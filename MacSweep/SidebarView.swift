import SwiftUI

// MARK: - Sidebar View (expanded, 200px)
struct SidebarView: View {
    @Binding var selected: AppSection
    @Binding var hoverSection: AppSection?
    @ObservedObject var scanEngine: ScanEngine
    @ObservedObject var settings: AppSettings

    @ObservedObject var appsEngine: ApplicationsEngine
    @ObservedObject var protectionEngine: ProtectionEngine
    @ObservedObject var perfEngine: PerformanceEngine
    @ObservedObject var dupEngine: DuplicateEngine
    @ObservedObject var memoryEngine: MemoryEngine
    @ObservedObject var spaceEngine: SpaceLensEngine
    @ObservedObject var devEngine: DevCleanEngine

    private let cleaningTools: [AppSection]   = [.smartScan, .systemJunk, .largeFiles, .duplicates]
    private let protectionTools: [AppSection] = [.protection]
    private let securityTools: [AppSection]   = [.malwareScanner, .realtimeProtect, .adwareCleaner, .ransomwareGuard, .networkMonitor, .quarantine, .integrityMonitor]
    private let managementTools: [AppSection] = [.performance, .maintenance, .memoryOptimizer, .applications]
    private let utilityTools: [AppSection]    = [.spaceLens, .devCleaner]

    // Scroll indicator state
    @State private var sidebarScrollOffset: CGFloat = 0
    @State private var sidebarContentHeight: CGFloat = 0
    @State private var sidebarVisibleHeight: CGFloat = 0

    private var canScrollUp: Bool {
        sidebarScrollOffset < -10 && !canScrollDown
    }

    private var canScrollDown: Bool {
        guard sidebarContentHeight > 0, sidebarVisibleHeight > 0 else { return false }
        let bottomOffset = sidebarContentHeight + sidebarScrollOffset - sidebarVisibleHeight
        return bottomOffset > 10
    }

    private func isScanning(_ section: AppSection) -> Bool {
        switch section {
        case .smartScan, .systemJunk, .largeFiles: return scanEngine.isScanning
        case .duplicates:   return dupEngine.isScanning
        case .protection:   return protectionEngine.isScanning
        case .performance:  return perfEngine.isScanning
        case .memoryOptimizer: return memoryEngine.isScanning
        case .applications: return appsEngine.isScanning
        case .spaceLens:    return spaceEngine.isScanning
        case .devCleaner:   return devEngine.isScanning
        default: return false
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Logo
            SidebarLogoButton(selected: $selected)
                .padding(.top, 34)
                .padding(.bottom, 10)
                .padding(.horizontal, 16)

            thinDivider

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Dashboard
                        SidebarIconButton(section: .dashboard, selected: $selected, hoverSection: $hoverSection, isScanning: false)
                            .padding(.top, 6)
                            .padding(.bottom, 2)
                            .id("top")

                        thinDivider.padding(.top, 4).padding(.bottom, 4)

                        // Cleaning
                        Text("Cleaning")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DS.textMuted)
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                            .padding(.bottom, 2)
                        ForEach(cleaningTools, id: \.self) { section in
                            SidebarIconButton(section: section, selected: $selected, hoverSection: $hoverSection, isScanning: isScanning(section))
                        }

                        thinDivider.padding(.vertical, 8)

                        // Protection
                        Text("Protection")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DS.textMuted)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 2)
                        ForEach(protectionTools, id: \.self) { section in
                            SidebarIconButton(section: section, selected: $selected, hoverSection: $hoverSection, isScanning: isScanning(section))
                        }

                        thinDivider.padding(.vertical, 8)

                        // Antivirus / Security
                        Text("Antivirus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DS.textMuted)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 2)
                        ForEach(securityTools, id: \.self) { section in
                            SidebarIconButton(section: section, selected: $selected, hoverSection: $hoverSection, isScanning: false)
                        }

                        thinDivider.padding(.vertical, 8)

                        // Management
                        Text("Management")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DS.textMuted)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 2)
                        ForEach(managementTools, id: \.self) { section in
                            SidebarIconButton(section: section, selected: $selected, hoverSection: $hoverSection, isScanning: isScanning(section))
                        }

                        thinDivider.padding(.vertical, 8)

                        // Utilities
                        Text("Utilities")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DS.textMuted)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 2)
                        ForEach(utilityTools, id: \.self) { section in
                            SidebarIconButton(section: section, selected: $selected, hoverSection: $hoverSection, isScanning: isScanning(section))
                        }

                        Spacer(minLength: 8)
                            .id("bottom")
                    }
                    .background(
                        GeometryReader { innerGeo in
                            Color.clear.onChange(of: innerGeo.frame(in: .named("sidebarScroll")).origin.y) { _, y in
                                DispatchQueue.main.async { sidebarScrollOffset = y }
                            }
                            .onChange(of: innerGeo.size.height) { _, h in
                                DispatchQueue.main.async { sidebarContentHeight = h }
                            }
                            .onAppear {
                                DispatchQueue.main.async {
                                    sidebarScrollOffset = innerGeo.frame(in: .named("sidebarScroll")).origin.y
                                    sidebarContentHeight = innerGeo.size.height
                                }
                            }
                        }
                    )
                }
                .coordinateSpace(name: "sidebarScroll")
                .background(
                    GeometryReader { visGeo in
                        Color.clear
                            .onChange(of: visGeo.size.height) { _, h in
                                DispatchQueue.main.async { sidebarVisibleHeight = h }
                            }
                            .onAppear {
                                DispatchQueue.main.async { sidebarVisibleHeight = visGeo.size.height }
                            }
                    }
                )
                .overlay(alignment: .bottom) {
                    if canScrollDown {
                        SidebarScrollArrow(direction: .down) {
                            withAnimation(.easeInOut(duration: 0.3)) { proxy.scrollTo("bottom", anchor: .bottom) }
                        }
                        .transition(.opacity)
                    }
                }

            }
            .frame(maxHeight: .infinity)

            thinDivider.padding(.bottom, 4)

            // Settings
            SidebarIconButton(section: .settings, selected: $selected, hoverSection: $hoverSection, isScanning: false)
                .padding(.bottom, 2)
                
            // Coffee Button
            SidebarCoffeeButton()
                .padding(.bottom, 14)
        }
        .frame(width: 200)
        .background(DS.bg)
        .overlay(
            Rectangle()
                .fill(DS.borderSubtle)
                .frame(width: 1),
            alignment: .trailing
        )
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(DS.borderSubtle)
            .frame(height: 1)
            .padding(.horizontal, 16)
    }
}

// MARK: - Sidebar Logo Button
private struct SidebarLogoButton: View {
    @Binding var selected: AppSection
    @State private var isHovered = false
    private var theme: SectionTheme { SectionTheme.theme(for: selected) }

    var body: some View {
        Button {
            withAnimation(Motion.std) { selected = .dashboard }
        } label: {
            HStack(spacing: 8) {
                LogoView(size: 28, theme: theme)
                    .shadow(color: theme.glow.opacity(isHovered ? 0.60 : 0.25), radius: isHovered ? 10 : 5)
                
                Text("MacSweep")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(DS.textPrimary)
                Spacer()
            }
            .contentShape(Rectangle())
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(Motion.fast, value: isHovered)
            .animation(Motion.fast, value: selected)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help("MacSweep — Dashboard")
    }
}

// MARK: - Sidebar Icon Button
struct SidebarIconButton: View {
    let section: AppSection
    @Binding var selected: AppSection
    @Binding var hoverSection: AppSection?
    var isScanning: Bool = false

    @State private var isHovered = false

    private var isSelected: Bool { selected == section }
    private var theme: SectionTheme { SectionTheme.theme(for: section) }
    private var glowColor: Color { theme.glow }

    var body: some View {
        Button {
            withAnimation(Motion.std) { selected = section }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(glowColor.opacity(0.18))
                            .frame(width: 32, height: 32)
                            .shadow(color: glowColor.opacity(0.35), radius: 8)
                    } else if isHovered {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 32, height: 32)
                    }

                    Image(systemName: section.icon)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? glowColor : DS.textMuted)
                        .frame(width: 32, height: 32)

                    if isScanning {
                        Circle()
                            .fill(DS.brandGreen)
                            .frame(width: 6, height: 6)
                            .shadow(color: DS.brandGreen.opacity(0.8), radius: 3)
                            .offset(x: 10, y: -10)
                    }
                }
                
                Text(section.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? DS.textPrimary : DS.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            hoverSection = hovering ? section : nil
        }
        .help(section.rawValue)
    }
}

// MARK: - Sidebar Coffee Button
struct SidebarCoffeeButton: View {
    @State private var isHovered = false
    private let url = URL(string: "https://ko-fi.com/mehmedhunjra")!

    var body: some View {
        Button {
            NSWorkspace.shared.open(url)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    if isHovered {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 32, height: 32)
                    }

                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(isHovered ? DS.brandGreen : DS.textMuted)
                        .frame(width: 32, height: 32)
                }
                
                Text("Buy me a Coffee")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(DS.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help("Support MacSweep")
    }
}

// MARK: - Visual Effect View (kept for other uses)
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Logo View
struct LogoView: View {
    var size: CGFloat = 40
    var theme: SectionTheme? = nil

    var body: some View {
        ZStack {
            if let theme {
                Image("MenuBarIcon")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(theme.linearGradient)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Image("BrandLogo")
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}


// MARK: - Disk Widget (kept for Dashboard use)
struct DiskWidget: View {
    let disk: DiskInfo
    @State private var isHovered = false

    var usageColor: Color {
        if disk.usedPercentage > 0.9 { return DS.danger }
        if disk.usedPercentage > 0.75 { return DS.warning }
        return DS.brandGreen
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "internaldrive.fill")
                    .foregroundColor(usageColor)
                    .font(.caption)
                Text("Macintosh HD")
                    .font(.caption.bold())
                    .foregroundColor(DS.textPrimary)
                Spacer()
                Text(disk.freeFormatted + " free")
                    .font(.caption2.bold())
                    .foregroundColor(usageColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.bgElevated)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [usageColor, usageColor.opacity(0.7)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * disk.usedPercentage)
                }
            }
            .frame(height: 6)

            HStack {
                Text("\(disk.usedFormatted) used")
                    .font(.caption2)
                    .foregroundColor(DS.textSecondary)
                Spacer()
                Text("\(disk.totalFormatted) total")
                    .font(.caption2)
                    .foregroundColor(DS.textSecondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(DS.bgPanel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(usageColor.opacity(isHovered ? 0.35 : 0.14), lineWidth: 1)
        )
        .shadow(color: usageColor.opacity(isHovered ? 0.20 : 0), radius: isHovered ? 10 : 0, y: 3)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .onHover { isHovered = $0 }
        .animation(Motion.fast, value: isHovered)
        .help("Used: \(disk.usedFormatted) of \(disk.totalFormatted). Free: \(disk.freeFormatted).")
    }
}

// MARK: - Scroll Preference Keys

private struct SidebarScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct SidebarContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Sidebar Scroll Arrow

private struct SidebarScrollArrow: View {
    enum Direction { case up, down }
    let direction: Direction
    var action: () -> Void = {}
    @State private var bounce = false

    var body: some View {
        Button(action: action) {
        VStack(spacing: 0) {
            if direction == .down {
                // Gradient fade above pill
                LinearGradient(
                    colors: [Color.clear, DS.bg],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 24)
            }

            HStack(spacing: 4) {
                Image(systemName: direction == .down ? "chevron.down" : "chevron.up")
                    .font(.system(size: 10, weight: .heavy))
                Text(direction == .down ? "More" : "Back to top")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(DS.brandTeal)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(DS.brandTeal.opacity(0.15))
                    .overlay(Capsule().stroke(DS.brandTeal.opacity(0.4), lineWidth: 0.5))
            )
            .offset(y: bounce ? (direction == .down ? 2 : -2) : 0)
            .animation(
                .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                value: bounce
            )
            .padding(.bottom, direction == .down ? 6 : 0)
            .padding(.top, direction == .up ? 6 : 0)

            if direction == .up {
                // Gradient fade below pill
                LinearGradient(
                    colors: [DS.bg, Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 24)
            }
        }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .allowsHitTesting(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                bounce = true
            }
        }
    }
}
