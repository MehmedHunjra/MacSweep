import SwiftUI

struct SystemJunkView: View {
    @ObservedObject var scanEngine:  ScanEngine
    @ObservedObject var cleanEngine: CleanEngine
    @State private var showConfirm = false
    @State private var showResult  = false
    @State private var showReview  = false
    @EnvironmentObject var navManager: NavigationManager

    private let theme = SectionTheme.theme(for: .systemJunk)

    var systemCategories: [ScanCategory] {
        [.userCaches, .logs, .tempFiles, .mailAttach]
    }

    var systemItems: [ScanItem] {
        scanEngine.scanItems.filter { systemCategories.contains($0.category) }
    }

    var selectedSystemItems: [ScanItem] {
        systemItems.filter(\.isSelected)
    }

    var selectedSystemSize: Int64 {
        selectedSystemItems.reduce(0) { $0 + $1.size }
    }

    var body: some View {
        VStack(spacing: 0) {
            if !scanEngine.isScanning && (!scanEngine.scanComplete || systemItems.isEmpty) {
                VStack(spacing: 0) {
                    navHeader(isLanding: true)
                    ToolLandingView(
                        section: .systemJunk,
                        subtitle: "Remove deep system caches, logs, and\ntemporary files to reclaim space.",
                        actionLabel: "Scan",
                        onAction: {
                            Task { await scanEngine.startScan(mode: .categories([.userCaches, .logs, .tempFiles, .mailAttach])) }
                        }
                    )
                }
            } else if scanEngine.isScanning {
                ToolScanningView(
                    section: .systemJunk,
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
        .alert("Clean System Junk?", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clean", role: .destructive) {
                Task {
                    await cleanEngine.clean(items: systemItems)
                    if cleanEngine.cleanedSize > 0 {
                        scanEngine.recordFreed(bytes: cleanEngine.cleanedSize, description: "System Junk cleanup")
                    }
                    DS.playCleanComplete()
                    await scanEngine.startScan(mode: .categories([.userCaches, .logs, .tempFiles, .mailAttach]))
                    showResult = true
                }
            }
        } message: {
            Text("This will remove \(ByteCountFormatter.string(fromByteCount: selectedSystemSize, countStyle: .file)) of system junk.")
        }
        .sheet(isPresented: $showResult) {
            CleanResultSheet(cleanEngine: cleanEngine, scanEngine: scanEngine, isPresented: $showResult)
        }
        .sheet(isPresented: $showReview) {
            ReviewManagerSheet(scanEngine: scanEngine, cleanEngine: cleanEngine, scope: .systemJunk)
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
                    Image(systemName: "xmark.bin.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("System Junk")
                    .font(MSFont.title2)
                    .foregroundColor(DS.textPrimary)
                
                Spacer()
                
                if !systemItems.isEmpty {
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
            HStack(spacing: 12) {
                Spacer()
                Button {
                    Task { await scanEngine.startScan(mode: .categories([.userCaches, .logs, .tempFiles, .mailAttach])) }
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

            // Summary bar
            HStack(spacing: 14) {
                SummaryPill(
                    icon: "xmark.bin.fill",
                    label: "System Junk",
                    value: ByteCountFormatter.string(fromByteCount: systemItems.reduce(0) { $0 + $1.size }, countStyle: .file),
                    color: theme.glow
                )
                SummaryPill(
                    icon: "checkmark.circle.fill",
                    label: "Selected",
                    value: "\(selectedSystemItems.count) items · \(ByteCountFormatter.string(fromByteCount: selectedSystemSize, countStyle: .file))",
                    color: DS.success
                )
                Spacer()
                HStack(spacing: 8) {
                    Button("All") {
                        for cat in systemCategories { scanEngine.selectAll(in: cat) }
                    }
                    .font(MSFont.caption)
                    .foregroundColor(DS.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DS.bgElevated)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)

                    Button("None") {
                        for cat in systemCategories { scanEngine.deselectAll(in: cat) }
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
                    title: "Clean",
                    icon: "trash.fill",
                    gradient: [DS.danger, DS.danger],
                    disabled: selectedSystemSize == 0
                ) {
                    showConfirm = true
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(DS.bgPanel)
            .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1), alignment: .bottom)

            // Category cards
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(systemCategories, id: \.self) { category in
                        let items = scanEngine.itemsByCategory[category] ?? []
                        if !items.isEmpty {
                            CategoryCard(category: category, items: items, scanEngine: scanEngine)
                        }
                    }
                }
                .padding(20)
            }
            .background(DS.bg)
        }
    }
}
