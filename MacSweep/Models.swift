import Foundation
import SwiftUI
import AppKit

// MARK: - Scan Category
enum ScanCategory: String, CaseIterable, Identifiable {
    case userCaches    = "User Caches"
    case logs          = "Log Files"
    case browserCaches = "Browser Caches"
    case development   = "Development Junk"
    case tempFiles     = "Temp Files"
    case appLeftovers  = "App Leftovers"
    case largeFiles    = "Large Files"
    case mailAttach    = "Mail Attachments"
    case photoJunk     = "Photo Junk"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .userCaches:    return "internaldrive"
        case .logs:          return "doc.text"
        case .browserCaches: return "globe"
        case .development:   return "hammer"
        case .tempFiles:     return "clock.arrow.circlepath"
        case .appLeftovers:  return "trash"
        case .largeFiles:    return "arrow.up.doc"
        case .mailAttach:    return "envelope.badge.fill"
        case .photoJunk:     return "photo.on.rectangle.angled"
        }
    }

    var color: Color {
        switch self {
        case .userCaches:    return Color(hex: "5B8DEF")
        case .logs:          return Color(hex: "F5A623")
        case .browserCaches: return Color(hex: "38A858")
        case .development:   return Color(hex: "3A6080")
        case .tempFiles:     return Color(hex: "9B9B9B")
        case .appLeftovers:  return Color(hex: "E03A3A")
        case .largeFiles:    return Color(hex: "CC44AA")
        case .mailAttach:    return Color(hex: "4A6AFF")
        case .photoJunk:     return Color(hex: "F8BBD0")
        }
    }

    var description: String {
        switch self {
        case .userCaches:    return "App cache files that can be safely regenerated"
        case .logs:          return "System and app log files"
        case .browserCaches: return "Chrome, Safari and Firefox cache data"
        case .development:   return "Xcode, npm, gradle and other dev tool junk"
        case .tempFiles:     return "Temporary files no longer needed"
        case .appLeftovers:  return "Leftover data from uninstalled apps"
        case .largeFiles:    return "Large files taking up significant space"
        case .mailAttach:    return "Cached mail attachments and downloads"
        case .photoJunk:     return "Photos cache, junk derivatives and analysis data"
        }
    }

    var isSafeByDefault: Bool {
        switch self {
        case .userCaches, .logs, .browserCaches, .development, .tempFiles, .mailAttach, .photoJunk:
            return true
        case .appLeftovers, .largeFiles:
            return false
        }
    }
}

// MARK: - App Section
enum AppSection: String, CaseIterable {
    case dashboard     = "Dashboard"
    case smartScan     = "Smart Scan"
    case systemJunk    = "System Junk"
    case largeFiles    = "Large Files"
    case appLeftovers  = "App Leftovers"
    case browser       = "Browser Privacy"
    case maintenance   = "Maintenance"
    case privacy       = "Privacy"
    case spaceLens     = "Space Lens"
    case devCleaner    = "Dev Cleaner"
    case performance   = "Startup Optimizer"
    case memoryOptimizer = "Memory Optimizer"
    case applications  = "Applications"
    case protection    = "Privacy & Protection"
    case duplicates    = "Duplicates"
    // Security
    case malwareScanner   = "Malware Scanner"
    case realtimeProtect  = "Real-Time Protection"
    case adwareCleaner    = "Adware Cleaner"
    case ransomwareGuard  = "Ransomware Guard"
    case networkMonitor   = "Network Monitor"
    case quarantine       = "Quarantine"
    case integrityMonitor = "System Integrity"
    case settings      = "Settings"

    var icon: String {
        switch self {
        case .dashboard:    return "gauge.medium"
        case .smartScan:    return "sparkles.rectangle.stack"
        case .systemJunk:   return "xmark.bin.fill"
        case .largeFiles:   return "arrow.up.doc.fill"
        case .appLeftovers: return "trash.fill"
        case .browser:      return "globe"
        case .maintenance:  return "wrench.and.screwdriver.fill"
        case .privacy:      return "hand.raised.fill"
        case .spaceLens:    return "chart.pie.fill"
        case .devCleaner:   return "chevron.left.forwardslash.chevron.right"
        case .performance:  return "bolt.shield"
        case .memoryOptimizer: return "memorychip"
        case .applications: return "square.stack.3d.up.fill"
        case .protection:   return "lock.shield"
        case .duplicates:   return "doc.on.doc.fill"
        case .settings:     return "gearshape.fill"
        case .malwareScanner:  return "shield.slash.fill"
        case .realtimeProtect: return "shield.fill"
        case .adwareCleaner:   return "ant.fill"
        case .ransomwareGuard: return "lock.trianglebadge.exclamationmark.fill"
        case .networkMonitor:  return "network"
        case .quarantine:      return "lock.doc.fill"
        case .integrityMonitor: return "checkmark.shield"
        }
    }

    var gradient: [Color] {
        switch self {
        case .dashboard:    return [Color(hex: "00C896"), Color(hex: "00A8B5")]
        case .smartScan:    return [Color(hex: "5B3BEB"), Color(hex: "7B5CF6")]
        case .systemJunk:   return [Color(hex: "1A7A50"), Color(hex: "00C896")]
        case .largeFiles:   return [Color(hex: "8B1F6E"), Color(hex: "CC44AA")]
        case .appLeftovers: return [Color(hex: "8B1A1A"), Color(hex: "E03A3A")]
        case .browser:      return [Color(hex: "1A5020"), Color(hex: "38A858")]
        case .maintenance:  return [Color(hex: "3A1C60"), Color(hex: "8B5CF6")]
        case .privacy:      return [Color(hex: "8B1A1A"), Color(hex: "E03A3A")]
        case .spaceLens:    return [Color(hex: "1A5A6E"), Color(hex: "00B4D8")]
        case .devCleaner:   return [Color(hex: "1A2840"), Color(hex: "3A6080")]
        case .performance:  return [Color(hex: "CC5A00"), Color(hex: "FF8C3A")]
        case .memoryOptimizer: return [Color(hex: "CC5A00"), Color(hex: "FF8C3A")]
        case .applications: return [Color(hex: "1A3D8F"), Color(hex: "3A70E0")]
        case .protection:   return [Color(hex: "AA1F6E"), Color(hex: "D459A0")]
        case .duplicates:   return [Color(hex: "5B1B8F"), Color(hex: "9B4DFF")]
        case .settings:     return [Color(hex: "1A1A2A"), Color(hex: "2A2A3E")]
        case .malwareScanner:  return [Color(hex: "8B0000"), Color(hex: "E03A3A")]
        case .realtimeProtect: return [Color(hex: "003A7A"), Color(hex: "0070E0")]
        case .adwareCleaner:   return [Color(hex: "7A3000"), Color(hex: "E07030")]
        case .ransomwareGuard: return [Color(hex: "6A0000"), Color(hex: "CC2020")]
        case .networkMonitor:  return [Color(hex: "004A6E"), Color(hex: "0090C0")]
        case .quarantine:      return [Color(hex: "4A0070"), Color(hex: "9B20C0")]
        case .integrityMonitor:  return [Color(hex: "0F6852"), Color(hex: "169677")]
        }
    }
}

// MARK: - Scan Item
struct ScanItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    let category: ScanCategory
    var isSelected: Bool

    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var url: URL {
        URL(fileURLWithPath: path)
    }
}

// MARK: - Disk Info
struct DiskInfo {
    let totalSpace: Int64
    let freeSpace: Int64

    var usedSpace: Int64 { totalSpace - freeSpace }

    var usedPercentage: Double {
        totalSpace > 0 ? Double(usedSpace) / Double(totalSpace) : 0
    }

    var totalFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file)
    }

    var freeFormatted: String {
        ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file)
    }

    var usedFormatted: String {
        ByteCountFormatter.string(fromByteCount: usedSpace, countStyle: .file)
    }
}

// MARK: - Storage Category for Space Lens
struct StorageCategory: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    let color: Color
    let icon: String

    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

// MARK: - Maintenance Task
struct MaintenanceTask: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let color: Color
    var isSelected: Bool = true
    var isCompleted: Bool = false
}

// MARK: - Running App Info
struct RunningAppInfo: Identifiable {
    let id: pid_t
    let name: String
    let bundleId: String
    let icon: NSImage?
    var cpuPercent: Double
    var memoryMB: Double
    var isActive: Bool

    var memoryFormatted: String {
        if memoryMB >= 1024 {
            return String(format: "%.1f GB", memoryMB / 1024)
        }
        return String(format: "%.0f MB", memoryMB)
    }

    var cpuFormatted: String {
        String(format: "%.1f%%", cpuPercent)
    }
}

// MARK: - Freed Space Record
struct FreedSpaceRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let bytes: Int64
    let description: String

    init(id: UUID = UUID(), date: Date = Date(), bytes: Int64, description: String) {
        self.id = id
        self.date = date
        self.bytes = bytes
        self.description = description
    }

    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    var dateFormatted: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}

// MARK: - App Settings (ObservableObject)
class AppSettings: ObservableObject {
    @Published var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin") }
    }
    @Published var launchAtLoginMenuBarOnly: Bool {
        didSet { UserDefaults.standard.set(launchAtLoginMenuBarOnly, forKey: "launchAtLoginMenuBarOnly") }
    }
    @Published var showMenuBarAlways: Bool {
        didSet { UserDefaults.standard.set(showMenuBarAlways, forKey: "showMenuBarAlways") }
    }
    @Published var showDockIcon: Bool {
        didSet {
            UserDefaults.standard.set(showDockIcon, forKey: "showDockIcon")
            NSApp.setActivationPolicy(showDockIcon ? .regular : .accessory)
        }
    }
    @Published var refreshInterval: Double {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval") }
    }
    @Published var menuBarShowCPU: Bool {
        didSet { UserDefaults.standard.set(menuBarShowCPU, forKey: "menuBarShowCPU") }
    }
    @Published var menuBarShowRAM: Bool {
        didSet { UserDefaults.standard.set(menuBarShowRAM, forKey: "menuBarShowRAM") }
    }
    @Published var menuBarShowDisk: Bool {
        didSet { UserDefaults.standard.set(menuBarShowDisk, forKey: "menuBarShowDisk") }
    }
    @Published var menuBarShowNetwork: Bool {
        didSet { UserDefaults.standard.set(menuBarShowNetwork, forKey: "menuBarShowNetwork") }
    }
    @Published var largeFileThresholdMB: Double {
        didSet { UserDefaults.standard.set(largeFileThresholdMB, forKey: "largeFileThresholdMB") }
    }
    @Published var scanIncludeUserCaches: Bool {
        didSet { UserDefaults.standard.set(scanIncludeUserCaches, forKey: "scanIncludeUserCaches") }
    }
    @Published var scanIncludeLogs: Bool {
        didSet { UserDefaults.standard.set(scanIncludeLogs, forKey: "scanIncludeLogs") }
    }
    @Published var scanIncludeBrowserCaches: Bool {
        didSet { UserDefaults.standard.set(scanIncludeBrowserCaches, forKey: "scanIncludeBrowserCaches") }
    }
    @Published var scanIncludeDevelopment: Bool {
        didSet { UserDefaults.standard.set(scanIncludeDevelopment, forKey: "scanIncludeDevelopment") }
    }
    @Published var scanIncludeTempFiles: Bool {
        didSet { UserDefaults.standard.set(scanIncludeTempFiles, forKey: "scanIncludeTempFiles") }
    }
    @Published var scanIncludeMailAttachments: Bool {
        didSet { UserDefaults.standard.set(scanIncludeMailAttachments, forKey: "scanIncludeMailAttachments") }
    }
    @Published var scanIncludeAppLeftovers: Bool {
        didSet { UserDefaults.standard.set(scanIncludeAppLeftovers, forKey: "scanIncludeAppLeftovers") }
    }
    @Published var scanIncludeLargeFiles: Bool {
        didSet { UserDefaults.standard.set(scanIncludeLargeFiles, forKey: "scanIncludeLargeFiles") }
    }
    @Published var scanIncludePhotoJunk: Bool {
        didSet { UserDefaults.standard.set(scanIncludePhotoJunk, forKey: "scanIncludePhotoJunk") }
    }
    // Browser tool settings
    @Published var browserScanChrome: Bool {
        didSet { UserDefaults.standard.set(browserScanChrome, forKey: "browserScanChrome") }
    }
    @Published var browserScanSafari: Bool {
        didSet { UserDefaults.standard.set(browserScanSafari, forKey: "browserScanSafari") }
    }
    @Published var browserScanFirefox: Bool {
        didSet { UserDefaults.standard.set(browserScanFirefox, forKey: "browserScanFirefox") }
    }
    @Published var browserScanEdge: Bool {
        didSet { UserDefaults.standard.set(browserScanEdge, forKey: "browserScanEdge") }
    }
    // Duplicate Finder settings
    @Published var duplicateMinSizeMB: Double {
        didSet { UserDefaults.standard.set(duplicateMinSizeMB, forKey: "duplicateMinSizeMB") }
    }
    @Published var duplicateSkipHiddenFiles: Bool {
        didSet { UserDefaults.standard.set(duplicateSkipHiddenFiles, forKey: "duplicateSkipHiddenFiles") }
    }
    // Space Lens settings
    @Published var spaceLensShowHiddenFiles: Bool {
        didSet { UserDefaults.standard.set(spaceLensShowHiddenFiles, forKey: "spaceLensShowHiddenFiles") }
    }
    // Memory Optimizer settings
    @Published var memoryAutoRefresh: Bool {
        didSet { UserDefaults.standard.set(memoryAutoRefresh, forKey: "memoryAutoRefresh") }
    }
    // Privacy settings
    @Published var privacyConfirmBeforeDelete: Bool {
        didSet { UserDefaults.standard.set(privacyConfirmBeforeDelete, forKey: "privacyConfirmBeforeDelete") }
    }
    @Published var autoScanEnabled: Bool {
        didSet { UserDefaults.standard.set(autoScanEnabled, forKey: "autoScanEnabled") }
    }
    @Published var autoScanIntervalHours: Double {
        didSet { UserDefaults.standard.set(autoScanIntervalHours, forKey: "autoScanIntervalHours") }
    }
    @Published var autoCleanEnabled: Bool {
        didSet { UserDefaults.standard.set(autoCleanEnabled, forKey: "autoCleanEnabled") }
    }
    @Published var autoCleanMinimumMB: Double {
        didSet { UserDefaults.standard.set(autoCleanMinimumMB, forKey: "autoCleanMinimumMB") }
    }
    @Published var autoLastRunAt: Date? {
        didSet {
            if let autoLastRunAt {
                UserDefaults.standard.set(autoLastRunAt, forKey: "autoLastRunAt")
            } else {
                UserDefaults.standard.removeObject(forKey: "autoLastRunAt")
            }
        }
    }
    @Published var autoLastCleanAt: Date? {
        didSet {
            if let autoLastCleanAt {
                UserDefaults.standard.set(autoLastCleanAt, forKey: "autoLastCleanAt")
            } else {
                UserDefaults.standard.removeObject(forKey: "autoLastCleanAt")
            }
        }
    }
    @Published var autoLastScanFoundBytes: Int64 {
        didSet { UserDefaults.standard.set(autoLastScanFoundBytes, forKey: "autoLastScanFoundBytes") }
    }
    @Published var autoLastCleanedBytes: Int64 {
        didSet { UserDefaults.standard.set(autoLastCleanedBytes, forKey: "autoLastCleanedBytes") }
    }
    @Published var autoLastPolicyStatus: String {
        didSet { UserDefaults.standard.set(autoLastPolicyStatus, forKey: "autoLastPolicyStatus") }
    }
    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }
    @Published var updateAutoCheckEnabled: Bool {
        didSet { UserDefaults.standard.set(updateAutoCheckEnabled, forKey: "updateAutoCheckEnabled") }
    }
    @Published var updateCheckIntervalHours: Double {
        didSet { UserDefaults.standard.set(updateCheckIntervalHours, forKey: "updateCheckIntervalHours") }
    }
    @Published var updateLastCheckAt: Date? {
        didSet {
            if let updateLastCheckAt {
                UserDefaults.standard.set(updateLastCheckAt, forKey: "updateLastCheckAt")
            } else {
                UserDefaults.standard.removeObject(forKey: "updateLastCheckAt")
            }
        }
    }

    // MARK: Antivirus Settings
    @Published var antivirusRealtimeEnabled: Bool {
        didSet { UserDefaults.standard.set(antivirusRealtimeEnabled, forKey: "antivirusRealtimeEnabled") }
    }
    @Published var antivirusAutoScanEnabled: Bool {
        didSet { UserDefaults.standard.set(antivirusAutoScanEnabled, forKey: "antivirusAutoScanEnabled") }
    }
    @Published var antivirusAutoScanIntervalHours: Double {
        didSet { UserDefaults.standard.set(antivirusAutoScanIntervalHours, forKey: "antivirusAutoScanIntervalHours") }
    }
    @Published var antivirusScanDownloads: Bool {
        didSet { UserDefaults.standard.set(antivirusScanDownloads, forKey: "antivirusScanDownloads") }
    }
    @Published var antivirusNotifyOnThreat: Bool {
        didSet { UserDefaults.standard.set(antivirusNotifyOnThreat, forKey: "antivirusNotifyOnThreat") }
    }
    @Published var antivirusQuarantineAuto: Bool {
        didSet { UserDefaults.standard.set(antivirusQuarantineAuto, forKey: "antivirusQuarantineAuto") }
    }
    @Published var antivirusDeepScan: Bool {
        didSet { UserDefaults.standard.set(antivirusDeepScan, forKey: "antivirusDeepScan") }
    }

    @Published var menuBarTab: String {
        didSet { UserDefaults.standard.set(menuBarTab, forKey: "menuBarTab") }
    }
    @Published var settingsSectionRaw: String {
        didSet { UserDefaults.standard.set(settingsSectionRaw, forKey: "settingsSectionRaw") }
    }
    @Published var mainSectionRaw: String {
        didSet { UserDefaults.standard.set(mainSectionRaw, forKey: "mainSectionRaw") }
    }

    // MARK: Integrity Monitor Settings
    @Published var integrityAutoMonitor: Bool {
        didSet { UserDefaults.standard.set(integrityAutoMonitor, forKey: "integrityAutoMonitor") }
    }
    @Published var integrityScanIntervalMinutes: Double {
        didSet { UserDefaults.standard.set(integrityScanIntervalMinutes, forKey: "integrityScanIntervalMinutes") }
    }
    @Published var integrityNotifyOnHighRisk: Bool {
        didSet { UserDefaults.standard.set(integrityNotifyOnHighRisk, forKey: "integrityNotifyOnHighRisk") }
    }
    @Published var integrityMonitorCronJobs: Bool {
        didSet { UserDefaults.standard.set(integrityMonitorCronJobs, forKey: "integrityMonitorCronJobs") }
    }
    @Published var integrityMonitorSSH: Bool {
        didSet { UserDefaults.standard.set(integrityMonitorSSH, forKey: "integrityMonitorSSH") }
    }

    // MARK: Selection settings
    @Published var selectionAlwaysShowCheckboxes: Bool {
        didSet { UserDefaults.standard.set(selectionAlwaysShowCheckboxes, forKey: "selectionAlwaysShowCheckboxes") }
    }
    @Published var selectionAutoSelectHighRisk: Bool {
        didSet { UserDefaults.standard.set(selectionAutoSelectHighRisk, forKey: "selectionAutoSelectHighRisk") }
    }

    // MARK: Notification category settings
    @Published var notifyScanComplete: Bool {
        didSet { UserDefaults.standard.set(notifyScanComplete, forKey: "notifyScanComplete") }
    }
    @Published var notifyThreatDetected: Bool {
        didSet { UserDefaults.standard.set(notifyThreatDetected, forKey: "notifyThreatDetected") }
    }
    @Published var notifyMemoryWarning: Bool {
        didSet { UserDefaults.standard.set(notifyMemoryWarning, forKey: "notifyMemoryWarning") }
    }
    @Published var notifyIntegrityAlert: Bool {
        didSet { UserDefaults.standard.set(notifyIntegrityAlert, forKey: "notifyIntegrityAlert") }
    }
    @Published var notifyUpdateAvailable: Bool {
        didSet { UserDefaults.standard.set(notifyUpdateAvailable, forKey: "notifyUpdateAvailable") }
    }
    @Published var notifyAutoClean: Bool {
        didSet { UserDefaults.standard.set(notifyAutoClean, forKey: "notifyAutoClean") }
    }
    @Published var notifySoundEnabled: Bool {
        didSet { UserDefaults.standard.set(notifySoundEnabled, forKey: "notifySoundEnabled") }
    }

    init() {
        let ud = UserDefaults.standard
        // First-run defaults: launch at login in menu bar mode.
        if ud.object(forKey: "launchAtLogin") == nil {
            ud.set(true, forKey: "launchAtLogin")
        }
        if ud.object(forKey: "launchAtLoginMenuBarOnly") == nil {
            ud.set(true, forKey: "launchAtLoginMenuBarOnly")
        }
        if ud.object(forKey: "scanIncludeUserCaches") == nil {
            ud.set(true, forKey: "scanIncludeUserCaches")
        }
        if ud.object(forKey: "scanIncludeLogs") == nil {
            ud.set(true, forKey: "scanIncludeLogs")
        }
        if ud.object(forKey: "scanIncludeBrowserCaches") == nil {
            ud.set(true, forKey: "scanIncludeBrowserCaches")
        }
        if ud.object(forKey: "scanIncludeDevelopment") == nil {
            ud.set(true, forKey: "scanIncludeDevelopment")
        }
        if ud.object(forKey: "scanIncludeTempFiles") == nil {
            ud.set(true, forKey: "scanIncludeTempFiles")
        }
        if ud.object(forKey: "scanIncludeMailAttachments") == nil {
            ud.set(true, forKey: "scanIncludeMailAttachments")
        }
        if ud.object(forKey: "scanIncludeAppLeftovers") == nil {
            ud.set(true, forKey: "scanIncludeAppLeftovers")
        }
        if ud.object(forKey: "selectionAlwaysShowCheckboxes") == nil {
            ud.set(true, forKey: "selectionAlwaysShowCheckboxes")
        }
        if ud.object(forKey: "selectionAutoSelectHighRisk") == nil {
            ud.set(true, forKey: "selectionAutoSelectHighRisk")
        }
        if ud.object(forKey: "scanIncludeLargeFiles") == nil {
            ud.set(true, forKey: "scanIncludeLargeFiles")
        }
        if ud.object(forKey: "scanIncludePhotoJunk") == nil {
            ud.set(true, forKey: "scanIncludePhotoJunk")
        }
        if ud.object(forKey: "autoScanEnabled") == nil {
            ud.set(false, forKey: "autoScanEnabled")
        }
        if ud.object(forKey: "autoScanIntervalHours") == nil {
            ud.set(24.0, forKey: "autoScanIntervalHours")
        }
        if ud.object(forKey: "autoCleanEnabled") == nil {
            ud.set(false, forKey: "autoCleanEnabled")
        }
        if ud.object(forKey: "autoCleanMinimumMB") == nil {
            ud.set(200.0, forKey: "autoCleanMinimumMB")
        }
        if ud.object(forKey: "autoLastPolicyStatus") == nil {
            ud.set("Idle", forKey: "autoLastPolicyStatus")
        }
        if ud.object(forKey: "antivirusRealtimeEnabled") == nil {
            ud.set(false, forKey: "antivirusRealtimeEnabled")
        }
        if ud.object(forKey: "antivirusAutoScanEnabled") == nil {
            ud.set(false, forKey: "antivirusAutoScanEnabled")
        }
        if ud.object(forKey: "antivirusAutoScanIntervalHours") == nil {
            ud.set(24.0, forKey: "antivirusAutoScanIntervalHours")
        }
        if ud.object(forKey: "antivirusScanDownloads") == nil {
            ud.set(true, forKey: "antivirusScanDownloads")
        }
        if ud.object(forKey: "antivirusNotifyOnThreat") == nil {
            ud.set(true, forKey: "antivirusNotifyOnThreat")
        }
        if ud.object(forKey: "antivirusQuarantineAuto") == nil {
            ud.set(false, forKey: "antivirusQuarantineAuto")
        }
        if ud.object(forKey: "antivirusDeepScan") == nil {
            ud.set(false, forKey: "antivirusDeepScan")
        }
        if ud.object(forKey: "updateAutoCheckEnabled") == nil {
            ud.set(true, forKey: "updateAutoCheckEnabled")
        }
        if ud.object(forKey: "updateCheckIntervalHours") == nil {
            ud.set(24.0, forKey: "updateCheckIntervalHours")
        }
        // Integrity Monitor defaults
        if ud.object(forKey: "integrityAutoMonitor") == nil {
            ud.set(true, forKey: "integrityAutoMonitor")
        }
        if ud.object(forKey: "integrityScanIntervalMinutes") == nil {
            ud.set(10.0, forKey: "integrityScanIntervalMinutes")
        }
        if ud.object(forKey: "integrityNotifyOnHighRisk") == nil {
            ud.set(true, forKey: "integrityNotifyOnHighRisk")
        }
        if ud.object(forKey: "integrityMonitorCronJobs") == nil {
            ud.set(true, forKey: "integrityMonitorCronJobs")
        }
        if ud.object(forKey: "integrityMonitorSSH") == nil {
            ud.set(true, forKey: "integrityMonitorSSH")
        }
        launchAtLogin       = ud.object(forKey: "launchAtLogin") as? Bool ?? true
        launchAtLoginMenuBarOnly = ud.object(forKey: "launchAtLoginMenuBarOnly") as? Bool ?? true
        showMenuBarAlways   = ud.object(forKey: "showMenuBarAlways") as? Bool ?? true
        showDockIcon        = ud.object(forKey: "showDockIcon") as? Bool ?? true
        refreshInterval     = ud.object(forKey: "refreshInterval") as? Double ?? 2.0
        menuBarShowCPU      = ud.object(forKey: "menuBarShowCPU") as? Bool ?? true
        menuBarShowRAM      = ud.object(forKey: "menuBarShowRAM") as? Bool ?? true
        menuBarShowDisk     = ud.object(forKey: "menuBarShowDisk") as? Bool ?? true
        menuBarShowNetwork  = ud.object(forKey: "menuBarShowNetwork") as? Bool ?? false
        largeFileThresholdMB = ud.object(forKey: "largeFileThresholdMB") as? Double ?? 100
        scanIncludeUserCaches = ud.object(forKey: "scanIncludeUserCaches") as? Bool ?? true
        scanIncludeLogs = ud.object(forKey: "scanIncludeLogs") as? Bool ?? true
        scanIncludeBrowserCaches = ud.object(forKey: "scanIncludeBrowserCaches") as? Bool ?? true
        scanIncludeDevelopment = ud.object(forKey: "scanIncludeDevelopment") as? Bool ?? true
        scanIncludeTempFiles = ud.object(forKey: "scanIncludeTempFiles") as? Bool ?? true
        scanIncludeMailAttachments = ud.object(forKey: "scanIncludeMailAttachments") as? Bool ?? true
        scanIncludeAppLeftovers = ud.object(forKey: "scanIncludeAppLeftovers") as? Bool ?? true
        scanIncludeLargeFiles = ud.object(forKey: "scanIncludeLargeFiles") as? Bool ?? true
        scanIncludePhotoJunk = ud.object(forKey: "scanIncludePhotoJunk") as? Bool ?? true
        browserScanChrome  = ud.object(forKey: "browserScanChrome")  as? Bool ?? true
        browserScanSafari  = ud.object(forKey: "browserScanSafari")  as? Bool ?? true
        browserScanFirefox = ud.object(forKey: "browserScanFirefox") as? Bool ?? true
        browserScanEdge    = ud.object(forKey: "browserScanEdge")    as? Bool ?? true
        duplicateMinSizeMB     = ud.object(forKey: "duplicateMinSizeMB")     as? Double ?? 1.0
        duplicateSkipHiddenFiles = ud.object(forKey: "duplicateSkipHiddenFiles") as? Bool ?? true
        spaceLensShowHiddenFiles = ud.object(forKey: "spaceLensShowHiddenFiles") as? Bool ?? false
        memoryAutoRefresh  = ud.object(forKey: "memoryAutoRefresh")  as? Bool ?? true
        privacyConfirmBeforeDelete = ud.object(forKey: "privacyConfirmBeforeDelete") as? Bool ?? true
        autoScanEnabled = ud.object(forKey: "autoScanEnabled") as? Bool ?? false
        autoScanIntervalHours = ud.object(forKey: "autoScanIntervalHours") as? Double ?? 24.0
        autoCleanEnabled = ud.object(forKey: "autoCleanEnabled") as? Bool ?? false
        autoCleanMinimumMB = ud.object(forKey: "autoCleanMinimumMB") as? Double ?? 200.0
        autoLastRunAt = ud.object(forKey: "autoLastRunAt") as? Date
        autoLastCleanAt = ud.object(forKey: "autoLastCleanAt") as? Date
        autoLastScanFoundBytes = (ud.object(forKey: "autoLastScanFoundBytes") as? NSNumber)?.int64Value ?? 0
        autoLastCleanedBytes = (ud.object(forKey: "autoLastCleanedBytes") as? NSNumber)?.int64Value ?? 0
        autoLastPolicyStatus = ud.string(forKey: "autoLastPolicyStatus") ?? "Idle"
        notificationsEnabled = ud.object(forKey: "notificationsEnabled") as? Bool ?? true
        updateAutoCheckEnabled = ud.object(forKey: "updateAutoCheckEnabled") as? Bool ?? true
        updateCheckIntervalHours = ud.object(forKey: "updateCheckIntervalHours") as? Double ?? 24.0
        updateLastCheckAt = ud.object(forKey: "updateLastCheckAt") as? Date
        antivirusRealtimeEnabled     = ud.object(forKey: "antivirusRealtimeEnabled")     as? Bool ?? false
        antivirusAutoScanEnabled     = ud.object(forKey: "antivirusAutoScanEnabled")     as? Bool ?? false
        antivirusAutoScanIntervalHours = ud.object(forKey: "antivirusAutoScanIntervalHours") as? Double ?? 24.0
        antivirusScanDownloads       = ud.object(forKey: "antivirusScanDownloads")       as? Bool ?? true
        antivirusNotifyOnThreat      = ud.object(forKey: "antivirusNotifyOnThreat")      as? Bool ?? true
        antivirusQuarantineAuto      = ud.object(forKey: "antivirusQuarantineAuto")      as? Bool ?? false
        antivirusDeepScan            = ud.object(forKey: "antivirusDeepScan")            as? Bool ?? false
        integrityAutoMonitor = ud.object(forKey: "integrityAutoMonitor") as? Bool ?? true
        integrityScanIntervalMinutes = ud.object(forKey: "integrityScanIntervalMinutes") as? Double ?? 10.0
        integrityNotifyOnHighRisk = ud.object(forKey: "integrityNotifyOnHighRisk") as? Bool ?? true
        integrityMonitorCronJobs = ud.object(forKey: "integrityMonitorCronJobs") as? Bool ?? true
        integrityMonitorSSH = ud.bool(forKey: "integrityMonitorSSH")

        selectionAlwaysShowCheckboxes = ud.bool(forKey: "selectionAlwaysShowCheckboxes")
        selectionAutoSelectHighRisk = ud.bool(forKey: "selectionAutoSelectHighRisk")

        // Notification category defaults
        notifyScanComplete    = ud.object(forKey: "notifyScanComplete")    as? Bool ?? true
        notifyThreatDetected  = ud.object(forKey: "notifyThreatDetected")  as? Bool ?? true
        notifyMemoryWarning   = ud.object(forKey: "notifyMemoryWarning")   as? Bool ?? true
        notifyIntegrityAlert  = ud.object(forKey: "notifyIntegrityAlert")  as? Bool ?? true
        notifyUpdateAvailable = ud.object(forKey: "notifyUpdateAvailable") as? Bool ?? true
        notifyAutoClean       = ud.object(forKey: "notifyAutoClean")       as? Bool ?? true
        notifySoundEnabled    = ud.object(forKey: "notifySoundEnabled")    as? Bool ?? true

        // Section preferences
        menuBarTab          = ud.string(forKey: "menuBarTab") ?? "Overview"
        settingsSectionRaw  = ud.string(forKey: "settingsSectionRaw") ?? "General"
        let storedMainSection = ud.string(forKey: "mainSectionRaw") ?? AppSection.dashboard.rawValue
        // Migrate old section name to the new standalone Startup Optimizer section label.
        if storedMainSection == "Optimize & Maintain" {
            mainSectionRaw = AppSection.performance.rawValue
        } else {
            mainSectionRaw = storedMainSection
        }
        integrityAutoMonitor = ud.object(forKey: "integrityAutoMonitor") as? Bool ?? true
        integrityScanIntervalMinutes = ud.object(forKey: "integrityScanIntervalMinutes") as? Double ?? 10.0
        integrityNotifyOnHighRisk = ud.object(forKey: "integrityNotifyOnHighRisk") as? Bool ?? true
        integrityMonitorCronJobs = ud.object(forKey: "integrityMonitorCronJobs") as? Bool ?? true
        integrityMonitorSSH = ud.object(forKey: "integrityMonitorSSH") as? Bool ?? true
    }

    var mainSection: AppSection {
        get { AppSection(rawValue: mainSectionRaw) ?? .dashboard }
        set { mainSectionRaw = newValue.rawValue }
    }

    var autoScanIntervalSeconds: TimeInterval {
        max(3600, autoScanIntervalHours * 3600)
    }

    // Backward compatibility for existing references.
    @available(*, deprecated, renamed: "largeFileThresholdMB")
    var largFileThresholdMB: Double {
        get { largeFileThresholdMB }
        set { largeFileThresholdMB = newValue }
    }
}

// MARK: - Notification Manager
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private weak var settings: AppSettings?

    enum Category: String {
        case scanComplete     = "SCAN_COMPLETE"
        case threatDetected   = "THREAT_DETECTED"
        case memoryWarning    = "MEMORY_WARNING"
        case integrityAlert   = "INTEGRITY_ALERT"
        case updateAvailable  = "UPDATE_AVAILABLE"
        case autoClean        = "AUTO_CLEAN"
        case test             = "TEST"
    }

    func configure(settings: AppSettings) {
        self.settings = settings
        requestPermissionIfNeeded()
    }

    func requestPermissionIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
            }
        }
    }

    func send(_ category: Category, title: String, body: String, subtitle: String? = nil) {
        guard let settings else { return }
        guard settings.notificationsEnabled else { return }

        // Check per-category toggle
        switch category {
        case .scanComplete:    guard settings.notifyScanComplete    else { return }
        case .threatDetected:  guard settings.notifyThreatDetected  else { return }
        case .memoryWarning:   guard settings.notifyMemoryWarning   else { return }
        case .integrityAlert:  guard settings.notifyIntegrityAlert  else { return }
        case .updateAvailable: guard settings.notifyUpdateAvailable else { return }
        case .autoClean:       guard settings.notifyAutoClean       else { return }
        case .test:            break // always send test notifications
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if let subtitle { content.subtitle = subtitle }
        content.categoryIdentifier = category.rawValue
        if settings.notifySoundEnabled {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: "\(category.rawValue)-\(UUID().uuidString)",
            content: content,
            trigger: nil // deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NotificationManager] Failed to deliver notification: \(error)")
            }
        }
    }

    /// Convenience helpers
    func notifyScanComplete(junkFound: String) {
        send(.scanComplete,
             title: "Scan Complete",
             body: "Found \(junkFound) of junk files ready to clean.",
             subtitle: "MacSweep")
    }

    func notifyThreatDetected(threatCount: Int) {
        send(.threatDetected,
             title: "⚠️ Threat Detected",
             body: "\(threatCount) potential threat\(threatCount == 1 ? "" : "s") found. Review recommended.",
             subtitle: "MacSweep Security")
    }

    func notifyMemoryWarning(usagePercent: Int) {
        send(.memoryWarning,
             title: "Memory Usage High",
             body: "RAM usage at \(usagePercent)%. Consider freeing memory.",
             subtitle: "MacSweep")
    }

    func notifyIntegrityAlert(description: String) {
        send(.integrityAlert,
             title: "🔒 Integrity Alert",
             body: description,
             subtitle: "MacSweep Security")
    }

    func playSound(_ name: String) {
        guard settings?.notifySoundEnabled ?? true else { return }
        NSSound(named: name)?.play()
    }

    func notifyUpdateAvailable(version: String) {
        send(.updateAvailable,
             title: "Update Available",
             body: "MacSweep v\(version) is available. Visit releases to download.",
             subtitle: "MacSweep")
    }

    func notifyAutoCleanComplete(freedBytes: Int64) {
        let freed = ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file)
        send(.autoClean,
             title: "Auto-Clean Complete",
             body: "Freed \(freed) of disk space automatically.",
             subtitle: "MacSweep")
    }

    func sendTestNotification() {
        send(.test,
             title: "🔔 Test Notification",
             body: "Notifications are working correctly!",
             subtitle: "MacSweep")
    }
}

// MARK: - App Update Engine (GitHub Releases)
@MainActor
final class AppUpdateEngine: ObservableObject {
    @Published private(set) var isChecking = false
    @Published private(set) var isUpdateAvailable = false
    @Published private(set) var latestVersion: String?
    @Published private(set) var latestReleaseURL: URL?
    @Published private(set) var statusMessage = "Never checked for updates"
    @Published private(set) var lastErrorMessage: String?

    let currentVersion: String

    private weak var settings: AppSettings?
    private var evaluationTimer: Timer?
    private var kickoffTask: Task<Void, Never>?

    private static let releasesPageURL = URL(string: "https://github.com/MehmedHunjra/MacSweep/releases")!
    private static let latestReleaseAPIURL = URL(string: "https://api.github.com/repos/MehmedHunjra/MacSweep/releases/latest")!

    init() {
        currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    deinit {
        evaluationTimer?.invalidate()
        kickoffTask?.cancel()
    }

    func configure(settings: AppSettings) {
        self.settings = settings
        if let last = settings.updateLastCheckAt, statusMessage == "Never checked for updates" {
            statusMessage = "Last checked \(Self.relativeDateText(last))"
        }
        startEvaluationTimerIfNeeded()
        scheduleKickoffEvaluation()
    }

    func evaluateAutoCheckIfNeeded() async {
        guard let settings else { return }
        guard settings.updateAutoCheckEnabled else { return }

        let intervalSeconds = max(1, settings.updateCheckIntervalHours) * 3600
        if let lastCheck = settings.updateLastCheckAt,
           Date().timeIntervalSince(lastCheck) < intervalSeconds {
            return
        }

        await checkForUpdates(manual: false)
    }

    func checkForUpdates(manual: Bool) async {
        guard !isChecking else { return }
        guard settings != nil else { return }

        isChecking = true
        lastErrorMessage = nil
        if manual {
            statusMessage = "Checking for updates..."
        }

        do {
            let release = try await fetchLatestRelease()
            let latestRaw = release.tagName.isEmpty ? (release.name ?? "") : release.tagName
            let latest = Self.normalizedVersion(latestRaw)
            let current = Self.normalizedVersion(currentVersion)

            latestVersion = latest.isEmpty ? current : latest
            latestReleaseURL = URL(string: release.htmlURL) ?? Self.releasesPageURL

            if latestVersion?.compare(current, options: .numeric) == .orderedDescending {
                isUpdateAvailable = true
                statusMessage = "Update available: v\(latestVersion ?? current)"
                NotificationManager.shared.notifyUpdateAvailable(version: latestVersion ?? current)
                NotificationManager.shared.playSound("Glass")
            } else {
                isUpdateAvailable = false
                statusMessage = "You are up to date"
            }

            settings?.updateLastCheckAt = Date()
        } catch {
            if manual {
                statusMessage = "Could not check updates"
            } else if statusMessage == "Never checked for updates" {
                statusMessage = "Automatic update check failed"
            }
            lastErrorMessage = Self.cleanErrorText(error)
        }

        isChecking = false
    }

    func openReleasePage() {
        NSWorkspace.shared.open(latestReleaseURL ?? Self.releasesPageURL)
    }

    private func startEvaluationTimerIfNeeded() {
        guard evaluationTimer == nil else { return }
        evaluationTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.evaluateAutoCheckIfNeeded()
            }
        }
        evaluationTimer?.tolerance = 20
    }

    private func scheduleKickoffEvaluation() {
        kickoffTask?.cancel()
        kickoffTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            await self?.evaluateAutoCheckIfNeeded()
        }
    }

    private func fetchLatestRelease() async throws -> GitHubRelease {
        var request = URLRequest(url: Self.latestReleaseAPIURL)
        request.timeoutInterval = 20
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("MacSweep/\(currentVersion)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateError.invalidServerResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw UpdateError.httpError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(GitHubRelease.self, from: data)
        } catch {
            throw UpdateError.invalidPayload
        }
    }

    private static func normalizedVersion(_ raw: String) -> String {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("v") || value.hasPrefix("V") {
            value.removeFirst()
        }
        if let stop = value.firstIndex(where: { $0 == " " || $0 == "(" }) {
            value = String(value[..<stop])
        }
        return value
    }

    private static func cleanErrorText(_ error: Error) -> String {
        if let localError = error as? LocalizedError, let description = localError.errorDescription {
            return description
        }
        return error.localizedDescription
    }

    private static func relativeDateText(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private struct GitHubRelease: Decodable {
        let tagName: String
        let name: String?
        let htmlURL: String

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case name
            case htmlURL = "html_url"
        }
    }

    private enum UpdateError: LocalizedError {
        case invalidServerResponse
        case httpError(Int)
        case invalidPayload

        var errorDescription: String? {
            switch self {
            case .invalidServerResponse:
                return "Update server returned an invalid response."
            case .httpError(let code):
                return "Update server error (HTTP \(code))."
            case .invalidPayload:
                return "Update metadata is not valid."
            }
        }
    }
}

// MARK: - Scheduled Auto Scan/Clean Policy Engine
@MainActor
final class AutoPolicyEngine: ObservableObject {
    @Published private(set) var isRunning = false

    private weak var scanEngine: ScanEngine?
    private weak var cleanEngine: CleanEngine?
    private weak var settings: AppSettings?
    private var evaluationTimer: Timer?
    private var scheduledKickoffTask: Task<Void, Never>?

    func configure(scanEngine: ScanEngine, cleanEngine: CleanEngine, settings: AppSettings) {
        self.scanEngine = scanEngine
        self.cleanEngine = cleanEngine
        self.settings = settings
        startEvaluationTimerIfNeeded()
        scheduleKickoffEvaluation()
    }

    deinit {
        evaluationTimer?.invalidate()
        scheduledKickoffTask?.cancel()
    }

    private func startEvaluationTimerIfNeeded() {
        guard evaluationTimer == nil else { return }
        evaluationTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.evaluateAndRunIfNeeded(force: false)
            }
        }
        evaluationTimer?.tolerance = 3.0
    }

    private func scheduleKickoffEvaluation() {
        scheduledKickoffTask?.cancel()
        scheduledKickoffTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await self?.evaluateAndRunIfNeeded(force: false)
        }
    }

    private func evaluateAndRunIfNeeded(force: Bool) async {
        guard let settings, let scanEngine, let cleanEngine else { return }
        guard settings.autoScanEnabled else {
            if settings.autoLastPolicyStatus != "Auto scan is off" {
                settings.autoLastPolicyStatus = "Auto scan is off"
            }
            return
        }
        guard !isRunning, !scanEngine.isScanning, !cleanEngine.isCleaning else { return }

        if !force, let lastRun = settings.autoLastRunAt {
            let nextRun = lastRun.addingTimeInterval(settings.autoScanIntervalSeconds)
            guard Date() >= nextRun else { return }
        }

        await runScheduledPolicy(
            scanEngine: scanEngine,
            cleanEngine: cleanEngine,
            settings: settings
        )
    }

    private func runScheduledPolicy(scanEngine: ScanEngine, cleanEngine: CleanEngine, settings: AppSettings) async {
        isRunning = true
        defer { isRunning = false }

        settings.autoLastPolicyStatus = "Running scheduled smart scan..."
        await scanEngine.startScan(mode: .smart)
        settings.autoLastRunAt = Date()
        settings.autoLastScanFoundBytes = scanEngine.totalFoundSize

        guard settings.autoCleanEnabled else {
            settings.autoLastCleanedBytes = 0
            settings.autoLastPolicyStatus = "Scan complete (auto clean off)"
            return
        }

        let minimumBytes = Int64(max(0, settings.autoCleanMinimumMB) * 1_000_000)
        let selectedBytes = scanEngine.selectedSize
        guard selectedBytes > 0 else {
            settings.autoLastCleanedBytes = 0
            settings.autoLastPolicyStatus = "Scan complete (nothing selected to clean)"
            return
        }
        guard selectedBytes >= minimumBytes else {
            settings.autoLastCleanedBytes = 0
            settings.autoLastPolicyStatus = "Scan complete (below auto-clean threshold)"
            return
        }

        settings.autoLastPolicyStatus = "Running scheduled auto clean..."
        await cleanEngine.clean(items: scanEngine.scanItems)
        let cleanedBytes = cleanEngine.cleanedSize
        settings.autoLastCleanedBytes = cleanedBytes
        settings.autoLastCleanAt = Date()

        if cleanedBytes > 0 {
            scanEngine.recordFreed(bytes: cleanedBytes, description: "Scheduled auto cleanup")
            await scanEngine.startScan(mode: .smart)
            settings.autoLastPolicyStatus = "Scan + clean complete"
        } else if cleanEngine.errors.isEmpty {
            settings.autoLastPolicyStatus = "Scan complete (nothing cleaned)"
        } else {
            settings.autoLastPolicyStatus = "Auto clean finished with some errors"
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Design System
struct DS {
    // Base backgrounds
    static let bg          = Color(hex: "0A0A12")
    static let bgPanel     = Color(hex: "12121E")
    static let bgElevated  = Color(hex: "1A1A2A")

    // Borders
    static let borderSubtle = Color.white.opacity(0.06)
    static let borderMid    = Color.white.opacity(0.10)

    // Brand (MacSweep vibrant green identity)
    static let brandGreen  = Color(hex: "169677")
    static let brandTeal   = Color(hex: "19B08B")

    // Semantic
    static let success     = Color(hex: "169677")
    static let warning     = Color(hex: "F5A623")
    static let danger      = Color(hex: "E03A3A")

    // Text
    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.60)
    static let textMuted     = Color.white.opacity(0.35)

    // Brand gradient
    static let brandGradient = LinearGradient(
        colors: [Color(hex: "00C896"), Color(hex: "00A8B5")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Sound helpers
    static func playSound(_ name: String) {
        NSSound(named: NSSound.Name(name))?.play()
    }
    static func playScanComplete()  { playSound("Submarine") }
    static func playCleanComplete() { playSound("Glass") }
    static func playError()         { playSound("Sosumi") }
}

// MARK: - Motion System
struct Motion {
    static let fast    = Animation.easeOut(duration: 0.12)
    static let std     = Animation.easeInOut(duration: 0.22)
    static let slow    = Animation.spring(duration: 0.45, bounce: 0.25)
    static let spring  = Animation.spring(duration: 0.55, bounce: 0.35)
    static let breathe = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    static let spin    = Animation.linear(duration: 2.0).repeatForever(autoreverses: false)

    static func stagger(_ index: Int) -> Animation {
        Animation.easeOut(duration: 0.4).delay(Double(index) * 0.06)
    }
}

// MARK: - Typography System
struct MSFont {
    static let heroTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title     = Font.system(size: 26, weight: .bold, design: .rounded)
    static let title2    = Font.system(size: 20, weight: .bold, design: .rounded)
    static let title3    = Font.system(size: 18, weight: .bold, design: .rounded)
    static let headline  = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let bodyBold  = Font.system(size: 13, weight: .semibold)
    static let body      = Font.system(size: 13, weight: .regular)
    static let caption   = Font.system(size: 11, weight: .medium)
    static let mono      = Font.system(size: 10, weight: .semibold, design: .monospaced)
}

// MARK: - Spacing System
struct MSSpacing {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 12
    static let md: CGFloat = 20
    static let lg: CGFloat = 28
    static let xl: CGFloat = 40
}

// MARK: - Section Theme
struct SectionTheme {
    let gradient: [Color]
    let glow: Color

    var linearGradient: LinearGradient {
        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func theme(for section: AppSection) -> SectionTheme {
        switch section {
        case .dashboard:    return SectionTheme(gradient: [Color(hex: "169677"), Color(hex: "19B08B")], glow: Color(hex: "169677"))
        case .smartScan:    return SectionTheme(gradient: [Color(hex: "169677"), Color(hex: "19B08B")], glow: Color(hex: "19B08B"))
        case .systemJunk:   return SectionTheme(gradient: [Color(hex: "0F6852"), Color(hex: "169677")], glow: Color(hex: "169677"))
        case .largeFiles:   return SectionTheme(gradient: [Color(hex: "8B1F6E"), Color(hex: "CC44AA")], glow: Color(hex: "CC44AA"))
        case .appLeftovers: return SectionTheme(gradient: [Color(hex: "8B1A1A"), Color(hex: "E03A3A")], glow: Color(hex: "E03A3A"))
        case .browser:      return SectionTheme(gradient: [Color(hex: "1A5020"), Color(hex: "38A858")], glow: Color(hex: "38A858"))
        case .maintenance:  return SectionTheme(gradient: [Color(hex: "3A1C60"), Color(hex: "8B5CF6")], glow: Color(hex: "8B5CF6"))
        case .privacy:      return SectionTheme(gradient: [Color(hex: "8B1A1A"), Color(hex: "E03A3A")], glow: Color(hex: "E03A3A"))
        case .spaceLens:    return SectionTheme(gradient: [Color(hex: "1A5A6E"), Color(hex: "00B4D8")], glow: Color(hex: "00B4D8"))
        case .devCleaner:   return SectionTheme(gradient: [Color(hex: "1A2840"), Color(hex: "3A6080")], glow: Color(hex: "3A6080"))
        case .performance:  return SectionTheme(gradient: [Color(hex: "CC5A00"), Color(hex: "FF8C3A")], glow: Color(hex: "FF8C3A"))
        case .memoryOptimizer: return SectionTheme(gradient: [Color(hex: "CC5A00"), Color(hex: "FF8C3A")], glow: Color(hex: "FF8C3A"))
        case .applications: return SectionTheme(gradient: [Color(hex: "1A3D8F"), Color(hex: "3A70E0")], glow: Color(hex: "3A70E0"))
        case .protection:   return SectionTheme(gradient: [Color(hex: "AA1F6E"), Color(hex: "D459A0")], glow: Color(hex: "D459A0"))
        case .duplicates:   return SectionTheme(gradient: [Color(hex: "5B1B8F"), Color(hex: "9B4DFF")], glow: Color(hex: "9B4DFF"))
        case .settings:     return SectionTheme(gradient: [Color(hex: "1A1A2A"), Color(hex: "2A2A3E")], glow: DS.brandGreen)
        case .malwareScanner:  return SectionTheme(gradient: [Color(hex: "8B0000"), Color(hex: "E03A3A")], glow: Color(hex: "E03A3A"))
        case .realtimeProtect: return SectionTheme(gradient: [Color(hex: "003A7A"), Color(hex: "0070E0")], glow: Color(hex: "0070E0"))
        case .adwareCleaner:   return SectionTheme(gradient: [Color(hex: "7A3000"), Color(hex: "E07030")], glow: Color(hex: "E07030"))
        case .ransomwareGuard: return SectionTheme(gradient: [Color(hex: "6A0000"), Color(hex: "CC2020")], glow: Color(hex: "CC2020"))
        case .networkMonitor:  return SectionTheme(gradient: [Color(hex: "004A6E"), Color(hex: "0090C0")], glow: Color(hex: "0090C0"))
        case .quarantine:      return SectionTheme(gradient: [Color(hex: "4A0070"), Color(hex: "9B20C0")], glow: Color(hex: "9B20C0"))
        case .integrityMonitor: return SectionTheme(gradient: [Color(hex: "0F6852"), Color(hex: "169677")], glow: Color(hex: "169677"))
        }
    }
}

// MARK: - AppTheme (backward-compatible wrapper over DS)
struct AppTheme {
    static let brandCyan     = DS.brandGreen
    static let brandBlue     = DS.brandTeal
    static let brandDarkBg   = DS.bgPanel
    static let brandDark     = DS.bg
    static let brandBorder   = DS.borderMid
    static let accent        = DS.brandGreen
    static let accentAlt     = DS.brandTeal
    static let success       = DS.success
    static let warning       = DS.warning
    static let danger        = DS.danger
    static let cardBg        = DS.bgPanel
    static let windowBg      = DS.bg
    static let sidebarBg     = DS.bg
    static let supportYellow = Color(hex: "FFD54A")
    static let supportAmber  = Color(hex: "FFB300")
    static let supportText   = Color(hex: "2B1B00")

    static var gradient: LinearGradient      { DS.brandGradient }
    static var brandGradient: LinearGradient { DS.brandGradient }

    static let supportGradient = LinearGradient(
        colors: [Color(hex: "FFD54A"), Color(hex: "FFB300")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func sectionGradient(_ section: AppSection) -> LinearGradient {
        SectionTheme.theme(for: section).linearGradient
    }
}

// MARK: - Support Coffee Button
struct SupportCoffeeButton: View {
    var compact: Bool = true
    @State private var isHovered = false

    var body: some View {
        Button {
            guard let url = URL(string: "https://ko-fi.com/mehmedhunjra") else { return }
            NSWorkspace.shared.open(url)
        } label: {
            HStack(spacing: compact ? 6 : 8) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: compact ? 11 : 13, weight: .bold))
                Text("Buy Me a Coffee")
                    .font(.system(size: compact ? 11 : 13, weight: .bold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundColor(AppTheme.supportText)
            .padding(.horizontal, compact ? 12 : 16)
            .padding(.vertical, compact ? 6 : 9)
            .background(Capsule().fill(AppTheme.supportGradient))
            .overlay(Capsule().stroke(Color.white.opacity(0.40), lineWidth: 1))
            .shadow(color: Color(hex: "FFCA28").opacity(isHovered ? 0.45 : 0.20), radius: isHovered ? 14 : 8, y: 3)
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .animation(Motion.fast, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Primary Tool Action Button
struct ToolPrimaryActionButton: View {
    let title: String
    let colors: [Color]
    var icon: String? = nil
    var minWidth: CGFloat = 176
    var disabled: Bool = false
    var action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                }
                Text(title)
                    .font(MSFont.headline)
                    .lineLimit(1)
            }
            .foregroundColor(disabled ? DS.textMuted : .white)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .frame(minWidth: minWidth)
            .background(
                Capsule()
                    .fill(LinearGradient(
                        colors: disabled ? [DS.bgElevated, DS.bgElevated] : colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .overlay(Capsule().stroke(DS.borderSubtle, lineWidth: 1))
            .shadow(
                color: (disabled ? Color.clear : (colors.first ?? .clear)).opacity(isHovered ? 0.50 : 0.28),
                radius: isHovered ? 18 : 10, y: 4
            )
            .scaleEffect((isHovered && !disabled) ? 1.03 : 1.0)
            .animation(Motion.fast, value: isHovered)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Window Support Overlay
struct WindowSupportOverlay: ViewModifier {
    var hidden: Bool
    var topPadding: CGFloat = 10
    var trailingPadding: CGFloat = 14

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .top, spacing: 0) {
            if !hidden {
                HStack {
                    Spacer(minLength: 0)
                    SupportCoffeeButton(compact: true)
                }
                .padding(.top, topPadding)
                .padding(.bottom, 6)
                .padding(.trailing, trailingPadding)
            }
        }
    }
}

extension View {
    func windowSupportOverlay(hidden: Bool = false, topPadding: CGFloat = 10, trailingPadding: CGFloat = 14) -> some View {
        modifier(WindowSupportOverlay(hidden: hidden, topPadding: topPadding, trailingPadding: trailingPadding))
    }
}

// MARK: - Shared Tool Landing View
struct ToolLandingView: View {
    let section: AppSection
    let subtitle: String
    var actionLabel: String = "Scan"
    var actionDisabled: Bool = false
    var extraContent: AnyView? = nil
    let onAction: () -> Void

    @State private var animateIn = false
    @State private var breathe   = false

    private var theme: SectionTheme { SectionTheme.theme(for: section) }

    var body: some View {
        ZStack {
            DS.bg
            RadialGradient(
                colors: [theme.glow.opacity(0.12), Color.clear],
                center: .center, startRadius: 0, endRadius: 500
            )

            VStack(spacing: 0) {
                Spacer()

                // 3D Glass Icon
                ZStack {
                    Circle()
                        .fill(theme.glow.opacity(breathe ? 0.18 : 0.06))
                        .frame(width: 180, height: 180)
                        .blur(radius: 40)

                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(theme.linearGradient)
                        .frame(width: 110, height: 110)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.clear],
                                    startPoint: .top, endPoint: .center
                                ))
                        )
                        .overlay(
                            Image(systemName: section.icon)
                                .font(.system(size: 42, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: theme.glow.opacity(0.55), radius: 32, y: 12)
                }
                .scaleEffect(breathe ? 1.045 : 1.0)
                .opacity(animateIn ? 1 : 0)
                .scaleEffect(animateIn ? 1 : 0.75)

                Spacer().frame(height: 34)

                Text(section.rawValue)
                    .font(MSFont.heroTitle)
                    .foregroundColor(DS.textPrimary)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 14)

                Spacer().frame(height: 10)

                Text(subtitle)
                    .font(MSFont.body)
                    .foregroundColor(DS.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)

                if let extra = extraContent {
                    Spacer().frame(height: 20)
                    extra.opacity(animateIn ? 1 : 0)
                }

                Spacer()

                Button(action: onAction) {
                    Text(actionLabel)
                        .font(MSFont.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Capsule().fill(theme.linearGradient))
                        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                        .shadow(color: theme.glow.opacity(0.40), radius: 18, y: 6)
                }
                .buttonStyle(.plain)
                .disabled(actionDisabled)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 18)

                Spacer().frame(height: 48)
            }
        }
        .onAppear {
            withAnimation(Motion.spring) { animateIn = true }
            withAnimation(Motion.breathe) { breathe = true }
        }
    }
}

// MARK: - Shared Tool Scanning View
struct ToolScanningView: View {
    let section: AppSection
    var scanningTitle: String = "Scanning..."
    @Binding var currentPath: String
    let onStop: () -> Void

    @State private var rotation: Double = 0
    @State private var breathe = false

    private var theme: SectionTheme { SectionTheme.theme(for: section) }

    private var displayPath: String {
        let parts = currentPath.split(separator: "/")
        guard parts.count >= 2 else { return currentPath }
        return parts.suffix(2).joined(separator: "/")
    }

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            RadialGradient(
                colors: [theme.glow.opacity(0.12), Color.clear],
                center: .center, startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    // Outer breathing halo
                    Circle()
                        .stroke(theme.glow.opacity(breathe ? 0.25 : 0.06), lineWidth: 1.5)
                        .frame(width: 176, height: 176)

                    // Spinning arc
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            AngularGradient(colors: [theme.glow, Color.clear], center: .center),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 152, height: 152)
                        .rotationEffect(.degrees(rotation))

                    // Glow
                    Circle()
                        .fill(theme.glow.opacity(breathe ? 0.14 : 0.05))
                        .frame(width: 130, height: 130)
                        .blur(radius: 22)

                    // Icon
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(theme.linearGradient)
                        .frame(width: 100, height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [Color.white.opacity(0.30), Color.clear],
                                    startPoint: .top, endPoint: .center
                                ))
                        )
                        .overlay(
                            Image(systemName: section.icon)
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: theme.glow.opacity(0.50), radius: 24, y: 8)
                        .scaleEffect(breathe ? 1.04 : 1.0)
                }

                Spacer().frame(height: 40)

                Text(scanningTitle)
                    .font(MSFont.title2)
                    .foregroundColor(DS.textPrimary)

                Spacer().frame(height: 14)

                Text(currentPath.isEmpty ? "Preparing..." : displayPath)
                    .font(MSFont.mono)
                    .foregroundColor(DS.textMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 440)
                    .animation(Motion.std, value: displayPath)

                Spacer()

                Button(action: onStop) {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("Stop")
                            .font(MSFont.headline)
                    }
                    .foregroundColor(.white)
                    .frame(width: 160, height: 44)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
                    .overlay(Capsule().stroke(DS.borderMid, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Spacer().frame(height: 48)
            }
        }
        .onAppear {
            withAnimation(Motion.breathe) { breathe = true }
            withAnimation(Motion.spin) { rotation = 360 }
        }
    }
}

