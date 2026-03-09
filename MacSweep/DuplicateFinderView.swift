import SwiftUI
import AppKit
import CryptoKit

// MARK: - Duplicate Finder View
struct DuplicateFinderView: View {
    @ObservedObject var engine: DuplicateEngine
    @State private var selectedGroupId: String?
    @State private var showConfirm = false
    @EnvironmentObject var navManager: NavigationManager

    private var theme: SectionTheme { SectionTheme.theme(for: .duplicates) }

    var body: some View {
        VStack(spacing: 0) {
            if !engine.isScanning && !engine.hasScanned {
                VStack(spacing: 0) {
                    navHeader
                    landingScreen
                }
            } else if engine.isScanning {
                ToolScanningView(
                    section: .duplicates,
                    scanningTitle: "Scanning for Duplicates...",
                    currentPath: $engine.currentScanPath,
                    onStop: { engine.cancelScan() }
                )
            } else {
                dupHeader
                Divider()
                HStack(spacing: 0) {
                    dupGroupList
                    Divider()
                    if let gid = selectedGroupId,
                       let group = engine.groups.first(where: { $0.id == gid }) {
                        dupItemList(group: group)
                    } else {
                        emptyState
                    }
                }
                Divider()
                dupFooter
            }
        }
        .background(DS.bg)
        .alert("Remove Duplicates?", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Move to Trash", role: .destructive) {
                engine.removeSelected()
            }
        } message: {
            Text("This will move \(engine.selectedCount) duplicate file(s) to the Trash. You can restore them from Trash if needed.")
        }
    }

    // MARK: - Nav Header (landing)
    private var navHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Button { navManager.goBack() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(navManager.canGoBack ? DS.textSecondary : DS.textMuted.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .background(navManager.canGoBack ? DS.bgElevated : DS.bgElevated.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!navManager.canGoBack)

                Button { navManager.goForward() } label: {
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

    // MARK: - Landing
    private var landingScreen: some View {
        ToolLandingView(
            section: .duplicates,
            subtitle: "Find and remove duplicate files to\nreclaim valuable disk space.",
            actionLabel: "Find Duplicates",
            extraContent: AnyView(dupFolderPicker),
            onAction: {
                engine.hasScanned = true
                engine.scanAll()
            }
        )
    }

    private var dupFolderPicker: some View {
        Menu {
            Button { engine.selectedDirectory = FileManager.default.homeDirectoryForCurrentUser } label: { Label("Home Folder", systemImage: "house.fill") }
            Button { engine.selectedDirectory = URL(fileURLWithPath: "/") } label: { Label("Macintosh HD", systemImage: "internaldrive.fill") }
            Divider()
            Button { engine.selectDirectory() } label: { Label("Choose Folder…", systemImage: "folder.badge.plus") }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: engine.selectedDirectory?.path == "/" ? "internaldrive.fill" : "folder.fill")
                    .foregroundColor(theme.glow)
                Text(engine.selectedDirectory?.lastPathComponent ?? FileManager.default.homeDirectoryForCurrentUser.lastPathComponent)
                    .font(MSFont.body)
                    .foregroundColor(DS.textPrimary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(DS.textMuted)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(width: 260)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DS.bgElevated)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(DS.borderMid, lineWidth: 1))
            )
        }
        .menuStyle(.borderlessButton)
    }

    // MARK: - Header (results)
    var dupHeader: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Button {
                    if engine.hasScanned && !engine.isScanning {
                        engine.hasScanned = false
                    } else {
                        navManager.goBack()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor((!engine.hasScanned && !navManager.canGoBack) ? DS.textMuted.opacity(0.5) : DS.textSecondary)
                        .frame(width: 32, height: 32)
                        .background((!engine.hasScanned && !navManager.canGoBack) ? DS.bgElevated.opacity(0.5) : DS.bgElevated)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!engine.hasScanned && !navManager.canGoBack)

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

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.linearGradient)
                    .frame(width: 44, height: 44)
                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Duplicate Finder")
                    .font(MSFont.title2)
                    .foregroundColor(DS.textPrimary)
                Text("Find identical files across your folders")
                    .font(MSFont.caption)
                    .foregroundColor(DS.textMuted)
            }
            Spacer()
            if !engine.isScanning {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(engine.groups.count) groups")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(theme.glow)
                    Text(ByteCountFormatter.string(fromByteCount: engine.totalWastedSize, countStyle: .file) + " wasted")
                        .font(MSFont.caption)
                        .foregroundColor(DS.textMuted)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Group List
    var dupGroupList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 4) {
                ForEach(engine.groups) { group in
                    DupGroupRow(
                        group: group,
                        isSelected: selectedGroupId == group.id,
                        onTap: { selectedGroupId = group.id }
                    )
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
        }
        .frame(width: 220)
        .background(DS.bgElevated.opacity(0.5))
    }

    // MARK: - Item List
    func dupItemList(group: DuplicateGroup) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: group.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.glow)
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.fileName)
                        .font(MSFont.headline)
                        .foregroundColor(DS.textPrimary)
                    Text("\(group.files.count) copies · \(group.sizeFormatted) each")
                        .font(MSFont.caption)
                        .foregroundColor(DS.textMuted)
                }
                Spacer()
                Button {
                    engine.autoSelectDuplicates(groupId: group.id)
                } label: {
                    Text("Keep First")
                        .font(MSFont.caption)
                        .foregroundColor(theme.glow)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(DS.bgElevated)

            Divider()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(group.files.enumerated()), id: \.element.id) { idx, file in
                        DupFileRow(
                            file: file,
                            index: idx,
                            onToggle: { engine.toggleFile(groupId: group.id, fileId: file.id) }
                        )
                        Divider().padding(.leading, 56)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 40))
                .foregroundColor(DS.textMuted.opacity(0.3))
            Text("Select a duplicate group")
                .font(MSFont.body)
                .foregroundColor(DS.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer
    var dupFooter: some View {
        HStack(spacing: 12) {
            Button {
                engine.scanAll()
            } label: {
                Label("Rescan", systemImage: "arrow.clockwise")
                    .font(MSFont.caption)
                    .foregroundColor(DS.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DS.bgElevated)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Button {
                engine.autoSelectAllDuplicates()
            } label: {
                Label("Keep All First", systemImage: "wand.and.stars")
                    .font(MSFont.caption)
                    .foregroundColor(theme.glow)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.glow.opacity(0.1))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Button {
                for gi in engine.groups.indices {
                    for fi in engine.groups[gi].files.indices {
                        engine.groups[gi].files[fi].isSelected = false
                    }
                }
            } label: {
                Label("Deselect All", systemImage: "xmark.circle")
                    .font(MSFont.caption)
                    .foregroundColor(DS.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DS.bgElevated)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Spacer()

            if !engine.isScanning {
                Text("\(engine.selectedCount) files selected · \(ByteCountFormatter.string(fromByteCount: engine.selectedSize, countStyle: .file))")
                    .font(MSFont.caption)
                    .foregroundColor(DS.textMuted)
            }

            Button {
                showConfirm = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                    Text("Remove Duplicates")
                }
                .font(MSFont.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(engine.selectedCount == 0
                              ? AnyShapeStyle(Color.gray)
                              : AnyShapeStyle(theme.linearGradient))
                )
            }
            .buttonStyle(.plain)
            .disabled(engine.selectedCount == 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Duplicate Group Row
struct DupGroupRow: View {
    let group: DuplicateGroup
    let isSelected: Bool
    let onTap: () -> Void
    @State private var hovered = false
    private var theme: SectionTheme { SectionTheme.theme(for: .duplicates) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected
                              ? AnyShapeStyle(theme.linearGradient)
                              : AnyShapeStyle(Color.clear))
                        .frame(width: 28, height: 28)
                    Image(systemName: group.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isSelected ? .white : DS.textMuted)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(group.fileName)
                        .font(MSFont.body)
                        .foregroundColor(isSelected ? DS.textPrimary : DS.textSecondary)
                        .lineLimit(1)
                    Text("\(group.files.count) copies · \(group.sizeFormatted)")
                        .font(MSFont.mono)
                        .foregroundColor(DS.textMuted)
                }
                Spacer()
                Text("\(group.files.count)")
                    .font(MSFont.mono)
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(theme.glow.cornerRadius(4))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? theme.glow.opacity(0.08) : (hovered ? DS.bgElevated.opacity(0.5) : Color.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(Motion.fast, value: hovered)
    }
}

// MARK: - Duplicate File Row
struct DupFileRow: View {
    let file: DuplicateFile
    let index: Int
    let onToggle: () -> Void
    @State private var hovered = false
    private var theme: SectionTheme { SectionTheme.theme(for: .duplicates) }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: file.isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundColor(file.isSelected ? theme.glow : DS.textMuted)
            }
            .buttonStyle(.plain)

            if index == 0 {
                Text("ORIGINAL")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(DS.brandGreen.opacity(0.9).cornerRadius(3))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(MSFont.body)
                    .foregroundColor(DS.textPrimary)
                    .lineLimit(1)
                Text(file.path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~"))
                    .font(MSFont.mono)
                    .foregroundColor(DS.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            Text(file.sizeFormatted)
                .font(MSFont.caption)
                .foregroundColor(DS.textSecondary)

            if hovered {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: file.path)])
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 11))
                        Text("Reveal")
                            .font(MSFont.caption)
                    }
                    .foregroundColor(theme.glow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 5).fill(theme.glow.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(hovered ? DS.bgElevated : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
        .animation(Motion.fast, value: hovered)
    }
}

// MARK: - Duplicate Engine
@MainActor
class DuplicateEngine: ObservableObject {
    @Published var groups: [DuplicateGroup] = []
    @Published var isScanning = false
    @Published var hasScanned = false
    @Published var selectedDirectory: URL? = nil
    @Published var currentScanPath: String = ""
    private var scanTask: Task<Void, Never>?
    private var scanSession = UUID()

    var totalWastedSize: Int64 {
        groups.reduce(0) { total, group in
            // Wasted = (count - 1) * size (since one copy is original)
            total + Int64(max(group.files.count - 1, 0)) * group.fileSize
        }
    }
    var selectedCount: Int { groups.flatMap(\.files).filter(\.isSelected).count }
    var selectedSize: Int64 { groups.flatMap(\.files).filter(\.isSelected).reduce(0) { $0 + $1.size } }

    func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Select Folder to Scan for Duplicates"
        panel.prompt = "Select"
        
        if panel.runModal() == .OK {
            self.selectedDirectory = panel.url
            self.hasScanned = false
            self.groups = []
        }
    }

    func scanAll() {
        scanTask?.cancel()
        let session = UUID()
        scanSession = session

        isScanning = true
        hasScanned = true
        groups = []
        currentScanPath = "Preparing scan..."

        let targetURL = selectedDirectory
        scanTask = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            let found = self.findDuplicates(in: targetURL) { status in
                Task { @MainActor [weak self] in
                    guard let self, self.scanSession == session, self.isScanning else { return }
                    self.currentScanPath = status
                }
            }

            if Task.isCancelled { return }

            await MainActor.run {
                guard self.scanSession == session else { return }
                self.groups = found
                self.currentScanPath = "Scan complete."
                self.isScanning = false
                self.scanTask = nil
                NotificationManager.shared.playSound("Glass")
            }
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        scanSession = UUID()
        isScanning = false
        hasScanned = false
        currentScanPath = "Scan cancelled."
    }

    nonisolated private struct DuplicateScanOptions {
        let minFileSizeBytes: Int64
        let skipHidden: Bool
    }

    nonisolated private static let quickFingerprintChunkSize = 64 * 1024
    nonisolated private static let fullHashChunkSize = 1024 * 1024
    nonisolated private static let excludedSystemRoots: [String] = [
        "/System",
        "/private/var/vm",
        "/private/var/folders",
        "/private/var/run",
        "/private/var/db",
        "/Volumes",
        "/dev",
        "/cores",
        "/net",
        "/home"
    ]

    nonisolated private static func loadScanOptions() -> DuplicateScanOptions {
        let ud = UserDefaults.standard
        let minSizeMB = (ud.object(forKey: "duplicateMinSizeMB") as? Double) ?? 1.0
        let minFileSizeBytes = max(Int64(minSizeMB * 1024 * 1024), 4 * 1024)
        let skipHidden = (ud.object(forKey: "duplicateSkipHiddenFiles") as? Bool) ?? true
        return DuplicateScanOptions(minFileSizeBytes: minFileSizeBytes, skipHidden: skipHidden)
    }

    nonisolated private static func isExcludedSystemPath(_ path: String) -> Bool {
        excludedSystemRoots.contains { root in
            path == root || path.hasPrefix(root + "/")
        }
    }

    nonisolated private static func iconForFileName(_ fileName: String) -> String {
        switch (fileName as NSString).pathExtension.lowercased() {
        case "jpg", "jpeg", "png", "gif", "heic", "webp", "tiff":
            return "photo"
        case "mp4", "mov", "avi", "mkv":
            return "film"
        case "mp3", "aac", "wav", "flac", "m4a":
            return "music.note"
        case "pdf":
            return "doc.richtext"
        case "zip", "rar", "7z", "dmg":
            return "archivebox"
        case "doc", "docx", "txt", "rtf", "pages":
            return "doc.text"
        case "xls", "xlsx", "csv", "numbers":
            return "tablecells"
        default:
            return "doc"
        }
    }

    nonisolated func findDuplicates(in target: URL?, onProgress: (@Sendable (String) -> Void)? = nil) -> [DuplicateGroup] {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser.path
        let options = Self.loadScanOptions()

        let dirs: [String]
        if let targetURL = target {
            dirs = [targetURL.path]
        } else {
            dirs = [
                "\(home)/Documents",
                "\(home)/Downloads",
                "\(home)/Desktop",
                "\(home)/Pictures",
                "\(home)/Movies",
                "\(home)/Music"
            ]
        }

        // Keep only duplicate-size candidates to cap memory growth on large scans.
        var firstPathBySize: [Int64: String] = [:]
        var candidatePathsBySize: [Int64: [String]] = [:]
        var scannedCount = 0
        var lastProgressAt = Date.distantPast

        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey]
        let enumOptions: FileManager.DirectoryEnumerationOptions = options.skipHidden
            ? [.skipsPackageDescendants, .skipsHiddenFiles]
            : [.skipsPackageDescendants]

        for dir in dirs {
            if Task.isCancelled { return [] }
            let rootURL = URL(fileURLWithPath: dir, isDirectory: true)
            guard let enumerator = fm.enumerator(
                at: rootURL,
                includingPropertiesForKeys: Array(resourceKeys),
                options: enumOptions,
                errorHandler: { _, _ in true }
            ) else { continue }

            while let url = enumerator.nextObject() as? URL {
                if Task.isCancelled { return [] }

                let fullPath = url.path
                if dir == "/" && Self.isExcludedSystemPath(fullPath) {
                    enumerator.skipDescendants()
                    continue
                }

                guard let values = try? url.resourceValues(forKeys: resourceKeys),
                      values.isRegularFile == true,
                      let fileSize = values.fileSize else { continue }

                let size = Int64(fileSize)
                guard size >= options.minFileSizeBytes else { continue }

                scannedCount += 1
                let now = Date()
                if now.timeIntervalSince(lastProgressAt) >= 0.12 {
                    lastProgressAt = now
                    let name = url.lastPathComponent.isEmpty ? fullPath : url.lastPathComponent
                    onProgress?("Scanning \(scannedCount) files... \(name)")
                }

                if candidatePathsBySize[size] != nil {
                    candidatePathsBySize[size, default: []].append(fullPath)
                } else if let first = firstPathBySize[size] {
                    candidatePathsBySize[size] = [first, fullPath]
                    firstPathBySize.removeValue(forKey: size)
                } else {
                    firstPathBySize[size] = fullPath
                }
            }
        }

        // Phase 2: quick fingerprint pass to avoid full hashing on likely-unique content.
        var quickGroups: [String: [String]] = [:]
        for (size, paths) in candidatePathsBySize where paths.count >= 2 {
            if Task.isCancelled { return [] }
            for path in paths {
                if Task.isCancelled { return [] }
                if let quick = Self.quickFingerprint(of: path, fileSize: size) {
                    quickGroups[quick, default: []].append(path)
                }
            }
        }

        // Phase 3: for fingerprint collisions, run full-file hash.
        var hashGroups: [String: [String]] = [:]
        for (_, paths) in quickGroups where paths.count >= 2 {
            if Task.isCancelled { return [] }
            for path in paths {
                if Task.isCancelled { return [] }
                if let fullHash = Self.md5Hash(of: path) {
                    hashGroups[fullHash, default: []].append(path)
                }
            }
        }

        // Phase 4: Build duplicate groups.
        var results: [DuplicateGroup] = []
        for (hash, paths) in hashGroups where paths.count >= 2 {
            if Task.isCancelled { return [] }
            let sortedPaths = paths.sorted()
            guard let firstPath = sortedPaths.first else { continue }
            let fileName = (firstPath as NSString).lastPathComponent
            let fileSize = (try? fm.attributesOfItem(atPath: firstPath)[.size] as? Int64) ?? 0

            let files = sortedPaths.map { path in
                DuplicateFile(
                    name: (path as NSString).lastPathComponent,
                    path: path,
                    size: fileSize,
                    isSelected: false // Don't auto-select any
                )
            }

            results.append(DuplicateGroup(
                hash: hash,
                fileName: fileName,
                fileSize: fileSize,
                files: files,
                icon: Self.iconForFileName(fileName)
            ))
        }

        return results.sorted { $0.fileSize * Int64($0.files.count) > $1.fileSize * Int64($1.files.count) }
    }

    nonisolated static func quickFingerprint(of path: String, fileSize: Int64) -> String? {
        guard let file = FileHandle(forReadingAtPath: path) else { return nil }
        defer { try? file.close() }

        let chunkSize = quickFingerprintChunkSize
        let firstSize = min(chunkSize, Int(fileSize))
        guard firstSize > 0 else { return nil }

        var hasher = Insecure.MD5()
        do {
            try file.seek(toOffset: 0)
            if let first = try file.read(upToCount: firstSize), !first.isEmpty {
                hasher.update(data: first)
            } else {
                return nil
            }

            if fileSize > Int64(chunkSize * 3) {
                let middleOffset = UInt64(max((fileSize / 2) - Int64(chunkSize / 2), 0))
                try file.seek(toOffset: middleOffset)
                if let middle = try file.read(upToCount: chunkSize), !middle.isEmpty {
                    hasher.update(data: middle)
                }
            }

            if fileSize > Int64(chunkSize) {
                let tailOffset = UInt64(max(fileSize - Int64(chunkSize), 0))
                try file.seek(toOffset: tailOffset)
                if let tail = try file.read(upToCount: chunkSize), !tail.isEmpty {
                    hasher.update(data: tail)
                }
            }
        } catch {
            return nil
        }

        let digest = hasher.finalize().map { String(format: "%02x", $0) }.joined()
        return "\(fileSize)-\(digest)"
    }

    nonisolated static func md5Hash(of path: String) -> String? {
        guard let file = FileHandle(forReadingAtPath: path) else { return nil }
        defer { try? file.close() }
        
        var hasher = Insecure.MD5()
        let bufferSize = fullHashChunkSize // 1MB chunk size
        
        while true {
            if Task.isCancelled { return nil }
            do {
                guard let data = try file.read(upToCount: bufferSize) else { break }
                if data.isEmpty { break }
                hasher.update(data: data)
            } catch {
                return nil
            }
        }
        
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func toggleFile(groupId: String, fileId: UUID) {
        guard let gi = groups.firstIndex(where: { $0.id == groupId }),
              let fi = groups[gi].files.firstIndex(where: { $0.id == fileId }) else { return }
        groups[gi].files[fi].isSelected.toggle()
    }

    func autoSelectDuplicates(groupId: String) {
        guard let gi = groups.firstIndex(where: { $0.id == groupId }) else { return }
        // Keep first file, select all others for removal
        for fi in groups[gi].files.indices {
            groups[gi].files[fi].isSelected = fi > 0
        }
    }

    func autoSelectAllDuplicates() {
        for gi in groups.indices {
            for fi in groups[gi].files.indices {
                groups[gi].files[fi].isSelected = fi > 0
            }
        }
    }

    func removeSelected() {
        let fm = FileManager.default
        for gi in groups.indices {
            groups[gi].files.removeAll { file in
                guard file.isSelected else { return false }
                do {
                    try fm.trashItem(at: URL(fileURLWithPath: file.path), resultingItemURL: nil)
                    return true
                } catch {
                    return false
                }
            }
        }
        // Remove groups that now have 1 or fewer files
        groups.removeAll { $0.files.count <= 1 }
    }
}

// MARK: - Data Models
struct DuplicateGroup: Identifiable {
    var id: String { hash }
    let hash: String
    let fileName: String
    let fileSize: Int64
    var files: [DuplicateFile]
    let icon: String

    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

struct DuplicateFile: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    var isSelected: Bool

    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
