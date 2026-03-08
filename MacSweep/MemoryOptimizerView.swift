import SwiftUI
import AppKit

// MARK: - Memory Optimizer View
struct MemoryOptimizerView: View {
    @ObservedObject var engine: MemoryEngine
    @State private var showKillConfirm = false
    @State private var processToKill: AppProcessInfo?
    
    @Binding var selectedTab: Int
    @EnvironmentObject var navManager: NavigationManager
    @State private var scanRotation: Double = 0
    @State private var gaugeHovered = false

    var body: some View {
        VStack(spacing: 0) {
            headerWithBackButton

            if !engine.hasScanned && !engine.isScanning {
                ToolLandingView(
                    section: .memoryOptimizer,
                    subtitle: "Analyze your Mac's RAM usage and\nforce quit memory-heavy apps.",
                    actionLabel: "Analyze Memory",
                    onAction: {
                        engine.scan()
                    }
                )
            } else if engine.isScanning {
                ToolScanningView(
                    section: .memoryOptimizer,
                    scanningTitle: "Analyzing Memory...",
                    currentPath: .constant("Gathering active processes and measuring pressure..."),
                    onStop: {
                        engine.cancelScan()
                        selectedTab = 0
                    }
                )
            } else {
                // Memory Overview
                memoryOverview
                
                Divider()
                
                // Process List
                processListView
                
                Divider()
                
                // Footer
                memoryFooter
            }
        }
        .background(DS.bg)
        .onAppear {
            if engine.hasScanned {
                engine.startMonitoring()
            }
        }
        .alert("Quit Process?", isPresented: $showKillConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Force Quit", role: .destructive) {
                if let p = processToKill {
                    engine.killProcess(pid: p.pid)
                }
            }
        } message: {
            Text("Force quitting \"\(processToKill?.name ?? "")\" may cause data loss. Are you sure?")
        }
    }

    var headerWithBackButton: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Button {
                        if engine.isScanning {
                            engine.cancelScan()
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

                Text("Memory Optimizer")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(DS.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider().background(DS.borderSubtle)
        }
    }
    
    // MARK: - Memory Overview
    var memoryOverview: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                // Circular gauge
                ZStack {
                    Circle()
                        .stroke(DS.borderSubtle, lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: engine.memoryPressure)
                        .stroke(
                            LinearGradient(colors: pressureGradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(Motion.slow, value: engine.memoryPressure)
                        .shadow(color: pressureGradient.first?.opacity(gaugeHovered ? 0.65 : 0.4) ?? .clear, radius: gaugeHovered ? 14 : 6)
                        .scaleEffect(gaugeHovered ? 1.07 : 1.0)
                        .animation(Motion.fast, value: gaugeHovered)

                    // Sweeping Scan Animation
                    if engine.isScanning || engine.isFreeingMemory {
                        Circle()
                            .trim(from: 0, to: 0.25)
                            .stroke(
                                AngularGradient(colors: [pressureGradient.first ?? .clear, .clear], center: .center),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(scanRotation))
                            .onAppear {
                                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                    scanRotation = 360
                                }
                            }
                    }

                    VStack(spacing: 0) {
                        Text("\(Int(engine.memoryPressure * 100))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(DS.textPrimary)
                        Text("used")
                            .font(MSFont.mono)
                            .foregroundColor(DS.textMuted)
                    }
                }
                .onHover { gaugeHovered = $0 }
                .overlay(alignment: .top) {
                    if gaugeHovered {
                        MemoryGaugeTooltip(engine: engine, gradient: pressureGradient)
                            .offset(y: -112)
                            .zIndex(999)
                            .allowsHitTesting(false)
                            .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .bottom)))
                            .animation(Motion.fast, value: gaugeHovered)
                    }
                }

                // Stats
                VStack(alignment: .leading, spacing: 6) {
                    memStat(label: "Used", value: engine.usedMemory, color: DS.danger)
                    memStat(label: "Wired", value: engine.wiredMemory, color: DS.warning)
                    memStat(label: "Compressed", value: engine.compressedMemory, color: Color(hex: "9B4DFF"))
                    memStat(label: "Free", value: engine.freeMemoryStr, color: DS.success)
                }

                Spacer()

                // Total RAM
                VStack(alignment: .trailing, spacing: 4) {
                    Text(engine.totalMemoryFormatted)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(DS.textPrimary)
                    Text("Total RAM")
                        .font(MSFont.caption)
                        .foregroundColor(DS.textMuted)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(DS.bgPanel)
    }
    
    var pressureGradient: [Color] {
        if engine.memoryPressure > 0.85 { return [DS.danger, Color(hex: "FF4B2B")] }
        if engine.memoryPressure > 0.65 { return [DS.warning, Color(hex: "FFD200")] }
        return [DS.success, DS.brandTeal]
    }

    func memStat(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(MSFont.caption)
                .foregroundColor(DS.textMuted)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(DS.textPrimary)
        }
    }
    
    // MARK: - Process List
    var processListView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Top Processes by Memory")
                    .font(MSFont.headline)
                    .foregroundColor(DS.textPrimary)
                Spacer()
                Text("\(engine.processes.count) processes")
                    .font(MSFont.caption)
                    .foregroundColor(DS.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DS.bgPanel)

            Rectangle().fill(DS.borderSubtle).frame(height: 1)

            // Column headers
            HStack(spacing: 0) {
                Text("Process")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("PID")
                    .frame(width: 55, alignment: .trailing)
                Text("Memory")
                    .frame(width: 75, alignment: .trailing)
                Text("")
                    .frame(width: 60)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(DS.textMuted)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(DS.bgPanel)

            Rectangle().fill(DS.borderSubtle).frame(height: 1)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(engine.processes) { proc in
                        ProcessRow(process: proc) {
                            processToKill = proc
                            showKillConfirm = true
                        }
                        Rectangle().fill(DS.borderSubtle).frame(height: 1).padding(.leading, 16)
                    }
                }
            }
            .background(DS.bg)
        }
    }
    
    // MARK: - Footer
    var memoryFooter: some View {
        HStack(spacing: 12) {
            Button {
                engine.refreshProcesses()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .font(MSFont.caption)
                .foregroundColor(DS.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(DS.bgElevated)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Auto-refreshes every 5s")
                .font(MSFont.caption)
                .foregroundColor(DS.textMuted)

            Button {
                engine.freeUpMemory()
            } label: {
                HStack(spacing: 6) {
                    if engine.isFreeingMemory {
                        ProgressView().scaleEffect(0.6).tint(.white)
                    } else {
                        Image(systemName: "memorychip")
                    }
                    Text(engine.isFreeingMemory ? "Freeing..." : "Free Memory")
                }
                .font(MSFont.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(LinearGradient(
                            colors: SectionTheme.theme(for: .memoryOptimizer).gradient,
                            startPoint: .leading, endPoint: .trailing
                        ))
                )
            }
            .buttonStyle(.plain)
            .disabled(engine.isFreeingMemory)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(DS.bgPanel)
    }
}

// MARK: - Process Row
struct ProcessRow: View {
    let process: AppProcessInfo
    let onKill: () -> Void
    @State private var hovered = false
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                if let icon = process.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "gearshape.2")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                }
                Text(process.name)
                    .font(.system(size: 12))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("\(process.pid)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 55, alignment: .trailing)
            
            Text(process.memoryFormatted)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(process.memoryMB > 500 ? DS.danger : DS.textPrimary)
                .frame(width: 75, alignment: .trailing)
            
            Group {
                if hovered {
                    Button(action: onKill) {
                        Text("Quit")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.red.cornerRadius(4))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 60)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(hovered ? DS.bgElevated : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
        .animation(Motion.fast, value: hovered)
    }
}

// MARK: - Memory Engine
@MainActor
class MemoryEngine: ObservableObject {
    @Published var processes: [AppProcessInfo] = []
    @Published var memoryPressure: CGFloat = 0
    @Published var usedMemory: String = "0 GB"
    @Published var wiredMemory: String = "0 GB"
    @Published var compressedMemory: String = "0 GB"
    @Published var freeMemoryStr: String = "0 GB"
    @Published var totalMemoryFormatted: String = "0 GB"
    
    @Published var isScanning = false
    @Published var hasScanned = false
    @Published var isFreeingMemory = false

    private var timer: Timer?
    private var scanTask: Task<Void, Never>?

    func scan() {
        scanTask?.cancel()
        stopMonitoring()
        isScanning = true
        hasScanned = false
        scanTask = Task {
            let procs = await Task.detached(priority: .userInitiated) {
                Self.getTopProcesses()
            }.value
            if Task.isCancelled { return }
            self.updateMemoryStats()
            self.processes = procs
            self.isScanning = false
            self.hasScanned = true
            self.scanTask = nil
            self.startMonitoring()
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        stopMonitoring()
        isScanning = false
        hasScanned = false
        processes = []
    }

    func startMonitoring() {
        timer?.invalidate()
        updateMemoryStats()
        refreshProcesses()
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryStats()
                self?.refreshProcesses()
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func updateMemoryStats() {
        let totalRAM = Foundation.ProcessInfo.processInfo.physicalMemory
        totalMemoryFormatted = ByteCountFormatter.string(fromByteCount: Int64(totalRAM), countStyle: .memory)
        
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let pageSize = vm_kernel_page_size
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return }
        
        let free = UInt64(stats.free_count) * UInt64(pageSize)
        let active = UInt64(stats.active_count) * UInt64(pageSize)
        let inactive = UInt64(stats.inactive_count) * UInt64(pageSize)
        let wired = UInt64(stats.wire_count) * UInt64(pageSize)
        let compressed = UInt64(stats.compressor_page_count) * UInt64(pageSize)
        let used = active + inactive + wired
        
        freeMemoryStr = ByteCountFormatter.string(fromByteCount: Int64(free), countStyle: .memory)
        usedMemory = ByteCountFormatter.string(fromByteCount: Int64(used), countStyle: .memory)
        wiredMemory = ByteCountFormatter.string(fromByteCount: Int64(wired), countStyle: .memory)
        compressedMemory = ByteCountFormatter.string(fromByteCount: Int64(compressed), countStyle: .memory)
        
        memoryPressure = CGFloat(used) / CGFloat(totalRAM)
    }
    
    @MainActor
    func refreshProcesses() {
        Task.detached(priority: .userInitiated) {
            let procs = Self.getTopProcesses()
            await MainActor.run { [weak self] in
                self?.processes = procs
            }
        }
    }
    
    nonisolated static func getTopProcesses() -> [AppProcessInfo] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-axo", "pid=,rss=,comm=", "-r"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        let sema = DispatchSemaphore(value: 0)
        task.terminationHandler = { _ in sema.signal() }
        do {
            try task.run()
        } catch { return [] }
        if sema.wait(timeout: .now() + 4.0) == .timedOut {
            task.terminate()
            return []
        }
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        var results: [AppProcessInfo] = []
        
        for line in output.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            // Parse: PID RSS COMMAND (space-separated, command can contain spaces)
            let parts = trimmed.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
            guard parts.count >= 3,
                  let pid = Int32(parts[0]),
                  let rssKB = Int64(parts[1]) else { continue }
            
            let fullPath = String(parts[2])
            let name = fullPath.components(separatedBy: "/").last ?? fullPath
            let memoryMB = Double(rssKB) / 1024.0
            guard memoryMB > 10 else { continue } // Only show processes > 10 MB
            
            let icon = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == pid })?.icon
            
            results.append(AppProcessInfo(
                pid: pid,
                name: name,
                memoryMB: memoryMB,
                icon: icon
            ))
        }
        
        return Array(results.prefix(30))
    }
    
    func killProcess(pid: Int32) {
        kill(pid, SIGTERM)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refreshProcesses()
        }
    }
    
    func freeUpMemory() {
        isFreeingMemory = true
        
        Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            let script = "do shell script \"/usr/sbin/purge\" with administrator privileges"
            process.arguments = ["-e", script]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            let sema = DispatchSemaphore(value: 0)
            process.terminationHandler = { _ in sema.signal() }
            do { 
                try process.run() 
                var slept = 0
                while process.isRunning && slept < 300 {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    slept += 1
                }
            } catch {}
            if process.isRunning { process.terminate() }

            await MainActor.run {
                self.isFreeingMemory = false
                self.updateMemoryStats()
            }
        }
    }
}

// MARK: - Memory Gauge Tooltip
private struct MemoryGaugeTooltip: View {
    let engine: MemoryEngine
    let gradient: [Color]

    private var accentColor: Color { gradient.first ?? DS.brandGreen }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Circle().fill(DS.danger).frame(width: 6, height: 6)
                Text("Used").font(MSFont.caption).foregroundColor(DS.textMuted)
                Spacer(minLength: 8)
                Text(engine.usedMemory).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundColor(DS.danger)
            }
            HStack(spacing: 8) {
                Circle().fill(DS.warning).frame(width: 6, height: 6)
                Text("Wired").font(MSFont.caption).foregroundColor(DS.textMuted)
                Spacer(minLength: 8)
                Text(engine.wiredMemory).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundColor(DS.warning)
            }
            HStack(spacing: 8) {
                Circle().fill(Color(hex: "9B4DFF")).frame(width: 6, height: 6)
                Text("Compressed").font(MSFont.caption).foregroundColor(DS.textMuted)
                Spacer(minLength: 8)
                Text(engine.compressedMemory).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: "9B4DFF"))
            }
            HStack(spacing: 8) {
                Circle().fill(DS.success).frame(width: 6, height: 6)
                Text("Free").font(MSFont.caption).foregroundColor(DS.textMuted)
                Spacer(minLength: 8)
                Text(engine.freeMemoryStr).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundColor(DS.success)
            }
            Rectangle().fill(DS.borderSubtle).frame(height: 1).padding(.vertical, 2)
            HStack(spacing: 8) {
                Circle().fill(accentColor).frame(width: 6, height: 6)
                Text("Pressure").font(MSFont.caption).foregroundColor(DS.textMuted)
                Spacer(minLength: 8)
                Text("\(Int(engine.memoryPressure * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(minWidth: 180)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(DS.bgElevated)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(DS.borderMid, lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
    }
}

// MARK: - Process Info Model
struct AppProcessInfo: Identifiable {
    var id: Int32 { pid }
    let pid: Int32
    let name: String
    let memoryMB: Double
    let icon: NSImage?
    
    var memoryFormatted: String {
        if memoryMB >= 1024 {
            return String(format: "%.1f GB", memoryMB / 1024)
        }
        return String(format: "%.0f MB", memoryMB)
    }
}
