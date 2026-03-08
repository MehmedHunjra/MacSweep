import SwiftUI
import AppKit

struct AppLeftoversView: View {
    @ObservedObject var scanEngine:  ScanEngine
    @ObservedObject var cleanEngine: CleanEngine
    @State private var showConfirm = false
    @State private var showResult  = false
    @State private var showReview  = false
    @EnvironmentObject var navManager: NavigationManager

    private let theme = SectionTheme.theme(for: .appLeftovers)

    var leftovers: [ScanItem] {
        scanEngine.scanItems
            .filter { $0.category == .appLeftovers }
            .sorted { $0.size > $1.size }
    }

    var selectedSize: Int64 {
        leftovers.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }

    var body: some View {
        VStack(spacing: 0) {
            if !scanEngine.isScanning && (!scanEngine.scanComplete || leftovers.isEmpty) {
                VStack(spacing: 0) {
                    navHeader(isLanding: true)
                    ToolLandingView(
                        section: .appLeftovers,
                        subtitle: "Find and remove leftover files from applications\nthat have already been uninstalled.",
                        actionLabel: "Scan",
                        onAction: {
                            Task { await scanEngine.startScan(mode: .categories([.appLeftovers])) }
                        }
                    )
                }
            } else if scanEngine.isScanning {
                ToolScanningView(
                    section: .appLeftovers,
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
        .alert("Remove App Leftovers?", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                Task {
                    await cleanEngine.clean(items: leftovers)
                    if cleanEngine.cleanedSize > 0 {
                        scanEngine.recordFreed(bytes: cleanEngine.cleanedSize, description: "App Leftovers cleanup")
                    }
                    DS.playCleanComplete()
                    await scanEngine.startScan(mode: .categories([.appLeftovers]))
                    showResult = true
                }
            }
        } message: {
            Text("This will remove \(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)) of leftover data.")
        }
        .sheet(isPresented: $showResult) {
            CleanResultSheet(cleanEngine: cleanEngine, scanEngine: scanEngine, isPresented: $showResult)
        }
        .sheet(isPresented: $showReview) {
            ReviewManagerSheet(scanEngine: scanEngine, cleanEngine: cleanEngine, scope: .appLeftovers)
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
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("App Leftovers")
                    .font(MSFont.title2)
                    .foregroundColor(DS.textPrimary)
                
                Spacer()
                
                if !leftovers.isEmpty {
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
                    Task { await scanEngine.startScan(mode: .categories([.appLeftovers])) }
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

            if !leftovers.isEmpty {
                // Summary bar
                HStack(spacing: 14) {
                    SummaryPill(
                        icon: "trash.fill",
                        label: "Leftovers",
                        value: "\(leftovers.count) apps",
                        color: theme.glow
                    )
                    SummaryPill(
                        icon: "checkmark.circle.fill",
                        label: "Selected",
                        value: "\(leftovers.filter(\.isSelected).count) · \(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file))",
                        color: DS.success
                    )
                    Spacer()
                    HStack(spacing: 8) {
                        Button("All") {
                            for item in leftovers where !item.isSelected { scanEngine.toggleItem(item.id) }
                        }
                        .font(MSFont.caption)
                        .foregroundColor(DS.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(DS.bgElevated)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)

                        Button("None") {
                            for item in leftovers where item.isSelected { scanEngine.toggleItem(item.id) }
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
                        title: "Remove Selected",
                        icon: "trash.fill",
                        gradient: [DS.danger, DS.danger],
                        disabled: selectedSize == 0
                    ) {
                        showConfirm = true
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(DS.bgPanel)
                .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1), alignment: .bottom)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 6) {
                        ForEach(leftovers) { item in
                            LeftoverRow(item: item, scanEngine: scanEngine)
                        }
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
                    Text("No App Leftovers Found")
                        .font(MSFont.title2)
                        .foregroundColor(DS.textPrimary)
                    Text("Your Mac is clean of uninstalled app data.")
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

// MARK: - Leftover Row

struct LeftoverRow: View {
    let item: ScanItem
    @ObservedObject var scanEngine: ScanEngine
    @State private var isHovered = false

    private let accent = SectionTheme.theme(for: .appLeftovers).glow

    var body: some View {
        HStack(spacing: 14) {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { _ in scanEngine.toggleItem(item.id) }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accent.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "app.dashed")
                    .font(.system(size: 18))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(MSFont.headline)
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
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(DS.textSecondary)

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            } label: {
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(DS.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? DS.bgElevated : DS.bgPanel)
                .animation(Motion.fast, value: isHovered)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(DS.borderSubtle, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(Motion.fast) { isHovered = hovering }
        }
    }
}
