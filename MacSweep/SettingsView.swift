import SwiftUI
import AppKit
import ServiceManagement
import UserNotifications
import ApplicationServices
#if canImport(CoreLocation)
import CoreLocation
#endif

struct SettingsView: View {
    @ObservedObject var scanEngine: ScanEngine
    @ObservedObject var settings: AppSettings
    @ObservedObject var updater: AppUpdateEngine
    @State private var selectedSection: SettingsSection = .general
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
#if canImport(CoreLocation)
    @State private var locationAuthStatus: CLAuthorizationStatus = .notDetermined
#endif
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    enum SettingsSection: String, CaseIterable {
        case general    = "General"
        case menuBar    = "Menu Bar"
        case scanning   = "Scanning"
        case tools         = "Tools"
        case notifications = "Notifications"
        case antivirus     = "Antivirus"
        case integrity     = "Integrity"
        case history       = "History"
        case about         = "About"

        var icon: String {
            switch self {
            case .general:   return "gearshape.fill"
            case .menuBar:   return "menubar.rectangle"
            case .scanning:  return "sparkles.rectangle.stack"
            case .tools:         return "wrench.and.screwdriver.fill"
            case .notifications: return "bell.badge.fill"
            case .antivirus:     return "shield.fill"
            case .integrity:     return "checkmark.shield"
            case .history:       return "clock.arrow.circlepath"
            case .about:         return "info.circle.fill"
            }
        }
        var color: Color {
            switch self {
            case .general:   return DS.textSecondary
            case .menuBar:   return DS.brandTeal
            case .scanning:  return DS.brandGreen
            case .tools:         return DS.warning
            case .notifications: return DS.warning
            case .antivirus:     return DS.danger
            case .integrity:     return Color(hex: "169677")
            case .history:       return Color(hex: "8B5CF6")
            case .about:         return DS.brandTeal
            }
        }
    }

    @EnvironmentObject var navManager: NavigationManager

    // MARK: - Navigation Header
    private var navHeader: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Button {
                    if !navManager.goBackInCurrentSection() {
                        navManager.goBack()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor((navManager.canGoBackInCurrentSection || navManager.canGoBack) ? DS.textSecondary : DS.textMuted.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .background((navManager.canGoBackInCurrentSection || navManager.canGoBack) ? DS.bgElevated : DS.bgElevated.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!(navManager.canGoBackInCurrentSection || navManager.canGoBack))

                Button {
                    if !navManager.goForwardInCurrentSection() {
                        navManager.goForward()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor((navManager.canGoForwardInCurrentSection || navManager.canGoForward) ? DS.textSecondary : DS.textMuted.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .background((navManager.canGoForwardInCurrentSection || navManager.canGoForward) ? DS.bgElevated : DS.bgElevated.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!(navManager.canGoForwardInCurrentSection || navManager.canGoForward))
            }
            
            Text("Settings")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(DS.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    var body: some View {
        VStack(spacing: 0) {
            navHeader
            
            HStack(spacing: 0) {
            // Settings sidebar
            VStack(alignment: .leading, spacing: 2) {
                Text("SETTINGS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(DS.textMuted)
                    .tracking(1.2)
                    .padding(.leading, 12)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                ForEach(SettingsSection.allCases, id: \.self) { sec in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedSection = sec
                        }
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedSection == sec ? sec.color : sec.color.opacity(0.15))
                                    .frame(width: 24, height: 24)
                                Image(systemName: sec.icon)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(selectedSection == sec ? .white : sec.color)
                            }
                            Text(sec.rawValue)
                                .font(.system(size: 13, weight: selectedSection == sec ? .semibold : .regular))
                                .foregroundColor(selectedSection == sec ? DS.textPrimary : DS.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(selectedSection == sec ? sec.color.opacity(0.12) : Color.clear)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .frame(width: 180)
            .background(DS.bgPanel)

            Rectangle().fill(DS.borderSubtle).frame(width: 1)

            // Settings content
            ScrollView(showsIndicators: false) {
                Group {
                    switch selectedSection {
                    case .general:   generalSettings
                    case .menuBar:   menuBarSettings
                    case .scanning:  scanningSettings
                    case .tools:         toolsSettings
                    case .notifications: notificationSettings
                    case .antivirus:     antivirusSettings
                    case .integrity:     integritySettings
                    case .history:       historySettings
                    case .about:         aboutView
                    }
                }
                .padding(28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // Priority: if navigation passed a concrete Settings sub-section, open that one.
            if navManager.currentState.section == .settings,
               let sub = navManager.currentState.subState,
               let fromNav = SettingsSection(rawValue: sub) {
                selectedSection = fromNav
            } else if let restored = SettingsSection(rawValue: settings.settingsSectionRaw) {
                selectedSection = restored
            }
            // Ensure first visit is in history if not already.
            if navManager.currentState.section != .settings || navManager.currentState.subState == nil {
                navManager.navigate(to: .settings, subState: selectedSection.rawValue)
            }
            refreshPermissionStatuses()
            registerLoginItem(enabled: settings.launchAtLogin)
            updater.configure(settings: settings)
            NotificationManager.shared.configure(settings: settings)
            Task { await updater.evaluateAutoCheckIfNeeded() }
        }
        .onChange(of: navManager.currentState) { _, newState in
            if newState.section == .settings, let sub = newState.subState, let section = SettingsSection(rawValue: sub) {
                if selectedSection != section {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedSection = section
                    }
                }
            }
        }
        .onChange(of: selectedSection) { _, newValue in
            if settings.settingsSectionRaw != newValue.rawValue {
                settings.settingsSectionRaw = newValue.rawValue
            }
            if navManager.currentState.section != .settings || navManager.currentState.subState != newValue.rawValue {
                navManager.navigate(to: .settings, subState: newValue.rawValue)
            }
        }
        .onChange(of: settings.settingsSectionRaw) { _, newRaw in
            if let section = SettingsSection(rawValue: newRaw), selectedSection != section {
                selectedSection = section
            }
        }
        .onChange(of: settings.updateAutoCheckEnabled) { _, _ in
            Task { await updater.evaluateAutoCheckIfNeeded() }
        }
        .onChange(of: settings.updateCheckIntervalHours) { _, _ in
            Task { await updater.evaluateAutoCheckIfNeeded() }
        }
        }
    }

    // MARK: - General Settings
    var generalSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsHeader(icon: "gearshape.fill", title: "General", color: DS.textSecondary)

            SettingsCard {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "power",
                        iconColor: DS.brandGreen,
                        title: "Launch at Login",
                        subtitle: "MacSweep starts automatically when you log in"
                    ) {
                        Toggle("", isOn: $settings.launchAtLogin)
                            .labelsHidden()
                            .onChange(of: settings.launchAtLogin) { _, newVal in
                                registerLoginItem(enabled: newVal)
                            }
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "menubar.rectangle",
                        iconColor: DS.brandTeal,
                        title: "Launch as Menu Bar Only",
                        subtitle: "Only menu bar launches at login (recommended)"
                    ) {
                        Toggle("", isOn: $settings.launchAtLoginMenuBarOnly)
                            .labelsHidden()
                            .disabled(!settings.launchAtLogin)
                    }
                    .opacity(settings.launchAtLogin ? 1.0 : 0.45)

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "dock.rectangle",
                        iconColor: DS.brandTeal,
                        title: "Show in Dock",
                        subtitle: "Display MacSweep icon in the Dock"
                    ) {
                        Toggle("", isOn: $settings.showDockIcon)
                            .labelsHidden()
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "bell.fill",
                        iconColor: DS.warning,
                        title: "Notifications",
                        subtitle: "Show alerts when scans complete"
                    ) {
                        Toggle("", isOn: $settings.notificationsEnabled)
                            .labelsHidden()
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "arrow.clockwise",
                        iconColor: DS.brandGreen,
                        title: "Refresh Interval",
                        subtitle: "How often to update system stats"
                    ) {
                        Picker("", selection: $settings.refreshInterval) {
                            Text("2s").tag(2.0)
                            Text("5s").tag(5.0)
                            Text("10s").tag(10.0)
                            Text("30s").tag(30.0)
                        }
                        .labelsHidden()
                        .frame(width: 70)
                        .onChange(of: settings.refreshInterval) { _, interval in
                            scanEngine.startRefreshTimer(interval: interval)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("APP UPDATES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                SettingsCard {
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "arrow.triangle.2.circlepath",
                            iconColor: DS.brandTeal,
                            title: "Automatic Update Checks",
                            subtitle: "Check GitHub releases in the background"
                        ) {
                            Toggle("", isOn: $settings.updateAutoCheckEnabled)
                                .labelsHidden()
                        }

                        Divider().padding(.leading, 44)

                        SettingsRow(
                            icon: "clock.badge.checkmark",
                            iconColor: DS.brandGreen,
                            title: "Check Frequency",
                            subtitle: "How often to check for new versions"
                        ) {
                            Picker("", selection: $settings.updateCheckIntervalHours) {
                                Text("Every 6h").tag(6.0)
                                Text("Every 12h").tag(12.0)
                                Text("Every 24h").tag(24.0)
                                Text("Every 48h").tag(48.0)
                                Text("Every 7d").tag(168.0)
                            }
                            .labelsHidden()
                            .frame(width: 96)
                            .disabled(!settings.updateAutoCheckEnabled)
                        }
                        .opacity(settings.updateAutoCheckEnabled ? 1.0 : 0.45)

                        Divider().padding(.leading, 44)

                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(DS.warning.opacity(0.15))
                                    .frame(width: 28, height: 28)
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(DS.warning)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(updater.statusMessage)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(updater.isUpdateAvailable ? DS.warning : .primary)

                                Text("Installed: v\(updater.currentVersion)  •  Latest: v\(updater.latestVersion ?? updater.currentVersion)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)

                                Text("Last checked: \(formatPolicyDate(settings.updateLastCheckAt))  •  Next: \(nextUpdateCheckText)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)

                                if let error = updater.lastErrorMessage, !error.isEmpty {
                                    Text(error)
                                        .font(.system(size: 10))
                                        .foregroundColor(DS.danger)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 8) {
                                Button {
                                    Task { await updater.checkForUpdates(manual: true) }
                                } label: {
                                    HStack(spacing: 6) {
                                        if updater.isChecking {
                                            ProgressView()
                                                .controlSize(.small)
                                        }
                                        Text(updater.isChecking ? "Checking..." : "Check Now")
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(DS.brandGreen)
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(updater.isChecking)

                                Button(updater.isUpdateAvailable ? "Download Update" : "View Releases") {
                                    updater.openReleasePage()
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(DS.brandTeal)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("SELECTION & INTERACTION")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                SettingsCard {
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "checkmark.circle",
                            iconColor: DS.brandTeal,
                            title: "Always Show Checkboxes",
                            subtitle: "Display selection circles even when not hovered"
                        ) {
                            Toggle("", isOn: $settings.selectionAlwaysShowCheckboxes)
                                .labelsHidden()
                        }

                        Divider().padding(.leading, 44)

                        SettingsRow(
                            icon: "sparkles",
                            iconColor: DS.warning,
                            title: "Auto-Select High Risk",
                            subtitle: "Automatically check dangerous items after scanning"
                        ) {
                            Toggle("", isOn: $settings.selectionAutoSelectHighRisk)
                                .labelsHidden()
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("PERMISSIONS & SHORTCUTS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                SettingsCard {
                    VStack(spacing: 0) {
                        PermissionShortcutRow(
                            icon: "figure.wave",
                            iconColor: DS.brandTeal,
                            title: "Accessibility",
                            subtitle: "Needed for app control actions",
                            statusText: accessibilityStatusText
                        ) {
                            openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
                        }

                        Divider().padding(.leading, 44)

                        PermissionShortcutRow(
                            icon: "externaldrive.fill.badge.checkmark",
                            iconColor: DS.brandGreen,
                            title: "Full Disk Access",
                            subtitle: "Needed for deep scanning and cleanup",
                            statusText: "Open macOS setting"
                        ) {
                            openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
                        }

                        Divider().padding(.leading, 44)

                        PermissionShortcutRow(
                            icon: "rectangle.on.rectangle",
                            iconColor: Color(hex: "8B5CF6"),
                            title: "Screen Recording",
                            subtitle: "Needed for advanced overlay/screen tools",
                            statusText: "Open macOS setting"
                        ) {
                            openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
                        }

                        Divider().padding(.leading, 44)

                        PermissionShortcutRow(
                            icon: "gearshape.2.fill",
                            iconColor: DS.danger,
                            title: "Automation",
                            subtitle: "Allow controlled actions between apps",
                            statusText: "Open macOS setting"
                        ) {
                            openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")
                        }

                        Divider().padding(.leading, 44)

                        PermissionShortcutRow(
                            icon: "location.fill",
                            iconColor: DS.success,
                            title: "Location Services",
                            subtitle: "Used for accurate Wi-Fi network details",
                            statusText: locationStatusText
                        ) {
                            openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")
                        }

                        Divider().padding(.leading, 44)

                        PermissionShortcutRow(
                            icon: "bell.badge.fill",
                            iconColor: DS.warning,
                            title: "Notifications Permission",
                            subtitle: "Allow scan alerts and task updates",
                            statusText: notificationStatusText
                        ) {
                            openSystemSettings("x-apple.systempreferences:com.apple.preference.notifications")
                        }

                        Divider().padding(.leading, 44)

                        PermissionShortcutRow(
                            icon: "keyboard",
                            iconColor: DS.brandGreen,
                            title: "Keyboard Shortcuts",
                            subtitle: "Open macOS shortcuts settings",
                            statusText: "Open macOS setting"
                        ) {
                            openSystemSettings("x-apple.systempreferences:com.apple.preference.keyboard?Shortcuts")
                        }
                    }
                }

                Text("Tip: once permission is granted in macOS, MacSweep won't ask again unless you revoke it.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Menu Bar Settings
    var menuBarSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsHeader(icon: "menubar.rectangle", title: "Menu Bar", color: DS.brandTeal)

            SettingsCard {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "cpu",
                        iconColor: DS.brandTeal,
                        title: "Show CPU Usage",
                        subtitle: "Display CPU load percentage in menu bar"
                    ) {
                        Toggle("", isOn: $settings.menuBarShowCPU).labelsHidden()
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "memorychip",
                        iconColor: DS.success,
                        title: "Show RAM Usage",
                        subtitle: "Display memory usage in menu bar"
                    ) {
                        Toggle("", isOn: $settings.menuBarShowRAM).labelsHidden()
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "internaldrive.fill",
                        iconColor: DS.brandGreen,
                        title: "Show Disk Available",
                        subtitle: "Display available disk space in menu bar"
                    ) {
                        Toggle("", isOn: $settings.menuBarShowDisk).labelsHidden()
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "wifi",
                        iconColor: DS.brandTeal,
                        title: "Show Network Speed",
                        subtitle: "Display download/upload speed in menu bar"
                    ) {
                        Toggle("", isOn: $settings.menuBarShowNetwork).labelsHidden()
                    }
                }
            }

            // Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Preview")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image("MenuBarIcon")
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 14)
                    if settings.menuBarShowCPU {
                        Text("12%")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                    if settings.menuBarShowRAM {
                        Text("8.4G")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                    if settings.menuBarShowDisk {
                        Text("142G")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                    if settings.menuBarShowNetwork {
                        Text("↓1.2M ↑280K")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DS.bgElevated)
                        .shadow(radius: 2)
                )
            }
        }
    }

    // MARK: - Scanning Settings
    var scanningSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsHeader(icon: "sparkles.rectangle.stack", title: "Scanning", color: DS.brandGreen)

            SettingsCard {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "checklist",
                        iconColor: DS.brandGreen,
                        title: "User Caches",
                        subtitle: "Scan application caches"
                    ) {
                        Toggle("", isOn: $settings.scanIncludeUserCaches)
                            .labelsHidden()
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "doc.text.fill",
                        iconColor: DS.warning,
                        title: "Log Files",
                        subtitle: "Scan application and system logs"
                    ) {
                        Toggle("", isOn: $settings.scanIncludeLogs)
                            .labelsHidden()
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "globe",
                        iconColor: DS.success,
                        title: "Browser Caches",
                        subtitle: "Scan browser caches and web data"
                    ) {
                        Toggle("", isOn: $settings.scanIncludeBrowserCaches)
                            .labelsHidden()
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "hammer.fill",
                        iconColor: DS.danger,
                        title: "Development Junk",
                        subtitle: "Scan Xcode/npm/gradle/cocoapods artifacts"
                    ) {
                        Toggle("", isOn: $settings.scanIncludeDevelopment)
                            .labelsHidden()
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "clock.arrow.circlepath",
                        iconColor: DS.textMuted,
                        title: "Temporary Files",
                        subtitle: "Scan temporary files and trash data"
                    ) {
                        Toggle("", isOn: $settings.scanIncludeTempFiles)
                            .labelsHidden()
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "envelope.badge.fill",
                        iconColor: DS.brandTeal,
                        title: "Mail Attachments",
                        subtitle: "Scan cached Mail downloads"
                    ) {
                        Toggle("", isOn: $settings.scanIncludeMailAttachments)
                            .labelsHidden()
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "photo.on.rectangle.angled",
                        iconColor: Color(hex: "EC4899"),
                        title: "Photo Junk",
                        subtitle: "Scan Photos app cache and analysis junk"
                    ) {
                        Toggle("", isOn: $settings.scanIncludePhotoJunk)
                            .labelsHidden()
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "trash.fill",
                        iconColor: DS.danger,
                        title: "App Leftovers",
                        subtitle: "Scan leftover data from removed apps"
                    ) {
                        Toggle("", isOn: $settings.scanIncludeAppLeftovers)
                            .labelsHidden()
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "arrow.up.doc.fill",
                        iconColor: DS.danger,
                        title: "Large Files",
                        subtitle: "Scan large files in user folders"
                    ) {
                        Toggle("", isOn: $settings.scanIncludeLargeFiles)
                            .labelsHidden()
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "arrow.up.doc.fill",
                        iconColor: DS.danger,
                        title: "Large File Threshold",
                        subtitle: "Files larger than this are flagged"
                    ) {
                        HStack(spacing: 6) {
                            Slider(value: $settings.largeFileThresholdMB, in: 50...1000, step: 50)
                                .frame(width: 120)
                            Text("\(Int(settings.largeFileThresholdMB)) MB")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .frame(width: 55, alignment: .trailing)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("AUTOMATION")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                SettingsCard {
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "calendar.badge.clock",
                            iconColor: DS.brandTeal,
                            title: "Scheduled Auto Scan",
                            subtitle: "Run Smart Scan automatically in the background"
                        ) {
                            Toggle("", isOn: $settings.autoScanEnabled)
                                .labelsHidden()
                        }

                        Divider().padding(.leading, 44)

                        SettingsRow(
                            icon: "timer",
                            iconColor: DS.brandGreen,
                            title: "Scan Interval",
                            subtitle: "How often scheduled scan should run"
                        ) {
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
                            .frame(width: 80)
                            .disabled(!settings.autoScanEnabled)
                        }
                        .opacity(settings.autoScanEnabled ? 1.0 : 0.45)

                        Divider().padding(.leading, 44)

                        SettingsRow(
                            icon: "sparkles",
                            iconColor: DS.warning,
                            title: "Auto Clean After Scan",
                            subtitle: "Clean selected safe categories after scheduled scan"
                        ) {
                            Toggle("", isOn: $settings.autoCleanEnabled)
                                .labelsHidden()
                                .disabled(!settings.autoScanEnabled)
                        }
                        .opacity(settings.autoScanEnabled ? 1.0 : 0.45)

                        Divider().padding(.leading, 44)

                        SettingsRow(
                            icon: "slider.horizontal.3",
                            iconColor: DS.danger,
                            title: "Auto Clean Minimum",
                            subtitle: "Only clean when selected items reach this size"
                        ) {
                            HStack(spacing: 6) {
                                Slider(value: $settings.autoCleanMinimumMB, in: 50...2000, step: 50)
                                    .frame(width: 120)
                                    .disabled(!(settings.autoScanEnabled && settings.autoCleanEnabled))
                                Text("\(Int(settings.autoCleanMinimumMB)) MB")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .frame(width: 58, alignment: .trailing)
                            }
                        }
                        .opacity((settings.autoScanEnabled && settings.autoCleanEnabled) ? 1.0 : 0.45)
                    }
                }

                SettingsCard {
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "clock.badge.checkmark",
                            iconColor: DS.brandGreen,
                            title: "Last Scheduled Run",
                            subtitle: "Most recent background policy execution"
                        ) {
                            Text(formatPolicyDate(settings.autoLastRunAt))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Divider().padding(.leading, 44)

                        SettingsRow(
                            icon: "clock.badge",
                            iconColor: DS.brandTeal,
                            title: "Next Scheduled Run",
                            subtitle: "Estimated next automatic Smart Scan"
                        ) {
                            Text(nextScheduledRunText)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Divider().padding(.leading, 44)

                        SettingsRow(
                            icon: "checkmark.seal.fill",
                            iconColor: DS.warning,
                            title: "Policy Status",
                            subtitle: "Latest scheduled policy state"
                        ) {
                            Text(settings.autoLastPolicyStatus)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }

            // Scan scope info
            VStack(alignment: .leading, spacing: 10) {
                Text("SCAN LOCATIONS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                let locations = [
                    ("~/Library/Caches", "User application caches"),
                    ("~/Library/Logs", "Application log files"),
                    ("~/Library/Developer/Xcode", "Xcode derived data"),
                    ("~/.npm, ~/.gradle", "Development tool caches"),
                    ("/private/tmp", "System temporary files"),
                    ("~/Library/Application Support", "App leftover data"),
                    ("~/Documents, ~/Downloads, etc.", "Large file search")
                ]

                SettingsCard {
                    VStack(spacing: 0) {
                        ForEach(Array(locations.enumerated()), id: \.0) { i, loc in
                            HStack(spacing: 12) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(DS.brandGreen)
                                    .frame(width: 14)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(loc.0)
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    Text(loc.1)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            if i < locations.count - 1 {
                                Divider().padding(.leading, 40)
                            }
                        }
                    }
                }
            }

            Text("These switches control Smart Scan defaults. Dedicated tools still scan their own category when opened directly.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Tools Settings
    var toolsSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsHeader(icon: "wrench.and.screwdriver.fill", title: "Tools", color: DS.warning)

            // Browser Privacy
            VStack(alignment: .leading, spacing: 10) {
                Text("BROWSER PRIVACY")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                SettingsCard {
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "globe.americas.fill",
                            iconColor: Color(hex: "4285F4"),
                            title: "Google Chrome",
                            subtitle: "Scan Chrome caches, history, and cookies"
                        ) {
                            Toggle("", isOn: $settings.browserScanChrome).labelsHidden()
                        }
                        Divider().padding(.leading, 44)
                        SettingsRow(
                            icon: "safari.fill",
                            iconColor: Color(hex: "006CFF"),
                            title: "Safari",
                            subtitle: "Scan Safari caches, history, and cookies"
                        ) {
                            Toggle("", isOn: $settings.browserScanSafari).labelsHidden()
                        }
                        Divider().padding(.leading, 44)
                        SettingsRow(
                            icon: "flame.fill",
                            iconColor: Color(hex: "FF6611"),
                            title: "Firefox",
                            subtitle: "Scan Firefox caches, history, and cookies"
                        ) {
                            Toggle("", isOn: $settings.browserScanFirefox).labelsHidden()
                        }
                        Divider().padding(.leading, 44)
                        SettingsRow(
                            icon: "e.circle.fill",
                            iconColor: Color(hex: "0078D4"),
                            title: "Microsoft Edge",
                            subtitle: "Scan Edge caches, history, and cookies"
                        ) {
                            Toggle("", isOn: $settings.browserScanEdge).labelsHidden()
                        }
                    }
                }
            }

            // Duplicate Finder
            VStack(alignment: .leading, spacing: 10) {
                Text("DUPLICATE FINDER")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                SettingsCard {
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "doc.on.doc.fill",
                            iconColor: SectionTheme.theme(for: .duplicates).glow,
                            title: "Minimum File Size",
                            subtitle: "Only flag duplicates larger than this threshold"
                        ) {
                            HStack(spacing: 6) {
                                Slider(value: $settings.duplicateMinSizeMB, in: 0.1...50, step: 0.5)
                                    .frame(width: 110)
                                Text(settings.duplicateMinSizeMB < 1 ? "\(Int(settings.duplicateMinSizeMB * 1000)) KB" : "\(String(format: "%.1f", settings.duplicateMinSizeMB)) MB")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .frame(width: 55, alignment: .trailing)
                            }
                        }
                        Divider().padding(.leading, 44)
                        SettingsRow(
                            icon: "eye.slash.fill",
                            iconColor: DS.textMuted,
                            title: "Skip Hidden Files",
                            subtitle: "Ignore files starting with a dot (.hidden)"
                        ) {
                            Toggle("", isOn: $settings.duplicateSkipHiddenFiles).labelsHidden()
                        }
                    }
                }
            }

            // Space Lens
            VStack(alignment: .leading, spacing: 10) {
                Text("SPACE LENS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                SettingsCard {
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "eye.fill",
                            iconColor: SectionTheme.theme(for: .spaceLens).glow,
                            title: "Show Hidden Files",
                            subtitle: "Include hidden files and folders in the disk map"
                        ) {
                            Toggle("", isOn: $settings.spaceLensShowHiddenFiles).labelsHidden()
                        }
                    }
                }
            }

            // Memory Optimizer
            VStack(alignment: .leading, spacing: 10) {
                Text("MEMORY OPTIMIZER")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                SettingsCard {
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "memorychip",
                            iconColor: SectionTheme.theme(for: .performance).glow,
                            title: "Auto-Refresh Processes",
                            subtitle: "Automatically refresh process list every 5 seconds"
                        ) {
                            Toggle("", isOn: $settings.memoryAutoRefresh).labelsHidden()
                        }
                    }
                }
            }

            // Privacy & Protection
            VStack(alignment: .leading, spacing: 10) {
                Text("PRIVACY & PROTECTION")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                SettingsCard {
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "hand.raised.fill",
                            iconColor: DS.danger,
                            title: "Confirm Before Deleting",
                            subtitle: "Show confirmation dialog before removing privacy files"
                        ) {
                            Toggle("", isOn: $settings.privacyConfirmBeforeDelete).labelsHidden()
                        }
                    }
                }
                Text("Tip: privacy files are moved to Trash so you can recover them if needed.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Notification Settings
    var notificationSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsHeader(icon: "bell.badge.fill", title: "Notifications", color: DS.warning)

            // Master toggle + permission status
            VStack(alignment: .leading, spacing: 10) {
                Text("GENERAL")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                SettingsCard {
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "bell.fill",
                            iconColor: DS.warning,
                            title: "Enable Notifications",
                            subtitle: "Master toggle for all MacSweep notifications"
                        ) {
                            Toggle("", isOn: $settings.notificationsEnabled)
                                .labelsHidden()
                                .tint(DS.warning)
                        }

                        Divider().padding(.leading, 44)

                        SettingsRow(
                            icon: "speaker.wave.2.fill",
                            iconColor: DS.brandTeal,
                            title: "Notification Sound",
                            subtitle: "Play a sound when notifications are delivered"
                        ) {
                            Toggle("", isOn: $settings.notifySoundEnabled)
                                .labelsHidden()
                                .tint(DS.brandTeal)
                        }
                        .opacity(settings.notificationsEnabled ? 1.0 : 0.45)

                        Divider().padding(.leading, 44)

                        PermissionShortcutRow(
                            icon: "bell.badge",
                            iconColor: DS.brandGreen,
                            title: "System Permission",
                            subtitle: "Allow macOS to show notifications",
                            statusText: notificationStatusText
                        ) {
                            openSystemSettings("x-apple.systempreferences:com.apple.preference.notifications")
                        }
                    }
                }
            }

            // Per-category toggles
            VStack(alignment: .leading, spacing: 10) {
                Text("NOTIFICATION CATEGORIES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                SettingsCard {
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "sparkles.rectangle.stack",
                            iconColor: DS.brandGreen,
                            title: "Scan Complete",
                            subtitle: "Notify when a scan finishes"
                        ) {
                            Toggle("", isOn: $settings.notifyScanComplete)
                                .labelsHidden()
                                .tint(DS.brandGreen)
                        }

                        Divider().padding(.leading, 44)

                        SettingsRow(
                            icon: "shield.slash.fill",
                            iconColor: DS.danger,
                            title: "Threat Detected",
                            subtitle: "Alert when malware or adware is found"
                        ) {
                            Toggle("", isOn: $settings.notifyThreatDetected)
                                .labelsHidden()
                                .tint(DS.danger)
                        }

                        Divider().padding(.leading, 44)

                        SettingsRow(
                            icon: "memorychip",
                            iconColor: Color(hex: "FF8C3A"),
                            title: "Memory Warning",
                            subtitle: "Warn when RAM usage is critically high"
                        ) {
                            Toggle("", isOn: $settings.notifyMemoryWarning)
                                .labelsHidden()
                                .tint(Color(hex: "FF8C3A"))
                        }

                        Divider().padding(.leading, 44)

                        SettingsRow(
                            icon: "checkmark.shield",
                            iconColor: Color(hex: "169677"),
                            title: "Integrity Alert",
                            subtitle: "Alert on high-risk system integrity changes"
                        ) {
                            Toggle("", isOn: $settings.notifyIntegrityAlert)
                                .labelsHidden()
                                .tint(Color(hex: "169677"))
                        }

                        Divider().padding(.leading, 44)

                        SettingsRow(
                            icon: "arrow.down.circle.fill",
                            iconColor: DS.brandTeal,
                            title: "Update Available",
                            subtitle: "Notify when a new MacSweep version is released"
                        ) {
                            Toggle("", isOn: $settings.notifyUpdateAvailable)
                                .labelsHidden()
                                .tint(DS.brandTeal)
                        }

                        Divider().padding(.leading, 44)

                        SettingsRow(
                            icon: "sparkles",
                            iconColor: DS.success,
                            title: "Auto-Clean Complete",
                            subtitle: "Notify when automatic cleanup finishes"
                        ) {
                            Toggle("", isOn: $settings.notifyAutoClean)
                                .labelsHidden()
                                .tint(DS.success)
                        }
                    }
                }
                .opacity(settings.notificationsEnabled ? 1.0 : 0.45)
            }

            // Test notification button
            VStack(alignment: .leading, spacing: 10) {
                Text("TEST")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                SettingsCard {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(DS.brandGreen)
                                .frame(width: 28, height: 28)
                            Image(systemName: "bell.and.waves.left.and.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Send Test Notification")
                                .font(.system(size: 13, weight: .medium))
                            Text("Verify that macOS notifications are working")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Send") {
                            NotificationManager.shared.sendTestNotification()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(DS.brandGreen)
                        )
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
            }

            // Info note
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(DS.warning)
                    .font(.system(size: 13))
                Text("Notifications require macOS permission. If notifications don't appear, check System Settings → Notifications → MacSweep.")
                    .font(.system(size: 11))
                    .foregroundColor(DS.textMuted)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(DS.bgElevated))
        }
    }

    // MARK: - Antivirus Settings
    var antivirusSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsHeader(icon: "shield.fill", title: "Antivirus", color: DS.danger)

            // Protection
            SettingsCard {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "shield.fill",
                        iconColor: DS.success,
                        title: "Real-Time Protection",
                        subtitle: "Monitor file system activity and block threats as they appear"
                    ) {
                        Toggle("", isOn: $settings.antivirusRealtimeEnabled)
                            .labelsHidden()
                            .tint(DS.success)
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "ant.fill",
                        iconColor: DS.danger,
                        title: "Deep Scan Mode",
                        subtitle: "Scan inside archives and application bundles (slower but thorough)"
                    ) {
                        Toggle("", isOn: $settings.antivirusDeepScan)
                            .labelsHidden()
                            .tint(DS.danger)
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "arrow.down.circle.fill",
                        iconColor: DS.brandTeal,
                        title: "Scan Downloads Folder",
                        subtitle: "Automatically flag suspicious files in ~/Downloads"
                    ) {
                        Toggle("", isOn: $settings.antivirusScanDownloads)
                            .labelsHidden()
                            .tint(DS.brandTeal)
                    }
                }
            }

            // Scheduled Scans
            SettingsCard {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "calendar.badge.clock",
                        iconColor: DS.warning,
                        title: "Scheduled Malware Scan",
                        subtitle: "Run automatic malware scans on a set schedule"
                    ) {
                        Toggle("", isOn: $settings.antivirusAutoScanEnabled)
                            .labelsHidden()
                            .tint(DS.warning)
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "clock.fill",
                        iconColor: DS.textMuted,
                        title: "Scan Interval",
                        subtitle: "How often to run the scheduled malware scan"
                    ) {
                        Picker("", selection: $settings.antivirusAutoScanIntervalHours) {
                            Text("Every 12 hours").tag(12.0)
                            Text("Every 24 hours").tag(24.0)
                            Text("Every 3 days").tag(72.0)
                            Text("Every 7 days").tag(168.0)
                        }
                        .labelsHidden()
                        .frame(width: 160)
                        .disabled(!settings.antivirusAutoScanEnabled)
                        .opacity(settings.antivirusAutoScanEnabled ? 1.0 : 0.45)
                    }
                }
            }

            // Threat Response
            SettingsCard {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "lock.doc.fill",
                        iconColor: DS.warning,
                        title: "Auto-Quarantine Threats",
                        subtitle: "Move detected threats to quarantine automatically without asking"
                    ) {
                        Toggle("", isOn: $settings.antivirusQuarantineAuto)
                            .labelsHidden()
                            .tint(DS.warning)
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "bell.badge.fill",
                        iconColor: DS.brandGreen,
                        title: "Notify on Threat Detected",
                        subtitle: "Show a notification when malware or suspicious files are found"
                    ) {
                        Toggle("", isOn: $settings.antivirusNotifyOnThreat)
                            .labelsHidden()
                            .tint(DS.brandGreen)
                    }
                }
            }

            // Info note
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(DS.brandTeal)
                    .font(.system(size: 13))
                Text("MacSweep uses heuristic analysis and known threat signatures. For enterprise-grade protection, consider pairing with a dedicated security suite.")
                    .font(.system(size: 11))
                    .foregroundColor(DS.textMuted)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(DS.bgElevated))
        }
    }

    // MARK: - Integrity Monitor Settings
    var integritySettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsHeader(icon: "checkmark.shield", title: "System Integrity", color: Color(hex: "169677"))

            // Monitoring
            SettingsCard {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "play.circle.fill",
                        iconColor: DS.success,
                        title: "Auto-Start Monitoring",
                        subtitle: "Automatically begin monitoring when MacSweep launches"
                    ) {
                        Toggle("", isOn: $settings.integrityAutoMonitor)
                            .labelsHidden()
                            .tint(DS.success)
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "clock.fill",
                        iconColor: Color(hex: "169677"),
                        title: "Rescan Interval",
                        subtitle: "How often to automatically rescan all monitored items"
                    ) {
                        Picker("", selection: $settings.integrityScanIntervalMinutes) {
                            Text("5 min").tag(5.0)
                            Text("10 min").tag(10.0)
                            Text("15 min").tag(15.0)
                            Text("30 min").tag(30.0)
                            Text("60 min").tag(60.0)
                        }
                        .labelsHidden()
                        .frame(width: 100)
                    }

                    Divider().padding(.leading, 44)

                    SettingsRow(
                        icon: "bell.badge.fill",
                        iconColor: DS.warning,
                        title: "Notify on High Risk",
                        subtitle: "Show a notification when high or critical risk items are found"
                    ) {
                        Toggle("", isOn: $settings.integrityNotifyOnHighRisk)
                            .labelsHidden()
                            .tint(DS.warning)
                    }
                }
            }

            // Scan Scopes
            VStack(alignment: .leading, spacing: 10) {
                Text("SCAN SCOPES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                SettingsCard {
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "clock.badge.exclamationmark",
                            iconColor: DS.danger,
                            title: "Monitor Cron Jobs",
                            subtitle: "Scan crontab and /etc/periodic for scheduled tasks"
                        ) {
                            Toggle("", isOn: $settings.integrityMonitorCronJobs)
                                .labelsHidden()
                                .tint(DS.danger)
                        }

                        Divider().padding(.leading, 44)

                        SettingsRow(
                            icon: "lock.laptopcomputer",
                            iconColor: DS.brandTeal,
                            title: "Monitor SSH Config",
                            subtitle: "Watch ~/.ssh/config and /etc/ssh for unauthorized changes"
                        ) {
                            Toggle("", isOn: $settings.integrityMonitorSSH)
                                .labelsHidden()
                                .tint(DS.brandTeal)
                        }
                    }
                }
            }

            // Monitored locations info
            VStack(alignment: .leading, spacing: 10) {
                Text("MONITORED LOCATIONS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                let locations: [(String, String, Color)] = [
                    ("bolt.circle", "~/Library/LaunchAgents", Color(hex: "169677")),
                    ("bolt.shield", "/Library/LaunchAgents", Color(hex: "169677")),
                    ("bolt.shield", "/Library/LaunchDaemons", DS.warning),
                    ("clock.badge.exclamationmark", "User crontab & /etc/periodic", DS.danger),
                    ("person.badge.key", "Login Items (BTM agents)", DS.brandTeal),
                    ("network", "/etc/hosts", DS.brandGreen),
                    ("lock.laptopcomputer", "~/.ssh/config & /etc/ssh", DS.brandTeal),
                    ("puzzlepiece.extension", "/Library/SystemExtensions", Color(hex: "8B5CF6")),
                    ("cpu", "/Library/Extensions (kexts)", DS.danger),
                ]

                SettingsCard {
                    VStack(spacing: 0) {
                        ForEach(Array(locations.enumerated()), id: \.0) { i, loc in
                            HStack(spacing: 12) {
                                Image(systemName: loc.0)
                                    .font(.system(size: 10))
                                    .foregroundColor(loc.2)
                                    .frame(width: 14)
                                Text(loc.1)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(DS.textPrimary)
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(DS.success)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            if i < locations.count - 1 {
                                Divider().padding(.leading, 40)
                            }
                        }
                    }
                }
            }

            // Info note
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color(hex: "169677"))
                    .font(.system(size: 13))
                Text("System Integrity Monitor continuously watches persistence mechanisms, code signatures, and critical configurations. Items flagged as high risk should be reviewed carefully.")
                    .font(.system(size: 11))
                    .foregroundColor(DS.textMuted)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(DS.bgElevated))
        }
    }

    // MARK: - History Settings
    var historySettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsHeader(icon: "clock.arrow.circlepath", title: "Cleanup History", color: DS.warning)

            // Total freed banner
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(DS.success.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(DS.success)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(ByteCountFormatter.string(fromByteCount: scanEngine.totalFreedBytes, countStyle: .file))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.brandGradient)
                    Text("Total freed across all sessions")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DS.success.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(DS.success.opacity(0.15), lineWidth: 1)
                    )
            )

            // History list
            if scanEngine.freedHistory.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "clock.badge.xmark")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("No cleanup history yet")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 30)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("SESSIONS (\(scanEngine.freedHistory.count))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.6))
                            .tracking(1.2)
                        Spacer()
                        Button("Clear History") {
                            scanEngine.clearFreedHistory()
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DS.danger)
                        .buttonStyle(.plain)
                    }

                    SettingsCard {
                        VStack(spacing: 0) {
                            ForEach(Array(scanEngine.freedHistory.enumerated()), id: \.element.id) { i, rec in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(DS.success.opacity(0.12))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(DS.success)
                                            .font(.system(size: 14))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(rec.description)
                                            .font(.system(size: 12, weight: .medium))
                                            .lineLimit(1)
                                        Text(rec.dateFormatted)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(rec.sizeFormatted)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(DS.success)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                if i < scanEngine.freedHistory.count - 1 {
                                    Divider().padding(.leading, 58)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - About
    var aboutView: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsHeader(icon: "info.circle.fill", title: "About MacSweep", color: DS.brandGreen)

            // Logo + name + BestTech.pk
            HStack(spacing: 20) {
                Image("AboutBrandIconSVG")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("MacSweep")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(DS.textPrimary)
                    Text("Version \(appVersion)  •  By Mehmed Hunjra")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    // BestTech.pk badge
                    Button {
                        NSWorkspace.shared.open(URL(string: "https://besttech.pk")!)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 9, weight: .black))
                            Text("Powered by BestTech.pk")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(colors: [Color(hex: "FF416C"), Color(hex: "FF4B2B")],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                // Share button
                Button {
                    let items: [Any] = [
                        "I use MacSweep — the free open-source Mac cleaner by @MehmedHunjra! 🍃✨",
                        URL(string: "https://github.com/MehmedHunjra/MacSweep")!
                    ]
                    let picker = NSSharingServicePicker(items: items)
                    if let button = NSApp.keyWindow?.contentView {
                        picker.show(relativeTo: .zero, of: button, preferredEdge: .minY)
                    }
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DS.brandGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DS.brandGreen.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(DS.bgPanel)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.borderSubtle, lineWidth: 1))
            )

            // ── Follow Me / Social Links ─────────────────────────
            VStack(alignment: .leading, spacing: 10) {
                Text("FOLLOW ME")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                HStack(spacing: 10) {
                    SocialButton(icon: "x-logo", label: "X / Twitter", username: "@MehmedHunjra",
                                 gradient: [Color(hex: "000000"), Color(hex: "333333")],
                                 url: "https://x.com/MehmedHunjra")
                    SocialButton(icon: "github-logo", label: "GitHub", username: "MehmedHunjra",
                                 gradient: [Color(hex: "24292E"), Color(hex: "586069")],
                                 url: "https://github.com/MehmedHunjra")
                    SocialButton(icon: "linkedin-logo", label: "LinkedIn", username: "MehmedHunjra",
                                 gradient: [Color(hex: "0077B5"), Color(hex: "00A0DC")],
                                 url: "https://linkedin.com/in/MehmedHunjra")
                }
            }

            // ── Donate ──────────────────────────────────────────
            Button {
                NSWorkspace.shared.open(URL(string: "https://ko-fi.com/mehmedhunjra")!)
            } label: {
                HStack(spacing: 12) {
                    Text("☕")
                        .font(.system(size: 22))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Buy Me a Coffee")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Text("Support MacSweep development — totally optional!")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: "heart.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 18))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [DS.brandGreen, DS.brandTeal],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            // Info cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AboutCard(icon: "lock.open.fill", title: "Open Source", subtitle: "Free for everyone, forever", color: DS.brandGreen)
                AboutCard(icon: "hand.raised.fill", title: "Privacy First", subtitle: "No telemetry, no tracking", color: DS.brandTeal)
                AboutCard(icon: "bolt.fill", title: "Native Swift", subtitle: "Built with SwiftUI for macOS 13+", color: DS.warning)
                AboutCard(icon: "star.fill", title: "CleanMyMac Level", subtitle: "Professional cleaning tools", color: Color(hex: "8B5CF6"))
            }

            // Features list
            VStack(alignment: .leading, spacing: 10) {
                Text("ALL FEATURES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                let features: [(String, String, Color)] = [
                    ("sparkles.rectangle.stack", "Smart Scan — deep system junk scanner", DS.brandGreen),
                    ("xmark.bin.fill", "System Junk — caches, logs, temp files", DS.danger),
                    ("arrow.up.doc.fill", "Large Files — find space hogs instantly", DS.danger),
                    ("trash.fill", "App Leftovers — clean uninstalled app data", DS.danger),
                    ("doc.on.doc.fill", "Duplicates — find and remove duplicate files", Color(hex: "9B4DFF")),
                    ("globe", "Browser Privacy — clear history and cookies", DS.success),
                    ("wrench.and.screwdriver.fill", "Maintenance — flush DNS, free RAM, more", Color(hex: "8B5CF6")),
                    ("hand.raised.fill", "Privacy — clear sensitive data trails", DS.danger),
                    ("chart.pie.fill", "Space Lens — visual disk usage map", DS.brandTeal),
                    ("chevron.left.forwardslash.chevron.right", "Dev Cleaner — Xcode, VS Code, npm, CocoaPods", DS.danger),
                    ("bolt.shield", "Startup Optimizer — manage login items & launch agents", Color(hex: "FF8C3A")),
                    ("memorychip", "Memory Optimizer — free up RAM instantly", Color(hex: "FF8C3A")),
                    ("lock.shield", "Privacy & Protection — secure sensitive data", Color(hex: "D459A0")),
                    ("menubar.rectangle", "Menu Bar — always-on system monitor", DS.brandGreen),
                    ("square.stack.3d.up.fill", "Applications — manage and uninstall apps", Color(hex: "3A70E0")),
                    ("shield.slash.fill", "Malware Scanner — detect & remove malware", DS.danger),
                    ("shield.fill", "Real-Time Protection — live threat monitoring", DS.success),
                    ("ant.fill", "Adware Cleaner — remove adware & persistence agents", DS.warning),
                    ("lock.trianglebadge.exclamationmark.fill", "Ransomware Guard — monitor suspicious file changes", DS.danger),
                    ("network", "Network Monitor — track & block suspicious connections", DS.brandTeal),
                    ("lock.doc.fill", "Quarantine Manager — manage isolated threat files", Color(hex: "9B4DFF")),
                    ("checkmark.shield", "System Integrity — monitor persistence & configs", Color(hex: "169677")),
                    ("gearshape.fill", "Settings — full control of every feature", DS.textMuted),
                ]

                SettingsCard {
                    VStack(spacing: 0) {
                        ForEach(Array(features.enumerated()), id: \.0) { i, feat in
                            HStack(spacing: 10) {
                                Image(systemName: feat.0)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(feat.2)
                                    .frame(width: 16)
                                Text(feat.1)
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(DS.success)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            if i < features.count - 1 {
                                Divider().padding(.leading, 40)
                            }
                        }
                    }
                }
            }

            // ── Legal ──────────────────────────────────────────
            VStack(alignment: .leading, spacing: 10) {
                Text("LEGAL")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(1.2)

                SettingsCard {
                    VStack(spacing: 0) {
                        Button {
                            showPrivacyPolicy = true
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(DS.brandGreen.opacity(0.15))
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "hand.raised.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(DS.brandGreen)
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Privacy Policy")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("How we handle your data")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 52)

                        Button {
                            showTermsOfService = true
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(DS.brandTeal.opacity(0.15))
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(DS.brandTeal)
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Terms of Service")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Your responsibilities when using MacSweep")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                LegalSheet(type: .privacy)
            }
            .sheet(isPresented: $showTermsOfService) {
                LegalSheet(type: .terms)
            }
        }
    }

    // MARK: - Helpers

    private var accessibilityStatusText: String {
        AXIsProcessTrusted() ? "Granted" : "Not Granted"
    }

    private var notificationStatusText: String {
        switch notificationAuthStatus {
        case .authorized, .provisional, .ephemeral: return "Granted"
        case .denied: return "Denied"
        case .notDetermined: return "Not Granted"
        @unknown default: return "Unknown"
        }
    }

    private var locationStatusText: String {
        #if canImport(CoreLocation)
        switch locationAuthStatus {
        case .authorizedAlways, .authorizedWhenInUse: return "Granted"
        case .denied, .restricted: return "Denied"
        case .notDetermined: return "Not Granted"
        @unknown default: return "Unknown"
        }
        #else
        return "Unknown"
        #endif
    }

    private func refreshPermissionStatuses() {
        UNUserNotificationCenter.current().getNotificationSettings { notif in
            DispatchQueue.main.async {
                notificationAuthStatus = notif.authorizationStatus
            }
        }
        #if canImport(CoreLocation)
        locationAuthStatus = CLLocationManager().authorizationStatus
        #endif
    }

    private func openSystemSettings(_ deepLink: String) {
        guard let url = URL(string: deepLink) else { return }
        NSWorkspace.shared.open(url)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            refreshPermissionStatuses()
        }
    }

    private func formatPolicyDate(_ date: Date?) -> String {
        guard let date else { return "Never" }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }

    private var nextScheduledRunText: String {
        guard settings.autoScanEnabled else { return "Disabled" }
        guard let last = settings.autoLastRunAt else { return "Due now" }
        let next = last.addingTimeInterval(settings.autoScanIntervalSeconds)
        if next <= Date() { return "Due now" }
        return formatPolicyDate(next)
    }

    private var nextUpdateCheckText: String {
        guard settings.updateAutoCheckEnabled else { return "Disabled" }
        guard let last = settings.updateLastCheckAt else { return "Due now" }
        let next = last.addingTimeInterval(max(1, settings.updateCheckIntervalHours) * 3600)
        if next <= Date() { return "Due now" }
        return formatPolicyDate(next)
    }

    @ViewBuilder
    func settingsHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
        }
    }

    func registerLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Login item registration failed: \(error)")
            }
        }
    }
}

// MARK: - Settings Card
struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(DS.bgPanel)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DS.borderSubtle, lineWidth: 1)
            )
    }
}

// MARK: - Settings Row
struct SettingsRow<Control: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @ViewBuilder let control: Control

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(iconColor)
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            control
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct PermissionShortcutRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let statusText: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(iconColor)
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(statusText)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            Button("Open") { action() }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DS.brandGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DS.brandGreen.opacity(0.12))
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Social Button
struct SocialButton: View {
    let icon: String
    let label: String
    let username: String
    let gradient: [Color]
    let url: String
    @State private var hovered = false

    var body: some View {
        Button {
            NSWorkspace.shared.open(URL(string: url)!)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    // Use SF Symbols as stand-ins for brand icons
                    Image(systemName: iconName(for: icon))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(hovered ? 1.08 : 1.0)

                VStack(spacing: 1) {
                    Text(label)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primary)
                    Text(username)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DS.bgPanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(hovered ? Color(gradient[0]) : Color.gray.opacity(0.12), lineWidth: hovered ? 1.5 : 1)
                    )
            )
            .animation(.spring(duration: 0.2), value: hovered)
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }

    func iconName(for brand: String) -> String {
        switch brand {
        case "x-logo":        return "x.circle.fill"
        case "github-logo":   return "chevron.left.slash.chevron.right"
        case "linkedin-logo": return "person.crop.square.filled.and.at.rectangle"
        default:              return "link"
        }
    }
}

// MARK: - About Card
struct AboutCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.system(size: 12, weight: .bold))
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(DS.bgPanel)
        )
    }
}
