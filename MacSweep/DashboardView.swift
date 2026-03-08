import SwiftUI

struct DashboardView: View {
    @ObservedObject var scanEngine: ScanEngine
    @ObservedObject var settings: AppSettings
    @Binding var selected: AppSection
    @State private var animateCards = false

    // Scroll indicator state
    @State private var dashScrollOffset: CGFloat = 0
    @State private var dashContentHeight: CGFloat = 0
    @State private var dashVisibleHeight: CGFloat = 0

    private var dashCanScrollUp: Bool { 
        dashScrollOffset < -10 && !dashCanScrollDown 
    }
    private var dashCanScrollDown: Bool {
        guard dashContentHeight > 0, dashVisibleHeight > 0 else { return false }
        return (dashContentHeight + dashScrollOffset - dashVisibleHeight) > 10
    }

    private var healthScore: Int {
        var score = 100
        if let disk = scanEngine.diskInfo {
            if disk.usedPercentage > 0.9 { score -= 40 }
            else if disk.usedPercentage > 0.75 { score -= 20 }
            else if disk.usedPercentage > 0.6 { score -= 10 }
        }
        if scanEngine.cpuUsagePercent > 80 { score -= 25 }
        else if scanEngine.cpuUsagePercent > 60 { score -= 10 }
        if scanEngine.memoryUsagePercent > 85 { score -= 20 }
        else if scanEngine.memoryUsagePercent > 70 { score -= 8 }
        return max(0, score)
    }

    private var healthStatus: (label: String, color: Color) {
        switch healthScore {
        case 80...100: return ("Excellent", DS.brandGreen)
        case 60..<80:  return ("Good",      DS.brandTeal)
        case 40..<60:  return ("Fair",      DS.warning)
        default:       return ("Poor",      DS.danger)
        }
    }

    private let tools: [(title: String, subtitle: String, section: AppSection)] = [
        ("Smart Scan",    "One-click full scan",        .smartScan),
        ("System Junk",   "Caches & logs",              .systemJunk),
        ("Large Files",   "Space-hogging files",        .largeFiles),
        ("Duplicates",    "Find duplicate files",       .duplicates),
        ("Protection",    "Privacy & threats",          .protection),
        ("Startup",       "Optimize startup items",     .performance),
        ("Maintenance",   "System maintenance tasks",   .maintenance),
        ("Memory",        "Optimize memory usage",      .memoryOptimizer),
        ("Applications",  "Manage apps",                .applications),
        ("Space Lens",    "Visualize disk usage",       .spaceLens),
        ("Dev Cleaner",   "IDE & build junk",           .devCleaner),
        ("Malware Scan",  "Detect & remove malware",    .malwareScanner),
        ("Real-Time",     "Live threat protection",     .realtimeProtect),
        ("Adware",        "Remove adware & agents",     .adwareCleaner),
        ("Ransomware",    "Monitor file changes",       .ransomwareGuard),
        ("Network",       "Monitor connections",        .networkMonitor),
        ("Quarantine",    "Manage quarantined files",   .quarantine),
        ("Integrity",     "System integrity monitor",   .integrityMonitor),
    ]

    private func formatSpeed(_ bytes: Int64) -> String {
        let b = max(bytes, 0)
        if b >= 1_000_000 {
            return String(format: "%.2f MB/sec", Double(b) / 1_000_000)
        }
        if b >= 1_000 {
            return String(format: "%.1f KB/sec", Double(b) / 1_000)
        }
        return "\(b) B/sec"
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let total = max(Int(seconds), 0)
        let days = total / 86_400
        let hours = (total % 86_400) / 3_600
        let mins = (total % 3_600) / 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }

    @EnvironmentObject var navManager: NavigationManager

    // MARK: - Navigation Header
    private var navHeader: some View {
        HStack(spacing: 16) {
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
            
            Text("Dashboard")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(DS.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: MSSpacing.lg) {

                    // Mac Health Card
                    HealthCard(score: healthScore, status: healthStatus, selected: $selected)
                        .id("top")
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 18)
                        .animation(Motion.stagger(0), value: animateCards)
                        .zIndex(100)

                    // Important settings shortcuts (compact)
                    DashboardQuickSettingsCard(scanEngine: scanEngine, settings: settings)
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 16)
                    .animation(Motion.stagger(1), value: animateCards)

                // Macintosh HD / Selected Drive details
                if scanEngine.diskInfo != nil {
                    DashboardDiskInsightCard(scanEngine: scanEngine, selected: $selected)
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 16)
                        .animation(Motion.stagger(2), value: animateCards)
                }

                // Topbar-like metric cards (1x4)
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: MSSpacing.sm), count: 4),
                    spacing: MSSpacing.sm
                ) {
                    let memoryPercent = min(max(Double(scanEngine.memoryUsagePercent) / 100.0, 0), 1)
                    let cpuPercent = min(max(Double(scanEngine.cpuUsagePercent) / 100.0, 0), 1)
                    let topCPUApps = scanEngine.runningApps.sorted { $0.cpuPercent > $1.cpuPercent }
                    let topMemoryApps = scanEngine.runningApps.sorted { $0.memoryMB > $1.memoryMB }
                    let topCPUApp = topCPUApps.first?.name ?? "n/a"
                    let topMemoryApp = topMemoryApps.first?.name ?? "n/a"
                    let memoryUsed = scanEngine.memoryUsed
                    let memoryTotal = max(scanEngine.memoryTotal, 0)
                    let memoryFree = max(memoryTotal - memoryUsed, 0)
                    let memoryUsedText = memoryUsed > 0
                        ? ByteCountFormatter.string(fromByteCount: memoryUsed, countStyle: .file)
                        : scanEngine.memoryUsedCompact
                    let memoryFreeText = ByteCountFormatter.string(fromByteCount: memoryFree, countStyle: .file)
                    let memoryTotalText = ByteCountFormatter.string(fromByteCount: memoryTotal, countStyle: .file)
                    let chipName = scanEngine.gpuName.isEmpty ? "Apple Silicon" : scanEngine.gpuName
                    let chipUsed = max(scanEngine.vramUsedMB, 0)
                    let chipTotal = max(scanEngine.vramTotalMB, 0)
                    let chipProgress = chipTotal > 0
                        ? min(max(Double(chipUsed) / Double(chipTotal), 0), 1)
                        : nil
                    let upload = formatSpeed(scanEngine.networkUpBytes)
                    let download = formatSpeed(scanEngine.networkDownBytes)
                    let netTotal = formatSpeed(scanEngine.networkUpBytes + scanEngine.networkDownBytes)
                    let uptime = formatUptime(ProcessInfo.processInfo.systemUptime)
                    let chipStatus: String = {
                        guard chipTotal > 0 else { return "Unknown" }
                        let pct = Double(chipUsed) / Double(chipTotal)
                        if pct > 0.85 { return "High" }
                        if pct > 0.70 { return "Busy" }
                        return "Good"
                    }()

                    let memoryTop1 = topMemoryApps.count > 0 ? "\(topMemoryApps[0].name) \(topMemoryApps[0].memoryFormatted)" : "n/a"
                    let memoryTop2 = topMemoryApps.count > 1 ? "\(topMemoryApps[1].name) \(topMemoryApps[1].memoryFormatted)" : "n/a"
                    let memoryTop3 = topMemoryApps.count > 2 ? "\(topMemoryApps[2].name) \(topMemoryApps[2].memoryFormatted)" : "n/a"
                    let cpuTop1 = topCPUApps.count > 0 ? "\(topCPUApps[0].name) \(topCPUApps[0].cpuFormatted)" : "n/a"
                    let cpuTop2 = topCPUApps.count > 1 ? "\(topCPUApps[1].name) \(topCPUApps[1].cpuFormatted)" : "n/a"
                    let cpuTop3 = topCPUApps.count > 2 ? "\(topCPUApps[2].name) \(topCPUApps[2].cpuFormatted)" : "n/a"
                    let chipTop1 = topMemoryApps.count > 0 ? "\(topMemoryApps[0].name) \(Int(topMemoryApps[0].memoryMB)) MB est." : "n/a"
                    let chipTop2 = topMemoryApps.count > 1 ? "\(topMemoryApps[1].name) \(Int(topMemoryApps[1].memoryMB)) MB est." : "n/a"
                    let chipTop3 = topMemoryApps.count > 2 ? "\(topMemoryApps[2].name) \(Int(topMemoryApps[2].memoryMB)) MB est." : "n/a"

                    MetricCard(
                        title: "Memory",
                        value: "Used: \(scanEngine.memoryUsedCompact) (\(scanEngine.memoryUsagePercent)%)",
                        subtitle: "Top App: \(topMemoryApp)",
                        icon: "memorychip",
                        color: DS.brandGreen,
                        progress: memoryPercent,
                        tooltipLines: [
                            ("Memory Used", memoryUsedText),
                            ("Memory Free", memoryFreeText),
                            ("Memory Total", memoryTotalText),
                            ("Pressure", "\(scanEngine.memoryUsagePercent)%"),
                            ("Top 1", memoryTop1),
                            ("Top 2", memoryTop2),
                            ("Top 3", memoryTop3),
                        ]
                    )
                    MetricCard(
                        title: "CPU",
                        value: "Load: \(scanEngine.cpuUsagePercent)%",
                        subtitle: "Top App: \(topCPUApp)",
                        icon: "cpu.fill",
                        color: DS.brandTeal,
                        progress: cpuPercent,
                        tooltipLines: [
                            ("CPU Load", "\(scanEngine.cpuUsagePercent)%"),
                            ("Running Apps", "\(scanEngine.runningAppCount)"),
                            ("Uptime", uptime),
                            ("Top 1", cpuTop1),
                            ("Top 2", cpuTop2),
                            ("Top 3", cpuTop3),
                        ]
                    )
                    MetricCard(
                        title: chipName,
                        value: "\(chipUsed) MB Shared",
                        subtitle: chipTotal > 0 ? "\(chipTotal) MB Total" : "Unified memory",
                        icon: "desktopcomputer",
                        color: Color(hex: "9B4DFF"),
                        progress: chipProgress,
                        tooltipLines: [
                            ("Chip", chipName),
                            ("Shared Used", "\(chipUsed) MB"),
                            ("Shared Total", chipTotal > 0 ? "\(chipTotal) MB" : "n/a"),
                            ("Status", chipStatus),
                            ("Top 1", chipTop1),
                            ("Top 2", chipTop2),
                            ("Top 3", chipTop3),
                        ]
                    )
                    MetricCard(
                        title: "Internet Speed",
                        value: "↑ \(upload)",
                        subtitle: "↓ \(download)",
                        icon: "wifi",
                        color: DS.brandTeal,
                        progress: nil,
                        tooltipLines: [
                            ("Upload", upload),
                            ("Download", download),
                            ("Throughput", netTotal),
                            ("Status", (scanEngine.networkUpBytes + scanEngine.networkDownBytes) > 0 ? "Active" : "Idle"),
                        ]
                    )
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 16)
                .animation(Motion.stagger(3), value: animateCards)

                // Storage Timeline
                StorageTimelineCard(scanEngine: scanEngine)
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 14)
                    .animation(Motion.stagger(4), value: animateCards)

                // Tools Grid
                VStack(alignment: .leading, spacing: MSSpacing.sm) {
                    Text("Tools")
                        .font(MSFont.title2)
                        .foregroundColor(DS.textPrimary)
                        .padding(.leading, 4)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: MSSpacing.sm),
                        GridItem(.flexible(), spacing: MSSpacing.sm),
                        GridItem(.flexible(), spacing: MSSpacing.sm),
                        GridItem(.flexible(), spacing: MSSpacing.sm)
                    ], spacing: MSSpacing.sm) {
                        ForEach(Array(tools.enumerated()), id: \.offset) { index, tool in
                            ToolCard(title: tool.title, subtitle: tool.subtitle, section: tool.section, selected: $selected)
                                .opacity(animateCards ? 1 : 0)
                                .offset(y: animateCards ? 0 : 14)
                                .animation(Motion.stagger(5 + index), value: animateCards)
                        }
                    }
                    
                    Spacer(minLength: 10).id("bottom")
                }
            }
            .padding(MSSpacing.lg)
            .background(
                GeometryReader { innerGeo in
                    Color.clear
                        .onChange(of: innerGeo.frame(in: .named("dashScroll")).origin.y) { _, y in
                            DispatchQueue.main.async { dashScrollOffset = y }
                        }
                        .onChange(of: innerGeo.size.height) { _, h in
                            DispatchQueue.main.async { dashContentHeight = h }
                        }
                        .onAppear {
                            DispatchQueue.main.async {
                                dashScrollOffset = innerGeo.frame(in: .named("dashScroll")).origin.y
                                dashContentHeight = innerGeo.size.height
                            }
                        }
                }
            )
            .coordinateSpace(name: "dashScroll")
            .background(
                GeometryReader { visGeo in
                    Color.clear
                        .onChange(of: visGeo.size.height) { _, h in
                            DispatchQueue.main.async { dashVisibleHeight = h }
                        }
                        .onAppear {
                            DispatchQueue.main.async { dashVisibleHeight = visGeo.size.height }
                        }
                }
            )
            .overlay(alignment: .bottom) {
                if dashCanScrollDown {
                    DashScrollArrow(direction: .down) {
                        withAnimation(.easeInOut(duration: 0.3)) { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                    .transition(.opacity)
                }
            }
            .background(DS.bg)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    animateCards = true
                }
            }
            }
        }
        }
    }
}

// MARK: - Health Card
private struct HealthCard: View {
    let score: Int
    let status: (label: String, color: Color)
    @Binding var selected: AppSection
    @State private var isHovered = false
    @State private var ringHovered = false
    private let ringSize: CGFloat = 90

    var scoreFactors: [(String, String)] {
        var factors: [(String, String)] = [("Health Score", "\(score) / 100")]
        if score < 100 { factors.append(("Status", status.label)) }
        if score <= 60  { factors.append(("Tip", "Run Smart Scan")) }
        return factors
    }

    var body: some View {
        HStack(alignment: .center, spacing: MSSpacing.lg) {
            // Score ring
            ZStack {
                Circle()
                    .stroke(DS.bgElevated, lineWidth: 8)
                    .frame(width: ringSize, height: ringSize)
                Circle()
                    .trim(from: 0, to: Double(score) / 100)
                    .stroke(
                        LinearGradient(colors: [status.color, status.color.opacity(0.6)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: status.color.opacity(ringHovered ? 0.65 : 0.40), radius: ringHovered ? 14 : 8)
                    .scaleEffect(ringHovered ? 1.03 : 1.0)
                    .animation(Motion.fast, value: ringHovered)

                VStack(spacing: 1) {
                    Text("\(score)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(status.color)
                    Text("/ 100")
                        .font(MSFont.caption)
                        .foregroundColor(DS.textMuted)
                }
            }
            .frame(width: ringSize + 26, height: ringSize + 26)
            .onHover { ringHovered = $0 }
            .contentShape(Circle())
            .overlay(alignment: .bottomLeading) {
                if ringHovered {
                    MetricTooltipCard(color: status.color, lines: scoreFactors)
                        .offset(y: CGFloat(scoreFactors.count * 24 + 18))
                        .zIndex(999)
                        .allowsHitTesting(false)
                        .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .topLeading)))
                        .animation(Motion.fast, value: ringHovered)
                }
            }
            .zIndex(2)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("Mac Health:")
                        .font(MSFont.title2)
                        .foregroundColor(DS.textSecondary)
                    Text(status.label)
                        .font(MSFont.title2)
                        .foregroundColor(status.color)
                }
                Text("Your Mac is running well. Run a Smart Scan to find potential issues.")
                    .font(MSFont.body)
                    .foregroundColor(DS.textSecondary)
                    .lineLimit(2)

                Button {
                    withAnimation(Motion.std) { selected = .smartScan }
                } label: {
                    Text("Scan Now")
                        .font(MSFont.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(DS.brandGradient))
                        .overlay(Capsule().stroke(DS.borderSubtle, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(MSSpacing.md)
        .frame(minHeight: ringSize + 34)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(DS.bgPanel))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(status.color.opacity(isHovered ? 0.30 : 0.12), lineWidth: 1))
        .shadow(color: status.color.opacity(isHovered ? 0.14 : 0), radius: 12, y: 4)
        .scaleEffect(isHovered ? 1.005 : 1.0)
        .animation(Motion.fast, value: isHovered)
        .onHover { isHovered = $0 }
    }
}

private struct DashboardQuickSettingsCard: View {
    @ObservedObject var scanEngine: ScanEngine
    @ObservedObject var settings: AppSettings
    @EnvironmentObject private var navManager: NavigationManager

    private var diskCompact: String {
        guard let disk = scanEngine.diskInfo else { return "0G" }
        let gib = max(0, Int((Double(disk.freeSpace) / 1_073_741_824.0).rounded()))
        return "\(gib)G"
    }

    private var menuBarTokens: [String] {
        var tokens: [String] = []
        if settings.menuBarShowCPU { tokens.append("\(scanEngine.cpuUsagePercent)%") }
        if settings.menuBarShowRAM { tokens.append(scanEngine.memoryUsedCompact.replacingOccurrences(of: " ", with: "")) }
        if settings.menuBarShowDisk { tokens.append(diskCompact) }
        if settings.menuBarShowNetwork {
            tokens.append("↓\(formatRate(scanEngine.networkDownBytes)) ↑\(formatRate(scanEngine.networkUpBytes))")
        }
        if tokens.isEmpty { tokens.append("Hidden") }
        return tokens
    }

    private var menuBarPreviewText: String {
        menuBarTokens.joined(separator: "  ")
    }

    private var nextScheduledRunText: String {
        guard settings.autoScanEnabled else { return "Disabled" }
        guard let last = settings.autoLastRunAt else { return "Due now" }
        let next = last.addingTimeInterval(settings.autoScanIntervalSeconds)
        if next <= Date() { return "Due now" }
        return formatPolicyDate(next)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MSSpacing.sm) {
            HStack {
                Text("Quick Settings")
                    .font(MSFont.headline)
                    .foregroundColor(DS.textPrimary)
                Spacer()
                Button {
                    openSettings("General")
                } label: {
                    Label("Open Settings", systemImage: "gearshape.fill")
                        .font(MSFont.caption)
                        .foregroundColor(DS.brandGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 9).fill(DS.bgElevated))
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: MSSpacing.sm),
                    GridItem(.flexible(), spacing: MSSpacing.sm),
                    GridItem(.flexible(), spacing: MSSpacing.sm),
                    GridItem(.flexible(), spacing: MSSpacing.sm)
                ],
                spacing: MSSpacing.sm
            ) {
                DashboardQuickPanel(title: "Menu Bar", icon: "menubar.rectangle", accent: DS.brandTeal) {
                    DashboardQuickToggleRow(icon: "cpu", iconColor: DS.brandTeal, title: "Show CPU", isOn: $settings.menuBarShowCPU)
                    DashboardQuickToggleRow(icon: "memorychip", iconColor: DS.success, title: "Show RAM", isOn: $settings.menuBarShowRAM)
                    DashboardQuickToggleRow(icon: "internaldrive.fill", iconColor: DS.brandGreen, title: "Show Disk", isOn: $settings.menuBarShowDisk)
                    DashboardQuickToggleRow(icon: "wifi", iconColor: DS.brandTeal, title: "Show Network", isOn: $settings.menuBarShowNetwork)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Live Preview")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(DS.textMuted)

                        HStack(spacing: 6) {
                            Image("MenuBarIcon")
                                .resizable()
                                .renderingMode(.original)
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 12)

                            Text(menuBarPreviewText)
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(DS.textSecondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 7).fill(DS.bgElevated))
                    }

                    Button {
                        openSettings("Menu Bar")
                    } label: {
                        Label("Menu Bar Settings", systemImage: "arrow.up.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(DS.brandTeal)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                }

                DashboardQuickPanel(title: "Automation", icon: "calendar.badge.clock", accent: DS.brandGreen) {
                    DashboardQuickToggleRow(icon: "calendar.badge.clock", iconColor: DS.brandTeal, title: "Scheduled Auto Scan", isOn: $settings.autoScanEnabled)

                    HStack(spacing: 8) {
                        Text("Scan Interval")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DS.textSecondary)
                        Spacer()
                        Picker("", selection: $settings.autoScanIntervalHours) {
                            Text("1h").tag(1.0)
                            Text("3h").tag(3.0)
                            Text("6h").tag(6.0)
                            Text("12h").tag(12.0)
                            Text("24h").tag(24.0)
                            Text("3d").tag(72.0)
                            Text("7d").tag(168.0)
                        }
                        .labelsHidden()
                        .frame(width: 84)
                    }
                    .disabled(!settings.autoScanEnabled)
                    .opacity(settings.autoScanEnabled ? 1.0 : 0.45)

                    DashboardQuickToggleRow(
                        icon: "sparkles",
                        iconColor: DS.warning,
                        title: "Auto Clean",
                        isOn: $settings.autoCleanEnabled,
                        isDisabled: !settings.autoScanEnabled
                    )

                    HStack(spacing: 8) {
                        Text("Min Clean")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DS.textSecondary)
                        Spacer()
                        Stepper("", value: $settings.autoCleanMinimumMB, in: 50...2000, step: 50)
                            .labelsHidden()
                            .frame(width: 56)
                        Text("\(Int(settings.autoCleanMinimumMB)) MB")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(DS.textSecondary)
                            .frame(width: 68, alignment: .trailing)
                    }
                    .disabled(!(settings.autoScanEnabled && settings.autoCleanEnabled))
                    .opacity((settings.autoScanEnabled && settings.autoCleanEnabled) ? 1.0 : 0.45)

                    DashboardQuickValueRow(label: "Last Run", value: formatPolicyDate(settings.autoLastRunAt))
                    DashboardQuickValueRow(label: "Next Run", value: nextScheduledRunText)
                    DashboardQuickValueRow(label: "Policy", value: settings.autoLastPolicyStatus)

                    Button {
                        openSettings("Scanning")
                    } label: {
                        Label("Scanning Settings", systemImage: "arrow.up.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(DS.brandGreen)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                }

                DashboardQuickPanel(title: "Tool Defaults", icon: "wrench.and.screwdriver.fill", accent: DS.warning) {
                    DashboardQuickToggleRow(
                        icon: "eye.slash.fill",
                        iconColor: DS.textMuted,
                        title: "Skip Hidden Files",
                        isOn: $settings.duplicateSkipHiddenFiles
                    )
                    DashboardQuickToggleRow(
                        icon: "eye.fill",
                        iconColor: DS.brandTeal,
                        title: "Show Hidden Files",
                        isOn: $settings.spaceLensShowHiddenFiles
                    )
                    DashboardQuickToggleRow(
                        icon: "memorychip",
                        iconColor: DS.brandGreen,
                        title: "Memory Auto Refresh",
                        isOn: $settings.memoryAutoRefresh
                    )
                    DashboardQuickValueRow(label: "Large File Threshold", value: "\(Int(settings.largeFileThresholdMB)) MB")
                    DashboardQuickValueRow(
                        label: "Duplicate Minimum",
                        value: settings.duplicateMinSizeMB < 1
                            ? "\(Int(settings.duplicateMinSizeMB * 1000)) KB"
                            : "\(String(format: "%.1f", settings.duplicateMinSizeMB)) MB"
                    )

                    Button {
                        openSettings("Tools")
                    } label: {
                        Label("Tools Settings", systemImage: "arrow.up.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(DS.warning)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                }

                DashboardQuickPanel(title: "Security", icon: "shield.checkered", accent: DS.danger) {
                    VStack(alignment: .leading, spacing: 8) {
                        // Antivirus
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ANTIVIRUS")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(DS.textMuted)
                                .padding(.bottom, 2)
                            
                            DashboardQuickToggleRow(icon: "shield.fill", iconColor: DS.success, title: "Real-Time Protection", isOn: $settings.antivirusRealtimeEnabled)
                            DashboardQuickToggleRow(icon: "calendar.badge.clock", iconColor: DS.brandTeal, title: "Scheduled Malware Scan", isOn: $settings.antivirusAutoScanEnabled)
                            DashboardQuickToggleRow(icon: "lock.doc.fill", iconColor: DS.warning, title: "Auto-Quarantine", isOn: $settings.antivirusQuarantineAuto)
                        }

                        Divider().opacity(0.3).padding(.vertical, 2)

                        // Integrity
                        VStack(alignment: .leading, spacing: 6) {
                            Text("SYSTEM INTEGRITY")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(DS.textMuted)
                                .padding(.bottom, 2)
                            
                            DashboardQuickToggleRow(icon: "checkmark.shield.fill", iconColor: DS.brandGreen, title: "Auto-Start Monitor", isOn: $settings.integrityAutoMonitor)
                            DashboardQuickToggleRow(icon: "bell.badge.fill", iconColor: DS.brandGreen, title: "Notify on High Risk", isOn: $settings.integrityNotifyOnHighRisk)
                            DashboardQuickToggleRow(icon: "terminal.fill", iconColor: DS.brandTeal, title: "Monitor Scopes (Cron/SSH)", isOn: Binding(
                                get: { settings.integrityMonitorCronJobs && settings.integrityMonitorSSH },
                                set: { val in settings.integrityMonitorCronJobs = val; settings.integrityMonitorSSH = val }
                            ))
                        }

                        HStack {
                            Button { openSettings("Antivirus") } label: {
                                Text("AV Sett.")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(DS.danger)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            Button { openSettings("Integrity") } label: {
                                Text("Integrity Sett.")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Color(hex: "169677"))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding(MSSpacing.md)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(DS.bgPanel))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(DS.borderSubtle, lineWidth: 1)
        )
    }

    private func openSettings(_ subState: String) {
        withAnimation(Motion.std) {
            navManager.navigate(to: .settings, subState: subState)
        }
    }

    private func formatPolicyDate(_ date: Date?) -> String {
        guard let date else { return "Never" }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }

    private func formatRate(_ bytesPerSecond: Int64) -> String {
        let value = Double(max(bytesPerSecond, 0))
        if value >= 1_000_000_000 { return String(format: "%.1fG", value / 1_000_000_000) }
        if value >= 1_000_000 { return String(format: "%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "%.0fK", value / 1_000) }
        return "\(Int(value))B"
    }
}

private struct DashboardQuickPanel<Content: View>: View {
    let title: String
    let icon: String
    let accent: Color
    let content: Content

    init(title: String, icon: String, accent: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(accent)
                    .frame(width: 24, height: 24)
                    .background(RoundedRectangle(cornerRadius: 7).fill(accent.opacity(0.15)))
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DS.textPrimary)
                Spacer()
            }

            content
        }
        .frame(maxWidth: .infinity, minHeight: 250, maxHeight: 250, alignment: .topLeading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(DS.bgElevated))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accent.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct DashboardQuickToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    var isDisabled: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 16)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DS.textSecondary)
                .lineLimit(1)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.mini)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1.0)
    }
}

private struct DashboardQuickValueRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DS.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(DS.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

// MARK: - Metric Card
private struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let progress: Double?
    var tooltipLines: [(label: String, value: String)] = []
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                    .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(color.opacity(0.15)))
                Spacer()
                Text(title)
                    .font(MSFont.caption)
                    .foregroundColor(DS.textMuted)
            }

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(DS.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let p = progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(DS.bgElevated).frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(colors: [color, color.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * min(p, 1.0), height: 6)
                            .shadow(color: color.opacity(0.5), radius: 4)
                    }
                }
                .frame(height: 6)
            }

            Text(subtitle)
                .font(MSFont.caption)
                .foregroundColor(DS.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 142, maxHeight: 142, alignment: .topLeading)
        .padding(MSSpacing.md)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DS.bgPanel))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(isHovered ? color.opacity(0.25) : DS.borderSubtle, lineWidth: 1))
        .shadow(color: color.opacity(isHovered ? 0.18 : 0), radius: 12, y: 4)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(Motion.fast, value: isHovered)
        .onHover { isHovered = $0 }
        .zIndex(isHovered ? 20 : 0)
        .overlay(alignment: .topLeading) {
            if isHovered && !tooltipLines.isEmpty {
                MetricTooltipCard(color: color, lines: tooltipLines)
                    .offset(y: -CGFloat(min(tooltipLines.count, 8) * 16 + 12))
                    .zIndex(999)
                    .allowsHitTesting(false)
                    .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .bottomLeading)))
                    .animation(Motion.fast, value: isHovered)
            }
        }
    }
}

private struct MetricTooltipCard: View {
    let color: Color
    let lines: [(label: String, value: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(lines.indices, id: \.self) { i in
                HStack(spacing: 8) {
                    Circle()
                        .fill(i == 0 ? color : DS.textMuted)
                    .frame(width: 6, height: 6)
                    Text(lines[i].label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(DS.textMuted)
                        .lineLimit(1)
                        .frame(width: 86, alignment: .leading)
                    Text(lines[i].value)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(i == 0 ? color : DS.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(width: 270, alignment: .leading)
        .fixedSize(horizontal: true, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(DS.bgPanel.opacity(0.98))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(DS.borderMid.opacity(0.9), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.55), radius: 14, y: 8)
    }
}

private struct DashboardDriveOption: Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
    let icon: String

    init(name: String, path: String, icon: String) {
        self.id = path
        self.name = name
        self.path = path
        self.icon = icon
    }
}

private struct DashboardDiskInsightCard: View {
    @ObservedObject var scanEngine: ScanEngine
    @Binding var selected: AppSection
    @State private var isDriveIconHovered = false
    @State private var driveOptions: [DashboardDriveOption] = []
    @State private var selectedDrivePath = "/"
    @State private var externalDiskInfo: DiskInfo?
    @State private var externalCategories: [StorageCategory] = []
    @State private var isAnalyzingExternalDrive = false

    private var selectedDriveName: String {
        driveOptions.first(where: { $0.path == selectedDrivePath })?.name ?? "Macintosh HD"
    }

    private var isSystemDriveSelected: Bool {
        selectedDrivePath == "/"
    }

    private var currentDiskInfo: DiskInfo? {
        isSystemDriveSelected ? scanEngine.diskInfo : externalDiskInfo
    }

    private var currentCategories: [StorageCategory] {
        isSystemDriveSelected ? scanEngine.storageCategories : externalCategories
    }

    private var isAnalyzingSelectedDrive: Bool {
        isSystemDriveSelected ? scanEngine.isAnalyzingSpace : isAnalyzingExternalDrive
    }

    private var diskSegments: [PopupDonutRing.Segment] {
        guard let disk = currentDiskInfo else {
            return [.init(name: "Used", value: 1, valueText: "0 B", color: .white.opacity(0.3))]
        }

        if currentCategories.isEmpty {
            return [
                .init(name: "Used", value: Double(disk.usedSpace), valueText: disk.usedFormatted, color: DS.brandGreen),
                .init(name: "Free", value: Double(max(disk.freeSpace, 1)), valueText: disk.freeFormatted, color: .white.opacity(0.4))
            ]
        }

        var segments = currentCategories.map {
            PopupDonutRing.Segment(name: $0.name, value: Double($0.size), valueText: $0.sizeFormatted, color: $0.color)
        }
        segments.append(
            .init(
                name: "Free",
                value: Double(max(disk.freeSpace, 1)),
                valueText: disk.freeFormatted,
                color: .white.opacity(0.4)
            )
        )
        return segments
    }

    private var legendSegments: [PopupDonutRing.Segment] {
        diskSegments
    }

    private var totalSegmentValue: Double {
        max(diskSegments.reduce(0) { $0 + max($1.value, 0) }, 1)
    }

    var body: some View {
        if let disk = currentDiskInfo {
            VStack(alignment: .leading, spacing: MSSpacing.md) {
                HStack {
                    Text(selectedDriveName)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(DS.textPrimary)
                    Spacer()
                    Menu {
                        Section {
                            ForEach(driveOptions) { option in
                                Button {
                                    selectDrive(option)
                                } label: {
                                    Label(option.name, systemImage: selectedDrivePath == option.path ? "checkmark.circle.fill" : option.icon)
                                }
                            }
                        }
                        Divider()
                        Button {
                            refreshDriveList()
                            refreshSelectedDriveInfo()
                        } label: {
                            Label("Refresh drive list", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: selectedDrivePath == "/" ? "internaldrive.fill" : "externaldrive.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(isDriveIconHovered ? DS.brandGreen : DS.textMuted)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(DS.bgElevated))
                                .overlay(Circle().stroke(DS.borderSubtle, lineWidth: 1))

                            Text("Select drive")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(isDriveIconHovered ? DS.brandGreen : DS.textMuted)
                        }
                        .animation(Motion.fast, value: isDriveIconHovered)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(Motion.fast) {
                            isDriveIconHovered = hovering
                        }
                    }
                    .help("Select drive")
                }

                Rectangle().fill(DS.borderSubtle).frame(height: 1)

                HStack(alignment: .top, spacing: MSSpacing.md) {
                    PopupDonutRing(
                        segments: diskSegments,
                        centerTop: disk.freeFormatted,
                        centerBottom: "of \(disk.totalFormatted)\navailable"
                    )
                    .frame(width: 190, height: 190)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(legendSegments.enumerated()), id: \.offset) { _, segment in
                            DashboardDiskLegendItem(segment: segment, total: totalSegmentValue)
                        }

                        HStack {
                            Spacer()
                            Button {
                                analyzeSelectedDrive()
                            } label: {
                                Group {
                                    if isAnalyzingSelectedDrive {
                                        HStack(spacing: 6) {
                                            ProgressView().controlSize(.small)
                                            Text("Analyzing...")
                                        }
                                    } else {
                                        Label("Analyze categories", systemImage: "chart.pie")
                                    }
                                }
                                .font(MSFont.caption)
                                .foregroundColor(DS.brandTeal)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 7)
                                .background(RoundedRectangle(cornerRadius: 9).fill(DS.bgElevated))
                            }
                            .buttonStyle(.plain)
                            .disabled(isAnalyzingSelectedDrive)
                        }
                        .padding(.top, 6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

            }
            .padding(MSSpacing.md)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(DS.bgPanel))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(DS.borderSubtle, lineWidth: 1))
            .onAppear {
                refreshDriveList()
                refreshSelectedDriveInfo()
            }
        }
    }

    private func refreshDriveList() {
        var options = [DashboardDriveOption(name: "Macintosh HD", path: "/", icon: "internaldrive.fill")]
        options.append(contentsOf: externalDriveOptions())
        driveOptions = options
        if !options.contains(where: { $0.path == selectedDrivePath }) {
            selectedDrivePath = "/"
        }
    }

    private func externalDriveOptions() -> [DashboardDriveOption] {
        let fm = FileManager.default
        guard let vols = try? fm.contentsOfDirectory(atPath: "/Volumes") else { return [] }
        let exclude = ["Macintosh HD", "Macintosh HD - Data", "Recovery"]
        return vols.compactMap { name in
            if name.hasPrefix(".") || exclude.contains(name) || name.hasPrefix("MacSweep") { return nil }
            let path = "/Volumes/\(name)"
            let url = URL(fileURLWithPath: path)
            if let values = try? url.resourceValues(forKeys: [.volumeIsRemovableKey, .volumeIsInternalKey, .volumeIsLocalKey]) {
                if values.volumeIsRemovable == true || values.volumeIsLocal == true {
                    return DashboardDriveOption(name: name, path: path, icon: "externaldrive.fill")
                }
            }
            return nil
        }
    }

    private func selectDrive(_ option: DashboardDriveOption) {
        selectedDrivePath = option.path
        refreshSelectedDriveInfo()
        if option.path != "/" {
            analyzeSelectedDrive()
        }
    }

    private func refreshSelectedDriveInfo() {
        guard selectedDrivePath != "/" else {
            externalDiskInfo = nil
            return
        }
        externalDiskInfo = diskInfoForVolume(path: selectedDrivePath)
        externalCategories = []
    }

    private func diskInfoForVolume(path: String) -> DiskInfo? {
        let url = URL(fileURLWithPath: path)
        guard let values = try? url.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ]),
        let total = values.volumeTotalCapacity else {
            return nil
        }

        func toInt64(_ value: Any?) -> Int64? {
            if let v = value as? Int64 { return v }
            if let v = value as? Int { return Int64(v) }
            if let v = value as? NSNumber { return v.int64Value }
            return nil
        }

        let available = toInt64(values.allValues[.volumeAvailableCapacityForImportantUsageKey])
            ?? toInt64(values.allValues[.volumeAvailableCapacityKey])
            ?? 0
        return DiskInfo(totalSpace: Int64(total), freeSpace: available)
    }

    private func analyzeSelectedDrive() {
        if isSystemDriveSelected {
            guard !scanEngine.isAnalyzingSpace else { return }
            Task { await scanEngine.analyzeSpace() }
            return
        }
        guard !isAnalyzingExternalDrive else { return }
        analyzeExternalDrive(path: selectedDrivePath)
    }

    private func analyzeExternalDrive(path: String) {
        isAnalyzingExternalDrive = true
        externalCategories = []
        let diskSnapshot = externalDiskInfo
        let targetPath = path

        Task {
            let rows = await Task.detached(priority: .userInitiated) { () -> [(name: String, path: String, size: Int64, isDir: Bool)] in
                let fm = FileManager.default
                let url = URL(fileURLWithPath: targetPath)
                guard let entries = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
                    return []
                }
                var output: [(name: String, path: String, size: Int64, isDir: Bool)] = []
                for entry in entries {
                    let name = entry.lastPathComponent
                    if name.hasPrefix(".") { continue }
                    let isDir = (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    let size = ScanEngine.calcSize(path: entry.path)
                    if size <= 0 { continue }
                    output.append((name: name, path: entry.path, size: size, isDir: isDir))
                }
                output.sort { $0.size > $1.size }
                return Array(output.prefix(10))
            }.value

            let palette: [Color] = [
                DS.warning, DS.brandTeal, DS.brandGreen, Color(hex: "3A70E0"),
                Color(hex: "9B4DFF"), Color(hex: "00C896"), Color(hex: "FF8C3A"),
                Color(hex: "D459A0"), Color(hex: "8B5CF6"), DS.textMuted
            ]

            var mapped: [StorageCategory] = []
            for (index, row) in rows.enumerated() {
                mapped.append(StorageCategory(
                    name: row.name,
                    path: row.path,
                    size: row.size,
                    color: palette[index % palette.count],
                    icon: row.isDir ? "folder.fill" : "doc.fill"
                ))
            }

            if let disk = diskSnapshot {
                let analyzed = mapped.reduce(Int64(0)) { $0 + $1.size }
                let remainder = max(disk.usedSpace - analyzed, 0)
                if remainder > 512_000_000 {
                    mapped.append(StorageCategory(
                        name: "System & Other",
                        path: targetPath,
                        size: remainder,
                        color: DS.textMuted,
                        icon: "internaldrive.fill"
                    ))
                }
            }

            externalCategories = mapped.sorted { $0.size > $1.size }
            isAnalyzingExternalDrive = false
        }
    }
}

private struct DashboardDiskLegendItem: View {
    let segment: PopupDonutRing.Segment
    let total: Double
    @State private var isHovered = false

    private var percent: Double {
        guard total > 0 else { return 0 }
        return min(max(segment.value / total, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(segment.color)
                    .frame(width: 8, height: 8)
                Text(segment.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DS.textSecondary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(segment.valueText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DS.textPrimary)
                    .lineLimit(1)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DS.bgElevated)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(segment.color)
                        .frame(width: geo.size.width * percent, height: 6)
                        .shadow(color: segment.color.opacity(isHovered ? 0.45 : 0.2), radius: isHovered ? 6 : 3)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 2)
        .overlay(alignment: .topTrailing) {
            if isHovered {
                VStack(alignment: .leading, spacing: 2) {
                    Text(segment.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(segment.color)
                            .frame(width: 7, height: 7)
                        Text(segment.valueText)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.95))
                        Text("(\(Int((percent * 100).rounded()))%)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color.black.opacity(0.46))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                .offset(x: -4, y: -56)
                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottom)))
            }
        }
        .onHover { isHovered = $0 }
        .animation(Motion.fast, value: isHovered)
    }
}

// MARK: - Tool Card
private struct ToolCard: View {
    let title: String
    let subtitle: String
    let section: AppSection
    @Binding var selected: AppSection
    @State private var isHovered = false

    private var theme: SectionTheme { SectionTheme.theme(for: section) }

    var body: some View {
        Button {
            withAnimation(Motion.std) { selected = section }
        } label: {
            VStack(alignment: .leading, spacing: MSSpacing.sm) {
                // Left accent bar + icon
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(theme.linearGradient)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: section.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: theme.glow.opacity(isHovered ? 0.40 : 0.15), radius: isHovered ? 8 : 4)
                    Spacer()
                }

                Text(title)
                    .font(MSFont.headline)
                    .foregroundColor(DS.textPrimary)

                Text(subtitle)
                    .font(MSFont.caption)
                    .foregroundColor(DS.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MSSpacing.md)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DS.bgPanel))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isHovered ? theme.glow.opacity(0.30) : DS.borderSubtle, lineWidth: 1)
            )
            .shadow(color: theme.glow.opacity(isHovered ? 0.14 : 0), radius: 10, y: 3)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(Motion.fast, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Storage Timeline Card
struct StorageTimelineCard: View {
    @ObservedObject var scanEngine: ScanEngine
    @State private var history: [StorageDataPoint] = []

    private let historyKey = "MacSweep_StorageHistory"

    var body: some View {
        VStack(alignment: .leading, spacing: MSSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Storage Timeline")
                        .font(MSFont.headline)
                        .foregroundColor(DS.textPrimary)
                    Text("Free space over the last 30 days")
                        .font(MSFont.caption)
                        .foregroundColor(DS.textSecondary)
                }
                Spacer()
                if let freed = monthlyFreedString {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(freed)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(DS.brandGreen)
                        Text("freed this month")
                            .font(MSFont.caption)
                            .foregroundColor(DS.textSecondary)
                    }
                }
            }

            if history.count >= 2 {
                GeometryReader { geo in
                    let maxFree = history.map(\.freeSpace).max() ?? 1
                    let minFree = history.map(\.freeSpace).min() ?? 0
                    let range = max(maxFree - minFree, 1)

                    ZStack {
                        // Grid lines
                        ForEach(0..<4, id: \.self) { i in
                            let y = geo.size.height * CGFloat(i) / 3
                            Path { p in
                                p.move(to: CGPoint(x: 0, y: y))
                                p.addLine(to: CGPoint(x: geo.size.width, y: y))
                            }
                            .stroke(DS.borderSubtle, lineWidth: 0.5)
                        }

                        // Fill
                        Path { path in
                            for (i, point) in history.enumerated() {
                                let x = geo.size.width * CGFloat(i) / CGFloat(max(history.count - 1, 1))
                                let y = geo.size.height * (1.0 - CGFloat(point.freeSpace - minFree) / CGFloat(range))
                                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else       { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                            path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                            path.closeSubpath()
                        }
                        .fill(LinearGradient(
                            colors: [DS.brandGreen.opacity(0.18), DS.brandGreen.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        ))

                        // Line
                        Path { path in
                            for (i, point) in history.enumerated() {
                                let x = geo.size.width * CGFloat(i) / CGFloat(max(history.count - 1, 1))
                                let y = geo.size.height * (1.0 - CGFloat(point.freeSpace - minFree) / CGFloat(range))
                                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else       { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .stroke(
                            LinearGradient(colors: [DS.brandGreen, DS.brandTeal], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )

                        // End dot
                        if let last = history.last {
                            let x = geo.size.width
                            let y = geo.size.height * (1.0 - CGFloat(last.freeSpace - minFree) / CGFloat(range))
                            Circle()
                                .fill(DS.brandGreen)
                                .frame(width: 7, height: 7)
                                .shadow(color: DS.brandGreen.opacity(0.7), radius: 4)
                                .position(x: x, y: y)
                        }
                    }
                }
                .frame(height: 80)

                HStack {
                    if let first = history.first {
                        Text(dateLabel(first.date)).font(MSFont.mono).foregroundColor(DS.textMuted)
                    }
                    Spacer()
                    Text("Today").font(MSFont.mono).foregroundColor(DS.textMuted)
                }
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 24))
                            .foregroundColor(DS.textMuted)
                        Text("History builds over time")
                            .font(MSFont.caption)
                            .foregroundColor(DS.textSecondary)
                    }
                    Spacer()
                }
                .frame(height: 80)
            }
        }
        .padding(MSSpacing.md)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(DS.bgPanel))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(DS.borderSubtle, lineWidth: 1))
        .onAppear { loadAndRecord() }
    }

    var monthlyFreedString: String? {
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        let total = scanEngine.freedHistory
            .filter { $0.date > thirtyDaysAgo }
            .reduce(0) { $0 + $1.bytes }
        
        guard total > 0 else { return nil }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }

    func dateLabel(_ date: Date) -> String {
        let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
        return fmt.string(from: date)
    }

    func loadAndRecord() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([StorageDataPoint].self, from: data) {
            history = decoded
        }
        guard let disk = scanEngine.diskInfo else { return }
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = history.last?.date, Calendar.current.isDate(lastDate, inSameDayAs: today) {
            history[history.count - 1] = StorageDataPoint(date: today, freeSpace: disk.freeSpace)
        } else {
            history.append(StorageDataPoint(date: today, freeSpace: disk.freeSpace))
        }
        if history.count > 30 { history = Array(history.suffix(30)) }
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
}

// MARK: - Dashboard Scroll Preference Keys

private struct DashScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct DashContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - Dashboard Scroll Arrow

private struct DashScrollArrow: View {
    enum Direction { case up, down }
    let direction: Direction
    var action: () -> Void = {}
    @State private var bounce = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
            if direction == .down {
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
                Text(direction == .down ? "Scroll for more" : "Back to top")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(DS.brandTeal)
            .padding(.horizontal, 14)
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

struct StorageDataPoint: Codable {
    let date: Date
    let freeSpace: Int64
}
