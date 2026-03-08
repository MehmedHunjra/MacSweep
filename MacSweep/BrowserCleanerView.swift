import SwiftUI

struct BrowserCleanerView: View {
    @ObservedObject var scanEngine:  ScanEngine
    @ObservedObject var cleanEngine: CleanEngine
    @State private var showConfirm = false
    @State private var showResult  = false
    @State private var showReview  = false
    @EnvironmentObject var navManager: NavigationManager

    private let theme = SectionTheme.theme(for: .browser)

    var browserItems: [ScanItem] {
        scanEngine.scanItems.filter { $0.category == .browserCaches }
    }

    var selectedBrowserSize: Int64 {
        browserItems.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }

    var body: some View {
        VStack(spacing: 0) {
            if !scanEngine.isScanning && (!scanEngine.scanComplete || browserItems.isEmpty) {
                VStack(spacing: 0) {
                    navHeader(isLanding: true)
                    ToolLandingView(
                        section: .browser,
                        subtitle: "Protect your privacy by clearing cookies,\nhistories, and cache from your browsers.",
                        actionLabel: "Scan",
                        onAction: {
                            Task { await scanEngine.startScan(mode: .categories([.browserCaches])) }
                        }
                    )
                }
            } else if scanEngine.isScanning {
                ToolScanningView(
                    section: .browser,
                    currentPath: $scanEngine.currentPath,
                    onStop: { scanEngine.cancelScan() }
                )
            } else {
                VStack(spacing: 0) {
                    navHeader(isLanding: false)
                    resultsView
                }
            }
        }
        .background(DS.bg)
        .alert("Clear Browser Data?", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                Task {
                    await cleanEngine.clean(items: browserItems)
                    if cleanEngine.cleanedSize > 0 {
                        scanEngine.recordFreed(bytes: cleanEngine.cleanedSize, description: "Browser cleanup")
                    }
                    DS.playCleanComplete()
                    await scanEngine.startScan(mode: .categories([.browserCaches]))
                    showResult = true
                }
            }
        } message: {
            Text("This will clear \(ByteCountFormatter.string(fromByteCount: selectedBrowserSize, countStyle: .file)) of browser data.")
        }
        .sheet(isPresented: $showResult) {
            CleanResultSheet(cleanEngine: cleanEngine, scanEngine: scanEngine, isPresented: $showResult)
        }
        .sheet(isPresented: $showReview) {
            ReviewManagerSheet(scanEngine: scanEngine, cleanEngine: cleanEngine, scope: .browser)
        }
    }

    // MARK: - Navigation Header
    func navHeader(isLanding: Bool) -> some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Button {
                    if !isLanding {
                        scanEngine.scanComplete = false
                    } else {
                        navManager.goBack()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor((isLanding && !navManager.canGoBack) ? DS.textMuted.opacity(0.5) : DS.textSecondary)
                        .frame(width: 32, height: 32)
                        .background((isLanding && !navManager.canGoBack) ? DS.bgElevated.opacity(0.5) : DS.bgElevated)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isLanding && !navManager.canGoBack)

                Button {
                    navManager.goForward()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(navManager.canGoForward ? DS.textSecondary : DS.textMuted.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .background(navManager.canGoForward ? DS.bgElevated : DS.bgElevated.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!navManager.canGoForward)
            }

            if !isLanding {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme.linearGradient)
                        .frame(width: 36, height: 36)
                    Image(systemName: "globe")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Browser Privacy")
                    .font(MSFont.title2)
                    .foregroundColor(DS.textPrimary)
                
                Spacer()
                
                if !browserItems.isEmpty {
                    Button("Review") { showReview = true }
                        .font(MSFont.caption)
                        .foregroundColor(DS.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DS.bgElevated)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                }
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Results
    private var resultsView: some View {
        VStack(spacing: 0) {
            // Header bar removed here as it's now in navHeader
            HStack(spacing: 12) {
                Spacer()
                Button {
                    Task { await scanEngine.startScan(mode: .categories([.browserCaches])) }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Rescan")
                    }
                    .font(MSFont.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(theme.linearGradient)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(DS.bgPanel)
            .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1), alignment: .bottom)

            if !browserItems.isEmpty {
                // Summary bar
                HStack(spacing: 14) {
                    SummaryPill(
                        icon: "globe",
                        label: "Browser Data",
                        value: ByteCountFormatter.string(fromByteCount: browserItems.reduce(0) { $0 + $1.size }, countStyle: .file),
                        color: theme.glow
                    )
                    SummaryPill(
                        icon: "checkmark.circle.fill",
                        label: "Selected",
                        value: "\(browserItems.filter(\.isSelected).count) · \(ByteCountFormatter.string(fromByteCount: selectedBrowserSize, countStyle: .file))",
                        color: DS.success
                    )
                    Spacer()
                    HStack(spacing: 8) {
                        Button("All") {
                            for item in browserItems where !item.isSelected { scanEngine.toggleItem(item.id) }
                        }
                        .font(MSFont.caption)
                        .foregroundColor(DS.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(DS.bgElevated)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)

                        Button("None") {
                            for item in browserItems where item.isSelected { scanEngine.toggleItem(item.id) }
                        }
                        .font(MSFont.caption)
                        .foregroundColor(DS.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(DS.bgElevated)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                    GradientButton(
                        title: "Clean Browsers",
                        icon: "trash.fill",
                        gradient: [DS.danger, DS.danger],
                        disabled: selectedBrowserSize == 0
                    ) {
                        showConfirm = true
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(DS.bgPanel)
                .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1), alignment: .bottom)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        BrowserSection(
                            name: "Google Chrome",
                            icon: "globe.americas.fill",
                            color: Color(hex: "4285F4"),
                            items: browserItems.filter { $0.path.contains("Chrome") },
                            scanEngine: scanEngine
                        )
                        BrowserSection(
                            name: "Safari",
                            icon: "safari.fill",
                            color: Color(hex: "006CFF"),
                            items: browserItems.filter { $0.path.contains("Safari") },
                            scanEngine: scanEngine
                        )
                        BrowserSection(
                            name: "Firefox",
                            icon: "flame.fill",
                            color: Color(hex: "FF6611"),
                            items: browserItems.filter { $0.path.contains("Firefox") },
                            scanEngine: scanEngine
                        )
                    }
                    .padding(20)
                }
                .background(DS.bg)
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(DS.success.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(DS.success)
                    }
                    Text("Browsers are Clean")
                        .font(MSFont.title2)
                        .foregroundColor(DS.textPrimary)
                    Text("No browser cache or tracking data found.")
                        .font(MSFont.body)
                        .foregroundColor(DS.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(DS.bg)
            }
        }
    }
}

// MARK: - Browser Section

struct BrowserSection: View {
    let name: String
    let icon: String
    let color: Color
    let items: [ScanItem]
    @ObservedObject var scanEngine: ScanEngine
    @State private var expanded = true

    var totalSize: Int64 { items.reduce(0) { $0 + $1.size } }

    var body: some View {
        if !items.isEmpty {
            VStack(spacing: 0) {
                Button {
                    withAnimation(Motion.std) { expanded.toggle() }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(color.opacity(0.18))
                                .frame(width: 36, height: 36)
                            Image(systemName: icon)
                                .font(.system(size: 18))
                                .foregroundColor(color)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name)
                                .font(MSFont.headline)
                                .foregroundColor(DS.textPrimary)
                            Text("\(items.count) item\(items.count == 1 ? "" : "s") · \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")
                                .font(MSFont.caption)
                                .foregroundColor(DS.textMuted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .rotationEffect(.degrees(expanded ? 90 : 0))
                            .foregroundColor(DS.textMuted)
                            .animation(Motion.std, value: expanded)
                    }
                    .padding(14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if expanded {
                    Rectangle()
                        .fill(DS.borderSubtle)
                        .frame(height: 1)
                        .padding(.horizontal, 14)

                    ForEach(items) { item in
                        BrowserCacheRow(item: item, scanEngine: scanEngine, color: color)
                        if item.id != items.last?.id {
                            Rectangle()
                                .fill(DS.borderSubtle)
                                .frame(height: 1)
                                .padding(.leading, 52)
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DS.bgPanel)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(DS.borderSubtle, lineWidth: 1))
            )
        }
    }
}

// MARK: - Browser Cache Row

struct BrowserCacheRow: View {
    let item: ScanItem
    @ObservedObject var scanEngine: ScanEngine
    let color: Color
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { _ in scanEngine.toggleItem(item.id) }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(MSFont.body)
                    .foregroundColor(DS.textPrimary)
                    .lineLimit(1)
                Text(item.path)
                    .font(MSFont.mono)
                    .foregroundColor(DS.textMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Text(item.sizeFormatted)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.path)])
            } label: {
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(isHovered ? DS.textSecondary : DS.textMuted)
            }
            .buttonStyle(.plain)
            .help("Reveal in Finder")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(isHovered ? DS.bgElevated : Color.clear)
        .animation(Motion.fast, value: isHovered)
        .onHover { isHovered = $0 }
    }
}
