import SwiftUI

struct SmartScanView: View {
    @ObservedObject var scanEngine:  ScanEngine
    @ObservedObject var cleanEngine: CleanEngine
    @ObservedObject var settings: AppSettings
    @State private var showConfirm = false
    @State private var showResult  = false
    @State private var showReview  = false
    @EnvironmentObject var navManager: NavigationManager

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()

            if !scanEngine.isScanning && !scanEngine.scanComplete {
                // Landing
                VStack(spacing: 0) {
                    landingHeader
                    ToolLandingView(
                        section: .smartScan,
                        subtitle: "One-click comprehensive scan.\nFinds junk, privacy risks, and space-wasters.",
                        actionLabel: "Scan",
                        onAction: { Task { await scanEngine.startScan() } }
                    )
                }
            } else if scanEngine.isScanning {
                // Scanning
                ToolScanningView(
                    section: .smartScan,
                    scanningTitle: "Scanning your Mac...",
                    currentPath: $scanEngine.currentPath,
                    onStop: { scanEngine.cancelScan() }
                )
            } else if scanEngine.scanComplete {
                // Results
                VStack(spacing: 0) {
                    scanResultsHeader
                    Divider().background(DS.borderSubtle)
                    ScanResultsView(
                        scanEngine: scanEngine,
                        cleanEngine: cleanEngine,
                        showConfirm: $showConfirm,
                        showResult: $showResult
                    )
                }
            }
        }
        .alert("Clean Selected Files?", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clean", role: .destructive) {
                Task {
                    await cleanEngine.clean(items: scanEngine.scanItems)
                    if cleanEngine.cleanedSize > 0 {
                        scanEngine.recordFreed(bytes: cleanEngine.cleanedSize, description: "Smart Scan cleanup")
                        DS.playCleanComplete()
                    }
                    await scanEngine.startScan()
                    showResult = true
                }
            }
        } message: {
            Text("This will permanently delete \(ByteCountFormatter.string(fromByteCount: scanEngine.selectedSize, countStyle: .file)) of selected files. This cannot be undone.")
        }
        .sheet(isPresented: $showResult) {
            CleanResultSheet(cleanEngine: cleanEngine, scanEngine: scanEngine, isPresented: $showResult)
        }
        .sheet(isPresented: $showReview) {
            ReviewManagerSheet(scanEngine: scanEngine, cleanEngine: cleanEngine, scope: .smartScan)
        }
    }

    private var landingHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Button {
                    navManager.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(navManager.canGoBack ? DS.textSecondary : DS.textMuted.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .background(navManager.canGoBack ? DS.bgElevated : DS.bgElevated.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!navManager.canGoBack)

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
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var scanResultsHeader: some View {
        HStack(spacing: MSSpacing.sm) {
            HStack(spacing: 8) {
                Button {
                    scanEngine.scanComplete = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DS.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(DS.bgElevated)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

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
            .padding(.trailing, 8)

            // Section identity
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(SectionTheme.theme(for: .smartScan).linearGradient)
                    .frame(width: 36, height: 36)
                Image(systemName: AppSection.smartScan.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Smart Scan")
                    .font(MSFont.title2)
                    .foregroundColor(DS.textPrimary)
                Text("\(scanEngine.scanItems.count) items · \(ByteCountFormatter.string(fromByteCount: scanEngine.totalFoundSize, countStyle: .file))")
                    .font(MSFont.caption)
                    .foregroundColor(DS.textSecondary)
            }

            Spacer()

            Button("Review") { showReview = true }
                .buttonStyle(MSSecondaryButtonStyle())

            Button("Configure") {
                settings.settingsSectionRaw = "Scanning"
                settings.mainSection = .settings
            }
            .buttonStyle(MSSecondaryButtonStyle())

            Button {
                Task { await scanEngine.startScan() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Rescan")
                }
                .font(MSFont.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(SectionTheme.theme(for: .smartScan).linearGradient))
                .overlay(Capsule().stroke(DS.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, MSSpacing.lg)
        .padding(.vertical, MSSpacing.md)
        .background(DS.bgPanel)
    }
}

// MARK: - Secondary Button Style
struct MSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MSFont.caption)
            .foregroundColor(DS.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(DS.bgElevated)
            )
            .overlay(Capsule().stroke(DS.borderMid, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

// MARK: - Scan Results View
struct ScanResultsView: View {
    @ObservedObject var scanEngine:  ScanEngine
    @ObservedObject var cleanEngine: CleanEngine
    @Binding var showConfirm: Bool
    @Binding var showResult:  Bool

    let safeCategories: [ScanCategory] = [
        .userCaches, .logs, .browserCaches, .development, .tempFiles, .mailAttach, .photoJunk
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Summary bar
            HStack(spacing: MSSpacing.sm) {
                SummaryPill(
                    icon: "magnifyingglass",
                    label: "Found",
                    value: ByteCountFormatter.string(fromByteCount: scanEngine.totalFoundSize, countStyle: .file),
                    color: DS.brandTeal
                )
                SummaryPill(
                    icon: "checkmark.circle.fill",
                    label: "Selected",
                    value: ByteCountFormatter.string(fromByteCount: scanEngine.selectedSize, countStyle: .file),
                    color: DS.brandGreen
                )
                Spacer()
                GradientButton(
                    title: "Clean Selected",
                    icon: "trash.fill",
                    gradient: [DS.danger, DS.danger],
                    disabled: scanEngine.selectedSize == 0
                ) {
                    showConfirm = true
                }
            }
            .padding(.horizontal, MSSpacing.lg)
            .padding(.vertical, MSSpacing.md)
            .background(DS.bgPanel)

            Divider().background(DS.borderSubtle)

            // Categories list
            ScrollView(showsIndicators: false) {
                VStack(spacing: MSSpacing.sm) {
                    ForEach(safeCategories, id: \.self) { category in
                        let items = scanEngine.itemsByCategory[category] ?? []
                        if !items.isEmpty {
                            CategoryCard(category: category, items: items, scanEngine: scanEngine)
                        }
                    }
                }
                .padding(MSSpacing.lg)
            }
        }
        .background(DS.bg)
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category:   ScanCategory
    let items:      [ScanItem]
    @ObservedObject var scanEngine: ScanEngine
    @State private var expanded = true

    var categoryTotal: Int64 { items.reduce(0) { $0 + $1.size } }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(Motion.slow) { expanded.toggle() }
            } label: {
                HStack(spacing: MSSpacing.sm) {
                    // Colored left accent + icon
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(category.color)
                            .frame(width: 4)
                            .clipShape(RoundedCornerRect(corners: [.topLeft, .bottomLeft], radius: 10))

                        ZStack {
                            Rectangle()
                                .fill(category.color.opacity(0.12))
                                .frame(width: 42)
                            Image(systemName: category.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(category.color)
                        }
                    }
                    .frame(height: 52)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.rawValue)
                            .font(MSFont.headline)
                            .foregroundColor(DS.textPrimary)
                        Text("\(items.count) item\(items.count == 1 ? "" : "s") · \(ByteCountFormatter.string(fromByteCount: categoryTotal, countStyle: .file))")
                            .font(MSFont.caption)
                            .foregroundColor(DS.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Button("All")  { scanEngine.selectAll(in: category) }
                            .buttonStyle(MSSecondaryButtonStyle())
                        Button("None") { scanEngine.deselectAll(in: category) }
                            .buttonStyle(MSSecondaryButtonStyle())
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(DS.textMuted)
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                        .padding(.trailing, MSSpacing.md)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                Divider().background(DS.borderSubtle).padding(.leading, 50)
                ForEach(items) { item in
                    ScanItemRow(item: item, scanEngine: scanEngine)
                    if item.id != items.last?.id {
                        Divider().background(DS.borderSubtle).padding(.leading, 50)
                    }
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(DS.bgPanel))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(DS.borderSubtle, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Rounded Corner Shape
struct RoundedCornerRect: Shape {
    var corners: UIRectCorner = .allCorners
    var radius: CGFloat = 10

    // Map NSRectEdge-style
    struct UIRectCorner: OptionSet {
        let rawValue: Int
        static let topLeft     = UIRectCorner(rawValue: 1 << 0)
        static let topRight    = UIRectCorner(rawValue: 1 << 1)
        static let bottomLeft  = UIRectCorner(rawValue: 1 << 2)
        static let bottomRight = UIRectCorner(rawValue: 1 << 3)
        static let allCorners  = UIRectCorner(rawValue: ~0)
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tl = corners.contains(.topLeft)     ? radius : 0
        let tr = corners.contains(.topRight)    ? radius : 0
        let bl = corners.contains(.bottomLeft)  ? radius : 0
        let br = corners.contains(.bottomRight) ? radius : 0

        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        if tr > 0 { path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false) }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        if br > 0 { path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false) }
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        if bl > 0 { path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false) }
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        if tl > 0 { path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false) }
        path.closeSubpath()
        return path
    }
}

// MARK: - Scan Item Row
struct ScanItemRow: View {
    let item: ScanItem
    @ObservedObject var scanEngine: ScanEngine
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: MSSpacing.sm) {
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
                .foregroundColor(DS.textSecondary)
                .frame(minWidth: 60, alignment: .trailing)

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.path)])
            } label: {
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(DS.textSecondary.opacity(isHovered ? 1 : 0.4))
                    .animation(Motion.fast, value: isHovered)
            }
            .buttonStyle(.plain)
            .help("Reveal in Finder")
            .padding(.trailing, MSSpacing.md)
        }
        .padding(.horizontal, MSSpacing.md)
        .padding(.vertical, 9)
        .background(isHovered ? DS.bgElevated : Color.clear)
        .animation(Motion.fast, value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Summary Pill
struct SummaryPill: View {
    let icon:  String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(MSFont.mono).foregroundColor(DS.textMuted)
                Text(value).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(DS.textPrimary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(color.opacity(0.10)))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(color.opacity(0.20), lineWidth: 1))
    }
}

// MARK: - Gradient Button
struct GradientButton: View {
    let title: String
    let icon: String
    let gradient: [Color]
    var disabled: Bool = false
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(MSFont.headline)
            }
            .foregroundColor(disabled ? DS.textMuted : .white)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(LinearGradient(
                        colors: disabled ? [DS.bgElevated] : gradient,
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
            )
            .overlay(Capsule().stroke(DS.borderSubtle, lineWidth: 1))
            .shadow(color: (disabled ? Color.clear : gradient.first ?? .clear).opacity(isHovered ? 0.45 : 0.20), radius: isHovered ? 14 : 8, y: 3)
            .scaleEffect((isHovered && !disabled) ? 1.02 : 1.0)
            .animation(Motion.fast, value: isHovered)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Animated Scan View (legacy compatibility shim → now uses ToolScanningView)
struct AnimatedScanView: View {
    @ObservedObject var scanEngine: ScanEngine
    var body: some View {
        ToolScanningView(
            section: .smartScan,
            scanningTitle: "Scanning your Mac...",
            currentPath: Binding(get: { scanEngine.currentPath }, set: { _ in }),
            onStop: { scanEngine.cancelScan() }
        )
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(DS.brandGreen)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(DS.textPrimary)
                Text(label).font(MSFont.mono).foregroundColor(DS.textMuted)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(DS.brandGreen.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(DS.brandGreen.opacity(0.15), lineWidth: 1))
    }
}

// MARK: - Scan Ready View (legacy)
struct ScanReadyView: View {
    let section: AppSection
    var body: some View {
        ToolLandingView(section: section, subtitle: "Ready to scan.", onAction: {})
    }
}

// MARK: - Review Manager
enum ReviewScope {
    case smartScan, systemJunk, browser, appLeftovers, largeFiles

    var title: String {
        switch self {
        case .smartScan:    return "Smart Scan Review"
        case .systemJunk:   return "System Junk Review"
        case .browser:      return "Browser Privacy Review"
        case .appLeftovers: return "App Leftovers Review"
        case .largeFiles:   return "Large Files Review"
        }
    }

    var cleanupDescription: String {
        switch self {
        case .smartScan:    return "Smart Scan cleanup"
        case .systemJunk:   return "System Junk cleanup"
        case .browser:      return "Browser cleanup"
        case .appLeftovers: return "App Leftovers cleanup"
        case .largeFiles:   return "Large Files cleanup"
        }
    }

    var allowedCategories: Set<ScanCategory> {
        switch self {
        case .smartScan:    return Set(ScanCategory.allCases)
        case .systemJunk:   return [.userCaches, .logs, .tempFiles, .mailAttach]
        case .browser:      return [.browserCaches]
        case .appLeftovers: return [.appLeftovers]
        case .largeFiles:   return [.largeFiles]
        }
    }

    var scanMode: ScanMode {
        switch self {
        case .smartScan:    return .smart
        case .systemJunk:   return .categories([.userCaches, .logs, .tempFiles, .mailAttach])
        case .browser:      return .categories([.browserCaches])
        case .appLeftovers: return .categories([.appLeftovers])
        case .largeFiles:   return .categories([.largeFiles])
        }
    }
}

enum ReviewTab: String, CaseIterable, Identifiable {
    case all = "All Items", cleanup = "Cleanup", applications = "Applications"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .all:          return "tray.full.fill"
        case .cleanup:      return "sparkles.rectangle.stack.fill"
        case .applications: return "app.badge.fill"
        }
    }
    func includes(_ category: ScanCategory) -> Bool {
        switch self {
        case .all:          return true
        case .cleanup:      return [.userCaches, .logs, .browserCaches, .development, .tempFiles, .mailAttach, .photoJunk].contains(category)
        case .applications: return [.appLeftovers, .largeFiles].contains(category)
        }
    }
}

struct ReviewManagerSheet: View {
    @ObservedObject var scanEngine: ScanEngine
    @ObservedObject var cleanEngine: CleanEngine
    let scope: ReviewScope

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ReviewTab = .all
    @State private var showConfirm = false
    @State private var isCleaning  = false

    private var visibleItems: [ScanItem] {
        scanEngine.scanItems.filter { scope.allowedCategories.contains($0.category) && selectedTab.includes($0.category) }
    }

    private var groupedItems: [(category: ScanCategory, items: [ScanItem])] {
        let grouped = Dictionary(grouping: visibleItems, by: \.category)
        return ScanCategory.allCases.compactMap { cat in
            guard let items = grouped[cat], !items.isEmpty else { return nil }
            return (cat, items.sorted { $0.size > $1.size })
        }
    }

    private var selectedVisibleSize: Int64 { visibleItems.filter(\.isSelected).reduce(0) { $0 + $1.size } }
    private var selectedVisibleCount: Int  { visibleItems.filter(\.isSelected).count }
    private var totalVisibleSize: Int64    { visibleItems.reduce(0) { $0 + $1.size } }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: MSSpacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(scope.title)
                        .font(MSFont.title)
                        .foregroundColor(DS.textPrimary)
                    Text("Review items, select what to remove, then clean safely.")
                        .font(MSFont.body)
                        .foregroundColor(DS.textSecondary)
                }
                Spacer()
                Button("Close") { dismiss() }
                    .buttonStyle(MSSecondaryButtonStyle())
            }
            .padding(.horizontal, MSSpacing.lg)
            .padding(.vertical, MSSpacing.md)
            .background(DS.bgPanel)

            Divider().background(DS.borderSubtle)

            // Tab bar
            HStack(spacing: 6) {
                ForEach(ReviewTab.allCases) { tab in
                    Button {
                        withAnimation(Motion.fast) { selectedTab = tab }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon).font(.system(size: 11, weight: .semibold))
                            Text(tab.rawValue).font(MSFont.caption)
                        }
                        .foregroundColor(selectedTab == tab ? .white : DS.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(selectedTab == tab ? DS.brandGreen : DS.bgElevated))
                        .overlay(Capsule().stroke(selectedTab == tab ? Color.clear : DS.borderMid, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Button("Select All") {
                    for item in visibleItems where !item.isSelected { scanEngine.toggleItem(item.id) }
                }
                .buttonStyle(MSSecondaryButtonStyle())
                .disabled(visibleItems.isEmpty)

                Button("Select None") {
                    for item in visibleItems where item.isSelected { scanEngine.toggleItem(item.id) }
                }
                .buttonStyle(MSSecondaryButtonStyle())
                .disabled(visibleItems.isEmpty)
            }
            .padding(.horizontal, MSSpacing.lg)
            .padding(.vertical, MSSpacing.md)
            .background(DS.bg)

            Divider().background(DS.borderSubtle)

            if visibleItems.isEmpty {
                Spacer()
                Image(systemName: "checkmark.circle.fill").font(.system(size: 40)).foregroundColor(DS.brandGreen)
                Text("Nothing to review in this tab.").font(MSFont.headline).foregroundColor(DS.textSecondary).padding(.top, 8)
                Spacer()
            } else {
                ScrollView(showsIndicators: true) {
                    VStack(spacing: MSSpacing.sm) {
                        ForEach(groupedItems, id: \.category) { group in
                            ReviewCategorySection(category: group.category, items: group.items, scanEngine: scanEngine)
                        }
                    }
                    .padding(MSSpacing.lg)
                }
            }

            Divider().background(DS.borderSubtle)

            // Footer
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(selectedVisibleCount) item\(selectedVisibleCount == 1 ? "" : "s") selected")
                        .font(MSFont.headline)
                        .foregroundColor(DS.textPrimary)
                    Text("\(ByteCountFormatter.string(fromByteCount: selectedVisibleSize, countStyle: .file)) of \(ByteCountFormatter.string(fromByteCount: totalVisibleSize, countStyle: .file))")
                        .font(MSFont.caption)
                        .foregroundColor(DS.textSecondary)
                }
                Spacer()
                GradientButton(
                    title: isCleaning ? "Cleaning..." : "Clean Selected",
                    icon: "trash.fill",
                    gradient: [DS.danger, DS.danger],
                    disabled: isCleaning || selectedVisibleCount == 0
                ) { showConfirm = true }
            }
            .padding(.horizontal, MSSpacing.lg)
            .padding(.vertical, MSSpacing.md)
            .background(DS.bgPanel)
        }
        .frame(minWidth: 920, minHeight: 620)
        .background(DS.bg)
        .alert("Clean Selected Files?", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clean", role: .destructive) {
                Task {
                    isCleaning = true
                    await cleanEngine.clean(items: visibleItems)
                    if cleanEngine.cleanedSize > 0 {
                        scanEngine.recordFreed(bytes: cleanEngine.cleanedSize, description: scope.cleanupDescription)
                        DS.playCleanComplete()
                    }
                    await scanEngine.startScan(mode: scope.scanMode)
                    isCleaning = false
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete \(ByteCountFormatter.string(fromByteCount: selectedVisibleSize, countStyle: .file)) of selected files.")
        }
    }
}

struct ReviewCategorySection: View {
    let category: ScanCategory
    let items: [ScanItem]
    @ObservedObject var scanEngine: ScanEngine
    @State private var expanded = true

    var totalSize: Int64  { items.reduce(0) { $0 + $1.size } }
    var selectedCount: Int { items.filter(\.isSelected).count }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(Motion.std) { expanded.toggle() }
            } label: {
                HStack(spacing: MSSpacing.sm) {
                    Image(systemName: category.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(category.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.rawValue).font(MSFont.headline).foregroundColor(DS.textPrimary)
                        Text("\(selectedCount)/\(items.count) selected · \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")
                            .font(MSFont.caption).foregroundColor(DS.textSecondary)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Button("All")  { scanEngine.selectAll(in: category) }.buttonStyle(MSSecondaryButtonStyle())
                        Button("None") { scanEngine.deselectAll(in: category) }.buttonStyle(MSSecondaryButtonStyle())
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(DS.textMuted)
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                        .padding(.trailing, MSSpacing.md)
                }
                .padding(.horizontal, MSSpacing.md)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                Divider().background(DS.borderSubtle).padding(.leading, MSSpacing.md)
                ForEach(items) { item in
                    ReviewScanItemRow(item: item, scanEngine: scanEngine)
                    if item.id != items.last?.id {
                        Divider().background(DS.borderSubtle).padding(.leading, 44)
                    }
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(DS.bgPanel))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(DS.borderSubtle, lineWidth: 1))
    }
}

struct ReviewScanItemRow: View {
    let item: ScanItem
    @ObservedObject var scanEngine: ScanEngine
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: MSSpacing.sm) {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { _ in scanEngine.toggleItem(item.id) }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(MSFont.body).foregroundColor(DS.textPrimary).lineLimit(1)
                Text(item.path).font(MSFont.mono).foregroundColor(DS.textMuted).lineLimit(1).truncationMode(.middle)
            }
            Spacer()
            Text(item.sizeFormatted).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(DS.textSecondary)
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.path)])
            } label: {
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(DS.textSecondary.opacity(isHovered ? 1 : 0.4))
                    .animation(Motion.fast, value: isHovered)
            }
            .buttonStyle(.plain)
            .help("Reveal in Finder")
            .padding(.trailing, MSSpacing.md)
        }
        .padding(.horizontal, MSSpacing.md)
        .padding(.vertical, 9)
        .background(isHovered ? DS.bgElevated : Color.clear)
        .animation(Motion.fast, value: isHovered)
        .onHover { isHovered = $0 }
    }
}
