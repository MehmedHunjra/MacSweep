import SwiftUI

struct MaintenanceView: View {
    @Binding var selectedTab: Int

    @State private var tasks: [MaintenanceTask] = [
        MaintenanceTask(name: "Flush DNS Cache", description: "Clear the DNS resolver cache to fix connection issues", icon: "network", color: Color(hex: "3A70E0")),
        MaintenanceTask(name: "Rebuild Spotlight Index", description: "Reindex Spotlight for faster and more accurate search", icon: "magnifyingglass", color: DS.warning),
        MaintenanceTask(name: "Repair Disk Permissions", description: "Fix incorrect file permissions that may cause issues", icon: "lock.shield.fill", color: DS.success),
        MaintenanceTask(name: "Free Purgeable Space", description: "Ask macOS to release purgeable disk space", icon: "internaldrive.fill", color: Color(hex: "9B4DFF")),
        MaintenanceTask(name: "Clear Font Caches", description: "Remove corrupted font caches that slow down apps", icon: "textformat", color: DS.danger),
        MaintenanceTask(name: "Rebuild Launch Services", description: "Fix duplicate 'Open With' menu entries", icon: "arrow.up.forward.app.fill", color: Color(hex: "00A8B5")),
        MaintenanceTask(name: "Clear System Caches", description: "Remove outdated system cache files", icon: "gearshape.fill", color: DS.textSecondary),
        MaintenanceTask(name: "Run Maintenance Scripts", description: "Execute macOS daily, weekly, and monthly scripts", icon: "terminal.fill", color: DS.brandGreen),
    ]

    @EnvironmentObject var navManager: NavigationManager

    @State private var isRunning  = false
    @State private var progress   = 0.0
    @State private var currentTask = ""
    @State private var completed  = false
    @State private var results: [String] = []

    private let theme = SectionTheme.theme(for: .maintenance)

    var selectedTasks: [MaintenanceTask] { tasks.filter(\.isSelected) }

    var body: some View {
        VStack(spacing: 0) {
            headerWithBackButton

            if !isRunning && !completed {
                ToolLandingView(
                    section: .maintenance,
                    subtitle: "Optimize your Mac's performance and fix\ncommon system issues automatically.",
                    actionLabel: "Run Tasks",
                    extraContent: AnyView(taskListPanel),
                    onAction: { runMaintenance() }
                )
            } else if isRunning {
                ToolScanningView(
                    section: .maintenance,
                    scanningTitle: "Running Maintenance...",
                    currentPath: $currentTask,
                    onStop: {
                        // For Maintenance, force quitting scripts midway is dangerous, but we can return back.
                        isRunning = false
                        completed = false
                        selectedTab = 0
                    }
                )
            } else if completed {
                completedView
            }
        }
        .background(DS.bg)
    }

    var headerWithBackButton: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Button {
                        if isRunning || completed {
                            isRunning = false
                            completed = false
                            results = []
                        }
                        // Prefer resetting any in-tool state before leaving the section.
                        if selectedTab != 0 {
                            selectedTab = 0
                            return
                        }
                        if !navManager.goBackInCurrentSection() {
                            navManager.goBack()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor((navManager.canGoBackInCurrentSection || navManager.canGoBack || selectedTab != 0) ? DS.textSecondary : DS.textMuted.opacity(0.5))
                            .frame(width: 32, height: 32)
                            .background((navManager.canGoBackInCurrentSection || navManager.canGoBack || selectedTab != 0) ? DS.bgElevated : DS.bgElevated.opacity(0.5))
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(DS.borderSubtle, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(!(navManager.canGoBackInCurrentSection || navManager.canGoBack || selectedTab != 0))

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
                            .overlay(Circle().strokeBorder(DS.borderSubtle, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(!(navManager.canGoForwardInCurrentSection || navManager.canGoForward))
                }

                Text("Maintenance")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(DS.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider().background(DS.borderSubtle)
        }
    }

    // MARK: - Task List Panel (shown in landing extraContent)
    private var taskListPanel: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(selectedTasks.count) of \(tasks.count) Tasks Selected")
                    .font(MSFont.caption)
                    .foregroundColor(DS.textMuted)
                Spacer()
                Button(tasks.allSatisfy(\.isSelected) ? "Deselect All" : "Select All") {
                    let target = !tasks.allSatisfy(\.isSelected)
                    for i in tasks.indices { tasks[i].isSelected = target }
                }
                .font(MSFont.caption)
                .foregroundColor(theme.glow)
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, _ in
                    MaintenanceTaskCard(task: $tasks[index])
                }
            }
        }
        .frame(maxWidth: 520)
    }

    // MARK: - Completed View
    private var completedView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 24)

            ZStack {
                Circle()
                    .fill(DS.success.opacity(0.12))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(DS.success)
            }

            Text("Maintenance Complete")
                .font(MSFont.title2)
                .foregroundColor(DS.textPrimary)

            ScrollView(showsIndicators: true) {
                VStack(spacing: 8) {
                    ForEach(results, id: \.self) { result in
                        let isFailure = result.hasPrefix("✗")
                        HStack(spacing: 12) {
                            Image(systemName: isFailure ? "xmark.octagon.fill" : "checkmark.circle.fill")
                                .foregroundColor(isFailure ? DS.warning : DS.success)
                                .font(.system(size: 14))
                            Text(result)
                                .font(MSFont.body)
                                .foregroundColor(isFailure ? DS.warning : DS.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(DS.bgPanel)
                                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(DS.borderSubtle, lineWidth: 1))
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: 300)

            HStack(spacing: 12) {
                Button {
                    completed = false
                    results = []
                    runMaintenance()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Run Again")
                    }
                    .font(MSFont.headline)
                    .foregroundColor(DS.textSecondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(DS.bgElevated)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button("Done") {
                    completed = false
                    results = []
                    selectedTab = 0
                }
                .font(MSFont.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(theme.linearGradient)
                .clipShape(Capsule())
                .buttonStyle(.plain)
            }
            .padding(.top, 8)

            Spacer()
        }
        .background(DS.bg)
    }
}

// MARK: - Maintenance Task Row

struct MaintenanceTaskRowPro: View {
    @Binding var task: MaintenanceTask
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 14) {
            Toggle("", isOn: $task.isSelected)
                .labelsHidden()
                .toggleStyle(.checkbox)
                .animation(Motion.std, value: task.isSelected)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(task.color.opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: task.icon)
                    .font(.system(size: 14))
                    .foregroundColor(task.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(MSFont.headline)
                    .foregroundColor(DS.textPrimary)
                Text(task.description)
                    .font(MSFont.caption)
                    .foregroundColor(DS.textMuted)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(isHovered ? DS.bgElevated : Color.clear)
        .animation(Motion.fast, value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Maintenance Task Card (for 2-column grid)
struct MaintenanceTaskCard: View {
    @Binding var task: MaintenanceTask
    @State private var isHovered = false

    var body: some View {
        Button {
            withAnimation(Motion.std) { task.isSelected.toggle() }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(task.color.opacity(0.18))
                        .frame(width: 32, height: 32)
                    Image(systemName: task.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(task.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DS.textPrimary)
                        .lineLimit(1)
                    Text(task.description)
                        .font(.system(size: 10))
                        .foregroundColor(DS.textMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Image(systemName: task.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(task.isSelected ? task.color : DS.textMuted.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovered ? DS.bgElevated : DS.bgPanel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(task.isSelected ? task.color.opacity(0.4) : DS.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// Unused legacy row — kept for compatibility
struct MaintenanceTaskRow: View {
    @Binding var task: MaintenanceTask
    var body: some View {
        MaintenanceTaskRowPro(task: $task)
    }
}

extension MaintenanceView {
    private func runMaintenance() {
        guard !selectedTasks.isEmpty else { return }
        isRunning = true
        progress = 0
        results = []
        completed = false

        let selectedNames = selectedTasks.map(\.name)
        let total = Double(max(selectedNames.count, 1))

        Task {
            let adminTaskNames = selectedNames.filter {
                MaintenanceRunner.skipReason(for: $0) == nil
                    && MaintenanceRunner.maintenanceCommand(for: $0)?.requiresAdmin == true
            }
            let adminBatch: (results: [String: Bool], canceled: Bool)
            if adminTaskNames.isEmpty {
                adminBatch = ([:], false)
            } else {
                currentTask = "Authorizing maintenance tasks..."
                adminBatch = await Task.detached(priority: .userInitiated) {
                    MaintenanceRunner.runPrivilegedCommandBatch(taskNames: adminTaskNames)
                }.value
            }

            for (idx, taskName) in selectedNames.enumerated() {
                currentTask = taskName
                let taskResult = await Task.detached(priority: .userInitiated) {
                    MaintenanceRunner.runMaintenanceTask(
                        named: taskName,
                        adminResults: adminBatch.results,
                        adminCanceled: adminBatch.canceled
                    )
                }.value

                if taskResult.success {
                    results.append(taskResult.message == "done" ? "✓ \(taskName)" : "✓ \(taskName) (\(taskResult.message))")
                } else {
                    results.append("✗ \(taskName) (\(taskResult.message))")
                }
                progress = Double(idx + 1) / total
            }

            isRunning = false
            completed = true
            DS.playCleanComplete()
        }
    }
}

private enum MaintenanceRunner {
    struct TaskResult {
        let success: Bool
        let message: String
    }

    static func runMaintenanceTask(
        named name: String,
        adminResults: [String: Bool],
        adminCanceled: Bool
    ) -> TaskResult {
        if let skip = skipReason(for: name) {
            return TaskResult(success: true, message: skip)
        }
        guard let config = maintenanceCommand(for: name) else {
            return TaskResult(success: true, message: "not available on this macOS")
        }
        if config.requiresAdmin {
            if adminCanceled { return TaskResult(success: false, message: "canceled by user") }
            let ok = adminResults[name] ?? false
            return TaskResult(success: ok, message: ok ? "done" : "failed")
        }
        let ok = runShellCommand(config.command)
        return TaskResult(success: ok, message: ok ? "done" : "failed")
    }

    static func skipReason(for name: String) -> String? {
        switch name {
        case "Repair Disk Permissions":
            return "not required on modern macOS"
        case "Rebuild Spotlight Index":
            guard FileManager.default.isExecutableFile(atPath: "/usr/bin/mdutil") else {
                return "not available on this macOS"
            }
            if let enabled = spotlightIndexingEnabled(), !enabled { return "indexing is disabled" }
            return nil
        case "Free Purgeable Space":
            if purgeExecutablePath() != nil { return nil }
            let hasTMUtil = FileManager.default.isExecutableFile(atPath: "/usr/bin/tmutil")
            guard hasTMUtil else { return "not available on this macOS" }
            return hasLocalSnapshots() ? nil : "no local snapshots to thin"
        case "Clear System Caches", "Run Maintenance Scripts":
            return periodicExecutablePath() == nil ? "not available on this macOS" : nil
        default:
            return nil
        }
    }

    private static func spotlightIndexingEnabled() -> Bool? {
        let result = runShellCommandWithOutput("/usr/bin/mdutil -s /")
        guard !result.output.isEmpty else { return nil }
        let lower = result.output.lowercased()
        if lower.contains("indexing disabled") { return false }
        if lower.contains("indexing enabled") { return true }
        return nil
    }

    private static func hasLocalSnapshots() -> Bool {
        let result = runShellCommandWithOutput("/usr/bin/tmutil listlocalsnapshots /")
        guard result.status == 0 else { return false }
        return result.output.lowercased().contains("com.apple.timemachine.")
    }

    static func periodicExecutablePath() -> String? {
        ["/usr/sbin/periodic", "/usr/bin/periodic"].first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    static func purgeExecutablePath() -> String? {
        ["/usr/sbin/purge", "/usr/bin/purge"].first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    static func maintenanceCommand(for name: String) -> (command: String, requiresAdmin: Bool)? {
        switch name {
        case "Flush DNS Cache":
            return ("/usr/bin/dscacheutil -flushcache; /usr/bin/killall -HUP mDNSResponder", true)
        case "Rebuild Spotlight Index":
            return ("/usr/bin/mdutil -E /", true)
        case "Repair Disk Permissions":
            return ("/usr/sbin/diskutil resetUserPermissions / $(id -u)", true)
        case "Free Purgeable Space":
            if let purge = purgeExecutablePath() { return ("\(purge)", true) }
            if FileManager.default.isExecutableFile(atPath: "/usr/bin/tmutil") {
                return ("/usr/bin/tmutil thinlocalsnapshots / 10000000000 4", true)
            }
            return nil
        case "Clear Font Caches":
            return ("/usr/bin/atsutil databases -remove; /usr/bin/atsutil server -shutdown; /usr/bin/atsutil server -ping", false)
        case "Rebuild Launch Services":
            let lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
            guard FileManager.default.isExecutableFile(atPath: lsregister) else { return nil }
            return ("\(lsregister) -seed -r -domain local -domain system -domain user >/dev/null 2>&1; code=$?; [ $code -eq 0 ] || [ $code -eq 2 ]", false)
        case "Clear System Caches":
            guard let periodic = periodicExecutablePath() else { return nil }
            return ("\(periodic) daily", true)
        case "Run Maintenance Scripts":
            guard let periodic = periodicExecutablePath() else { return nil }
            return ("\(periodic) daily weekly monthly", true)
        default:
            return nil
        }
    }

    static func runPrivilegedCommandBatch(taskNames: [String]) -> (results: [String: Bool], canceled: Bool) {
        let privilegedTasks = taskNames.compactMap { name -> (name: String, command: String)? in
            guard let config = maintenanceCommand(for: name), config.requiresAdmin else { return nil }
            return (name, config.command)
        }
        guard !privilegedTasks.isEmpty else { return ([:], false) }

        let script = privilegedTasks.enumerated().map { idx, task in
            "if \(task.command) >/dev/null 2>&1; then echo __MACSWEEP_OK__\(idx); else echo __MACSWEEP_FAIL__\(idx); fi"
        }.joined(separator: "; ")

        let process = Process()
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        let escaped = script
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        process.arguments = ["-e", "do shell script \"\(escaped)\" with administrator privileges"]

        do {
            let sema = DispatchSemaphore(value: 0)
            process.terminationHandler = { _ in sema.signal() }
            try process.run()
            if sema.wait(timeout: .now() + 120.0) == .timedOut {
                process.terminate()
                return (Dictionary(uniqueKeysWithValues: privilegedTasks.map { ($0.name, false) }), true)
            }
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            var results = Dictionary(uniqueKeysWithValues: privilegedTasks.map { ($0.name, false) })

            for lineSub in output.split(whereSeparator: \.isNewline) {
                let line = String(lineSub)
                if line.hasPrefix("__MACSWEEP_OK__") {
                    let indexText = line.replacingOccurrences(of: "__MACSWEEP_OK__", with: "")
                    if let idx = Int(indexText), idx >= 0, idx < privilegedTasks.count {
                        results[privilegedTasks[idx].name] = true
                    }
                } else if line.hasPrefix("__MACSWEEP_FAIL__") {
                    let indexText = line.replacingOccurrences(of: "__MACSWEEP_FAIL__", with: "")
                    if let idx = Int(indexText), idx >= 0, idx < privilegedTasks.count {
                        results[privilegedTasks[idx].name] = false
                    }
                }
            }

            if process.terminationStatus != 0 {
                let lowered = output.lowercased()
                if lowered.contains("user canceled") || lowered.contains("cancel") {
                    return (results, true)
                }
            }
            return (results, false)
        } catch {
            return (Dictionary(uniqueKeysWithValues: privilegedTasks.map { ($0.name, false) }), true)
        }
    }

    static func runShellCommand(_ command: String) -> Bool {
        let process = Process()
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        let sema = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in sema.signal() }
        do { try process.run() } catch { return false }
        if sema.wait(timeout: .now() + 60.0) == .timedOut { process.terminate(); return false }
        return process.terminationStatus == 0
    }

    private static func runShellCommandWithOutput(_ command: String) -> (status: Int32, output: String) {
        let process = Process()
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        let sema = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in sema.signal() }
        do { try process.run() } catch { return (1, "") }
        if sema.wait(timeout: .now() + 60.0) == .timedOut { process.terminate(); return (1, "") }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return (process.terminationStatus, String(data: data, encoding: .utf8) ?? "")
    }
}
