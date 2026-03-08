import SwiftUI
import AppKit

struct LargeFilesView: View {
    @ObservedObject var scanEngine:  ScanEngine
    @ObservedObject var cleanEngine: CleanEngine
    @AppStorage("largeFileThresholdMB") private var largeFileThresholdMB: Double = 100
    @State private var showConfirm = false
    @State private var showResult  = false
    @State private var showReview  = false
    @State private var scanTarget  = NSHomeDirectory()
    @EnvironmentObject var navManager: NavigationManager

    private let theme = SectionTheme.theme(for: .largeFiles)

    var largeFiles: [ScanItem] {
        scanEngine.scanItems
            .filter { $0.category == .largeFiles }
            .sorted { $0.size > $1.size }
    }

    var selectedLargeSize: Int64 {
        largeFiles.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }

    var body: some View {
        VStack(spacing: 0) {
            let showLanding = !scanEngine.isScanning && (!scanEngine.scanComplete || largeFiles.isEmpty)
            if showLanding {
                VStack(spacing: 0) {
                    navHeader(isLanding: true)
                    ToolLandingView(
                        section: .largeFiles,
                        subtitle: "Locate and remove massive files that are\ncluttering your storage.",
                        actionLabel: "Scan",
                        extraContent: AnyView(folderPicker),
                        onAction: {
                            Task { await scanEngine.startScan(mode: .custom(path: scanTarget, categories: [.largeFiles])) }
                        }
                    )
                }
            } else if scanEngine.isScanning {
                ToolScanningView(
                    section: .largeFiles,
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
        .alert("Delete Selected Files?", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await cleanEngine.clean(items: largeFiles)
                    if cleanEngine.cleanedSize > 0 {
                        scanEngine.recordFreed(bytes: cleanEngine.cleanedSize, description: "Large Files cleanup")
                    }
                    DS.playCleanComplete()
                    await scanEngine.startScan(mode: .custom(path: scanTarget, categories: [.largeFiles]))
                    showResult = true
                }
            }
        } message: {
            Text("This will permanently delete \(ByteCountFormatter.string(fromByteCount: selectedLargeSize, countStyle: .file)).")
        }
        .sheet(isPresented: $showResult) {
            CleanResultSheet(cleanEngine: cleanEngine, scanEngine: scanEngine, isPresented: $showResult)
        }
        .sheet(isPresented: $showReview) {
            ReviewManagerSheet(scanEngine: scanEngine, cleanEngine: cleanEngine, scope: .largeFiles)
        }
    }

    // MARK: - Folder Picker
    private var folderPicker: some View {
        Menu {
            Button { scanTarget = NSHomeDirectory() } label: {
                Label("Home Folder", systemImage: "house.fill")
            }
            Button { scanTarget = "/" } label: {
                Label("Macintosh HD", systemImage: "internaldrive.fill")
            }
            Divider()
            Button { selectCustomFolder() } label: {
                Label("Choose Folder…", systemImage: "folder.badge.plus")
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: scanTarget == "/" ? "internaldrive.fill" : "folder.fill")
                    .foregroundColor(theme.glow)
                Text(scanTargetName)
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
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Large Files")
                    .font(MSFont.title2)
                    .foregroundColor(DS.textPrimary)
                
                Spacer()
                
                if !largeFiles.isEmpty {
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
            // Header bar removed here as it's now in navHeader
            HStack(spacing: 12) {
                Spacer()
                Button {
                    Task { await scanEngine.startScan(mode: .custom(path: scanTarget, categories: [.largeFiles])) }
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

            if !largeFiles.isEmpty {
                // Summary + actions bar
                HStack(spacing: 14) {
                    SummaryPill(
                        icon: "arrow.up.doc.fill",
                        label: "Large Files",
                        value: "\(largeFiles.count) files",
                        color: theme.glow
                    )
                    SummaryPill(
                        icon: "checkmark.circle.fill",
                        label: "Selected",
                        value: "\(largeFiles.filter(\.isSelected).count) · \(ByteCountFormatter.string(fromByteCount: selectedLargeSize, countStyle: .file))",
                        color: DS.success
                    )
                    Spacer()
                    HStack(spacing: 8) {
                        Button("All") {
                            for item in largeFiles where !item.isSelected { scanEngine.toggleItem(item.id) }
                        }
                        .font(MSFont.caption)
                        .foregroundColor(DS.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(DS.bgElevated)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)

                        Button("None") {
                            for item in largeFiles where item.isSelected { scanEngine.toggleItem(item.id) }
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
                        title: "Delete Selected",
                        icon: "trash.fill",
                        gradient: [DS.danger, DS.danger],
                        disabled: selectedLargeSize == 0
                    ) {
                        showConfirm = true
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(DS.bgPanel)
                .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1), alignment: .bottom)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 6) {
                        ForEach(largeFiles) { item in
                            LargeFileRow(item: item, scanEngine: scanEngine)
                        }
                    }
                    .padding(20)
                }
                .background(DS.bg)
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(DS.success.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(DS.success)
                    }
                    Text("No Large Files Found")
                        .font(MSFont.title2)
                        .foregroundColor(DS.textPrimary)
                    Text("Your selected folder is clear of large files.")
                        .font(MSFont.body)
                        .foregroundColor(DS.textSecondary)
                    Button("Scan Another Folder") {
                        scanEngine.scanComplete = false
                    }
                    .font(MSFont.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(theme.linearGradient)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(DS.bg)
            }
        }
    }

    private var scanTargetName: String {
        if scanTarget == "/" { return "Macintosh HD" }
        return (scanTarget as NSString).lastPathComponent
    }

    private func selectCustomFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK, let url = panel.url {
            scanTarget = url.path
        }
    }
}

// MARK: - Large File Row

struct LargeFileRow: View {
    let item: ScanItem
    @ObservedObject var scanEngine: ScanEngine
    @State private var isHovered = false

    var fileIcon: String {
        let ext = (item.name as NSString).pathExtension.lowercased()
        switch ext {
        case "mp4", "mov", "avi", "mkv": return "film.fill"
        case "dmg", "iso", "zip", "gz", "tar": return "doc.zipper"
        case "app": return "app.fill"
        case "mp3", "wav", "m4a", "aac": return "music.note"
        case "jpg", "png", "heic", "tiff": return "photo.fill"
        case "pdf": return "doc.text.fill"
        default: return "doc.fill"
        }
    }

    var fileColor: Color {
        let ext = (item.name as NSString).pathExtension.lowercased()
        switch ext {
        case "mp4", "mov", "avi", "mkv": return Color(hex: "9B4DFF")
        case "dmg", "iso", "zip", "gz", "tar": return DS.warning
        case "app": return Color(hex: "3A70E0")
        case "mp3", "wav", "m4a", "aac": return DS.brandGreen
        case "jpg", "png", "heic", "tiff": return Color(hex: "D459A0")
        case "pdf": return DS.danger
        default: return DS.textMuted
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { _ in scanEngine.toggleItem(item.id) }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(fileColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: fileIcon)
                    .font(.system(size: 18))
                    .foregroundColor(fileColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(MSFont.headline)
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
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(SectionTheme.theme(for: .largeFiles).glow)

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            } label: {
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(DS.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? DS.bgElevated : DS.bgPanel)
                .animation(Motion.fast, value: isHovered)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(DS.borderSubtle, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(Motion.fast) { isHovered = hovering }
        }
    }
}
