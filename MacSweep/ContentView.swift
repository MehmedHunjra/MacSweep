import SwiftUI

struct ContentView: View {
    @ObservedObject var scanEngine: ScanEngine
    @ObservedObject var cleanEngine: CleanEngine
    @ObservedObject var settings: AppSettings
    @ObservedObject var updateEngine: AppUpdateEngine

    // Hosted Engines
    @StateObject private var appsEngine      = ApplicationsEngine()
    @StateObject private var protectionEngine = ProtectionEngine()
    @StateObject private var perfEngine      = PerformanceEngine()
    @StateObject private var dupEngine       = DuplicateEngine()
    @StateObject private var memoryEngine    = MemoryEngine()
    @StateObject private var spaceEngine     = SpaceLensEngine()
    @StateObject private var devEngine       = DevCleanEngine()

    // Security Engines (hoisted so they persist across navigation)
    @StateObject private var malwareEngine     = MalwareScanEngine()
    @StateObject private var realtimeEngine    = RealtimeProtectionEngine()
    @StateObject private var adwareEngine      = AdwareCleanEngine()
    @StateObject private var ransomwareEngine  = RansomwareGuardEngine()
    @StateObject private var networkEngine     = NetworkMonitorEngine()
    @StateObject private var quarantineEngine  = QuarantineManager()
    @StateObject private var integrityEngine   = IntegrityMonitorEngine()

    // Navigation
    @StateObject private var navManager = NavigationManager()
    @State private var hoverSection: AppSection?

    var body: some View {
        HStack(spacing: 0) {
            // Icon-only sidebar (52px)
            SidebarView(
                selected: $navManager.currentSection,
                hoverSection: $hoverSection,
                scanEngine: scanEngine,
                settings: settings,
                appsEngine: appsEngine,
                protectionEngine: protectionEngine,
                perfEngine: perfEngine,
                dupEngine: dupEngine,
                memoryEngine: memoryEngine,
                spaceEngine: spaceEngine,
                devEngine: devEngine
            )
            .frame(width: 200)

            // Detail view with slide+fade transition
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(Motion.std, value: navManager.currentSection)
        }
        .background(DS.bg)
        .onAppear {
            if navManager.currentSection != settings.mainSection {
                navManager.currentSection = settings.mainSection
            }
            scanEngine.refreshDiskInfo()
            scanEngine.refreshRunningApps()
        }
        .onChange(of: settings.mainSectionRaw) { _, newRaw in
            let target = AppSection(rawValue: newRaw) ?? .dashboard
            if navManager.currentSection != target {
                withAnimation(Motion.std) { navManager.currentSection = target }
            }
        }
        .onChange(of: navManager.currentSection) { _, newValue in
            if settings.mainSection != newValue {
                settings.mainSection = newValue
            }
        }
        .background(
            MainWindowAccessor { window in
                guard let window else { return }
                if window.identifier?.rawValue != "MacSweepMainWindow" {
                    window.identifier = NSUserInterfaceItemIdentifier("MacSweepMainWindow")
                }
                window.isReleasedWhenClosed = false
                window.collectionBehavior.insert(.moveToActiveSpace)
                AppDelegate.ensureMainWindowGeometry(window)
                AppDelegate.mainWindow = window
            }
        )
    }

    @State private var maintenanceStandaloneTab = 0
    @State private var memoryStandaloneTab = 0

    @ViewBuilder
    var detailView: some View {
        switch navManager.currentSection {
        case .dashboard:
            DashboardView(scanEngine: scanEngine, settings: settings, selected: $navManager.currentSection)
                .environmentObject(navManager)
        case .smartScan:
            SmartScanView(scanEngine: scanEngine, cleanEngine: cleanEngine, settings: settings)
                .environmentObject(navManager)
        case .systemJunk:
            SystemJunkView(scanEngine: scanEngine, cleanEngine: cleanEngine)
                .environmentObject(navManager)
        case .largeFiles:
            LargeFilesView(scanEngine: scanEngine, cleanEngine: cleanEngine)
                .environmentObject(navManager)
        case .appLeftovers:
            AppLeftoversView(scanEngine: scanEngine, cleanEngine: cleanEngine)
                .environmentObject(navManager)
        case .browser:
            BrowserCleanerView(scanEngine: scanEngine, cleanEngine: cleanEngine)
                .environmentObject(navManager)
        case .maintenance:
            MaintenanceView(selectedTab: $maintenanceStandaloneTab)
                .onAppear { maintenanceStandaloneTab = 0 }
                .environmentObject(navManager)
        case .privacy:
            PrivacyView(scanEngine: scanEngine, cleanEngine: cleanEngine)
                .environmentObject(navManager)
        case .spaceLens:
            SpaceLensView(scanEngine: scanEngine, engine: spaceEngine)
                .environmentObject(navManager)
        case .devCleaner:
            DevCleanerView(devEngine: devEngine)
                .environmentObject(navManager)
        case .performance:
            PerformanceManagerView(engine: perfEngine)
                .environmentObject(navManager)
        case .memoryOptimizer:
            MemoryOptimizerView(engine: memoryEngine, selectedTab: $memoryStandaloneTab)
                .onAppear { memoryStandaloneTab = 0 }
                .environmentObject(navManager)
        case .applications:
            ApplicationsManagerView(engine: appsEngine)
                .environmentObject(navManager)
        case .protection:
            ProtectionManagerView(scanEngine: scanEngine, cleanEngine: cleanEngine, engine: protectionEngine)
                .environmentObject(navManager)
        case .duplicates:
            DuplicateFinderView(engine: dupEngine)
                .environmentObject(navManager)
        case .settings:
            SettingsView(scanEngine: scanEngine, settings: settings, updater: updateEngine)
                .environmentObject(navManager)
        case .malwareScanner:
            MalwareScannerView(engine: malwareEngine)
                .environmentObject(navManager)
        case .realtimeProtect:
            RealtimeProtectionView(engine: realtimeEngine)
                .environmentObject(navManager)
        case .adwareCleaner:
            AdwareCleanerView(engine: adwareEngine)
                .environmentObject(navManager)
        case .ransomwareGuard:
            RansomwareGuardView(engine: ransomwareEngine)
                .environmentObject(navManager)
        case .networkMonitor:
            NetworkMonitorView(engine: networkEngine)
                .environmentObject(navManager)
        case .quarantine:
            QuarantineManagerView(quarantine: quarantineEngine)
                .environmentObject(navManager)
        case .integrityMonitor:
            IntegrityMonitorView(engine: integrityEngine)
                .environmentObject(navManager)
        }
    }
}

private struct MainWindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = WindowHookView()
        view.onWindowChange = onResolve
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let hook = nsView as? WindowHookView else {
            DispatchQueue.main.async { onResolve(nsView.window) }
            return
        }
        hook.onWindowChange = onResolve
        DispatchQueue.main.async { onResolve(hook.window) }
    }
}

private final class WindowHookView: NSView {
    var onWindowChange: ((NSWindow?) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        onWindowChange?(window)
    }
}
