import SwiftUI
import AppKit

// MARK: =========  SPACE LENS VIEW (PRO)  =========
struct SpaceLensView: View {
    @ObservedObject var scanEngine: ScanEngine
    @ObservedObject var engine: SpaceLensEngine
    @State private var showReviewSheet = false
    @EnvironmentObject var navManager: NavigationManager

    var body: some View {
        VStack(spacing: 0) {
            if engine.currentPath.isEmpty && !engine.isScanning {
                VStack(spacing: 0) {
                    navHeader(isLanding: true)
                    landingScreen
                }
            } else if engine.isScanning {
                ToolScanningView(
                    section: .spaceLens,
                    scanningTitle: "Scanning Space...",
                    currentPath: $engine.scanStatus,
                    onStop: { engine.cancelScan() }
                )
            } else {
                VStack(spacing: 0) {
                    navHeader(isLanding: false)
                    topBar
                    Divider().opacity(0.3)
                    mainContent
                    Divider().opacity(0.3)
                    footerBar
                }
            }
        }
        .background(DS.bg)
    }

    // MARK: - Landing
    @State private var scanTarget = NSHomeDirectory()

    private var landingScreen: some View {
        ToolLandingView(
            section: .spaceLens,
            subtitle: "Visualize what's taking up the most disk space\nand clean up your storage quickly.",
            actionLabel: "Scan",
            extraContent: AnyView(spaceLensFolderPicker),
            onAction: { engine.navigateTo(path: scanTarget) }
        )
    }

    private var spaceLensFolderPicker: some View {
        Menu {
            Button { scanTarget = "/" } label: {
                Label("Macintosh HD (Entire Disk)", systemImage: "internaldrive.fill")
            }
            Button { scanTarget = NSHomeDirectory() } label: {
                Label("Home Folder", systemImage: "house.fill")
            }
            Divider()
            Button { selectCustomFolder() } label: {
                Label("Choose Folder…", systemImage: "folder.badge.plus")
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: scanTarget == "/" ? "internaldrive.fill" : "folder.fill")
                    .foregroundColor(SectionTheme.theme(for: .spaceLens).glow)
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

    private var scanTargetName: String {
        if scanTarget == "/" { return "Macintosh HD" }
        return (scanTarget as NSString).lastPathComponent
    }

    private func selectCustomFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        panel.message = "Choose a folder to analyze"
        if panel.runModal() == .OK, let url = panel.url {
            scanTarget = url.path
        }
    }

    // MARK: - Navigation Header
    func navHeader(isLanding: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Button {
                        if !isLanding {
                            engine.goBack()
                        } else {
                            navManager.goBack()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor((isLanding && !navManager.canGoBack) ? DS.textMuted.opacity(0.3) : DS.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(DS.bgElevated.opacity(0.6))
                            .overlay(Circle().strokeBorder(DS.borderSubtle, lineWidth: 1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isLanding && !navManager.canGoBack)

                    Button {
                        if !isLanding {
                            engine.goForward()
                        } else {
                            navManager.goForward()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor((isLanding ? !navManager.canGoForward : !engine.canGoForward) ? DS.textMuted.opacity(0.3) : DS.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(DS.bgElevated.opacity(0.6))
                            .overlay(Circle().strokeBorder(DS.borderSubtle, lineWidth: 1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isLanding ? !navManager.canGoForward : !engine.canGoForward)
                }
                
                if !isLanding {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(SectionTheme.theme(for: .spaceLens).linearGradient)
                                .frame(width: 36, height: 36)
                            Image(systemName: AppSection.spaceLens.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Text("Space Lens")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(DS.textPrimary)
                    }
                } else {
                    Text("Space Lens")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(DS.textPrimary)
                }
                
                Spacer()
                
                if !isLanding {
                    Button {
                        engine.startOver()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Start Over")
                        }
                        .font(MSFont.caption)
                        .foregroundColor(DS.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DS.bgElevated)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            
            Divider().background(DS.borderSubtle.opacity(0.5))
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        VStack(spacing: 0) {
            // Large nav buttons removed from here as they're now in navHeader
            
            // Breadcrumb
            HStack(spacing: 6) {
                // Small nav buttons removed from breadcrumb as we have large ones now
                
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(Array(engine.breadcrumbs.enumerated()), id: \.element.id) { idx, crumb in
                                if idx > 0 {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(.secondary.opacity(0.35))
                                }
                                Button { engine.navigateTo(path: crumb.path) } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: crumb.icon)
                                            .font(.system(size: 10))
                                            .foregroundColor(crumb.isActive ? SectionTheme.theme(for: .spaceLens).glow : DS.textMuted)
                                        Text(crumb.name)
                                            .font(.system(size: 12, weight: crumb.isActive ? .bold : .medium))
                                            .foregroundColor(crumb.isActive ? DS.textPrimary : DS.textSecondary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(crumb.isActive ? SectionTheme.theme(for: .spaceLens).glow.opacity(0.12) : Color.clear)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                                .id(crumb.id)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .onChange(of: engine.currentPath) { _, _ in
                        if let last = engine.breadcrumbs.last {
                            withAnimation { proxy.scrollTo(last.id) }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(DS.bgPanel)
        }
    }

    private func navButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(enabled ? .primary : .gray.opacity(0.25))
                .frame(width: 26, height: 26)
                .background(DS.bgElevated.opacity(enabled ? 1 : 0.4))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: - Main Content
    private var mainContent: some View {
        Group {
            if engine.isScanning {
                VStack(spacing: 20) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(SectionTheme.theme(for: .spaceLens).glow)
                    Text("Scanning \(engine.currentDirName)…")
                        .font(MSFont.headline)
                        .foregroundColor(DS.textPrimary)
                    Text(engine.scanStatus)
                        .font(MSFont.caption)
                        .foregroundColor(DS.textMuted)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DS.bg)
            } else {
                HStack(spacing: 0) {
                    fileListPanel.frame(width: 320)
                    Divider().opacity(0.3)
                    bubbleCanvas
                }
            }
        }
    }

    // MARK: - File List
    private var fileListPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [SectionTheme.theme(for: .spaceLens).glow.opacity(0.25), SectionTheme.theme(for: .spaceLens).glow.opacity(0.12)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: engine.currentPath == "/" ? "internaldrive.fill" : "folder.fill")
                        .font(.system(size: 18))
                        .foregroundColor(SectionTheme.theme(for: .spaceLens).glow)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(engine.currentDirName)
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(ByteCountFormatter.string(fromByteCount: engine.currentDirSize, countStyle: .file))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                        Text("|")
                            .font(.system(size: 10))
                            .foregroundColor(.gray.opacity(0.4))
                        Text("\(engine.totalItemCount) items")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            // Select bar
            HStack(spacing: 6) {
                Text("Select:")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Menu {
                    Button("All") { engine.selectAll() }
                    Button("None") { engine.deselectAll() }
                    Button("Files Only") { engine.selectFilesOnly() }
                    Button("Folders Only") { engine.selectFoldersOnly() }
                    Divider()
                    Button("Large Items (> 100 MB)") { engine.selectLargeItems() }
                } label: {
                    HStack(spacing: 3) {
                        Text(engine.selectionLabel)
                            .font(.system(size: 11, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 7, weight: .bold))
                    }
                    .foregroundColor(SectionTheme.theme(for: .spaceLens).glow)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            Divider().opacity(0.3)

            // File rows
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(engine.entries) { entry in
                        SLFileRow(
                            entry: entry,
                            parentSize: engine.currentDirSize,
                            isHighlighted: engine.hoveredEntryId == entry.id,
                            onToggle: { engine.toggleEntry(entry.id) },
                            onNavigate: {
                                if entry.isDirectory {
                                    engine.navigateTo(path: entry.path)
                                }
                            },
                            onHover: { hovering in
                                engine.hoveredEntryId = hovering ? entry.id : nil
                            }
                        )
                    }
                }
            }

            if engine.otherItemsSize > 0 {
                Divider().opacity(0.3)
                HStack(spacing: 8) {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Other items")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: engine.otherItemsSize, countStyle: .file))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(DS.bgPanel)
            }
        }
        .background(DS.bgPanel)
    }

    // MARK: - Bubble Canvas
    private var bubbleCanvas: some View {
        ZStack {
            // DS dark background
            DS.bg

            // Center glow with section accent
            RadialGradient(
                colors: [SectionTheme.theme(for: .spaceLens).glow.opacity(0.10), Color.clear],
                center: .center, startRadius: 20, endRadius: 400
            )

            // Bubbles from cached layout
            ForEach(engine.cachedBubbles) { bubble in
                SLBubbleView(
                    bubble: bubble,
                    isHighlighted: engine.hoveredEntryId == bubble.entry.id,
                    onTap: {
                        if bubble.entry.isDirectory {
                            engine.navigateTo(path: bubble.entry.path)
                        } else {
                            engine.toggleEntry(bubble.entry.id)
                        }
                    },
                    onHover: { hovering in
                        engine.hoveredEntryId = hovering ? bubble.entry.id : nil
                    }
                )
                .position(x: bubble.x, y: bubble.y)
            }
        }
        .onAppear { engine.computeLayoutIfNeeded() }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            if abs(newSize.width - engine.lastCanvasSize.width) > 20 ||
               abs(newSize.height - engine.lastCanvasSize.height) > 20 {
                engine.lastCanvasSize = newSize
                engine.recomputeLayout()
            }
        }
    }

    // MARK: - Footer
    private var footerBar: some View {
        HStack(spacing: 10) {
            if let disk = scanEngine.diskInfo {
                HStack(spacing: 8) {
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("Macintosh HD")
                        .font(.system(size: 11, weight: .medium))

                    let fraction = disk.totalSpace > 0
                        ? CGFloat(disk.usedSpace) / CGFloat(disk.totalSpace) : 0
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(DS.bgElevated)
                            .frame(width: 100, height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(colors: [SectionTheme.theme(for: .spaceLens).glow, DS.brandGreen],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: 100 * fraction, height: 5)
                    }
                    .frame(width: 100, height: 5)

                    Text("\(ByteCountFormatter.string(fromByteCount: disk.usedSpace, countStyle: .file)) of \(ByteCountFormatter.string(fromByteCount: disk.totalSpace, countStyle: .file)) used")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if engine.selectedCount > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(SectionTheme.theme(for: .spaceLens).glow)
                    Text("\(engine.selectedCount) items selected")
                        .font(.system(size: 11))
                    Text("•")
                        .foregroundColor(.gray.opacity(0.4))
                    Text(ByteCountFormatter.string(fromByteCount: engine.selectedSize, countStyle: .file))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundColor(.secondary)
            }

            Button {
                showReviewSheet = true
            } label: {
                HStack(spacing: 6) {
                    Text("Review and Remove")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(engine.selectedCount > 0
                              ? AnyShapeStyle(LinearGradient(
                                    colors: [DS.danger, DS.danger.opacity(0.75)],
                                    startPoint: .leading, endPoint: .trailing))
                              : AnyShapeStyle(DS.bgElevated))
                )
            }
            .buttonStyle(.plain)
            .disabled(engine.selectedCount == 0)
            .sheet(isPresented: $showReviewSheet) {
                SLReviewSheet(engine: engine, scanEngine: scanEngine) {
                    showReviewSheet = false
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: =========  FILE ROW  =========
struct SLFileRow: View {
    let entry: SpaceLensEntry
    let parentSize: Int64
    let isHighlighted: Bool
    let onToggle: () -> Void
    let onNavigate: () -> Void
    let onHover: (Bool) -> Void
    @State private var hovered = false

    private var barFraction: CGFloat {
        guard parentSize > 0 else { return 0 }
        return CGFloat(entry.size) / CGFloat(parentSize)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Info button
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: entry.path)])
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(hovered ? 0.7 : 0.3))
            }
            .buttonStyle(.plain)
            .frame(width: 24)

            // Checkbox
            Button(action: onToggle) {
                Image(systemName: entry.isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 13))
                    .foregroundColor(entry.isSelected ? SectionTheme.theme(for: .spaceLens).glow : DS.textMuted.opacity(0.5))
            }
            .buttonStyle(.plain)
            .frame(width: 24)

            // Icon
            Image(systemName: entry.isDirectory ? "folder.fill" : entry.fileIcon)
                .font(.system(size: 13))
                .foregroundColor(entry.isDirectory ? SectionTheme.theme(for: .spaceLens).glow : DS.textMuted.opacity(0.7))
                .frame(width: 22)

            // Name
            Text(entry.name)
                .font(.system(size: 12, weight: entry.isSelected || isHighlighted ? .semibold : .regular))
                .foregroundColor(entry.name.hasPrefix(".") ? DS.textMuted : DS.textPrimary)
                .lineLimit(1)
                .padding(.leading, 6)

            Spacer()

            // Size
            Text(entry.sizeFormatted)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(DS.textSecondary)
                .padding(.trailing, 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            ZStack(alignment: .leading) {
                if barFraction > 0.01 {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(entry.isSelected
                                  ? DS.danger.opacity(0.08)
                                  : SectionTheme.theme(for: .spaceLens).glow.opacity(0.05))
                            .frame(width: geo.size.width * min(barFraction, 1.0))
                    }
                }
                if hovered || isHighlighted {
                    SectionTheme.theme(for: .spaceLens).glow.opacity(0.07)
                }
            }
        )
        .contentShape(Rectangle())
        .onHover { h in
            hovered = h
            onHover(h)
        }
        .onTapGesture {
            if entry.isDirectory {
                onNavigate()
            } else {
                onToggle()
            }
        }
    }
}

// MARK: =========  BUBBLE VIEW  =========
struct SLBubbleView: View {
    let bubble: BubbleLayout
    let isHighlighted: Bool
    let onTap: () -> Void
    let onHover: (Bool) -> Void
    @State private var localHover = false
    @State private var tooltipEntry: SpaceLensEntry? = nil

    private var isHovered: Bool { localHover || isHighlighted }

    private var gradient: LinearGradient {
        if bubble.isSelected {
            return LinearGradient(
                colors: [DS.danger.opacity(0.85), DS.danger.opacity(0.6)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        return LinearGradient(
            colors: [
                Color(hex: "1A5A6E").opacity(isHovered ? 0.95 : 0.75),
                Color(hex: "00A8B5").opacity(isHovered ? 0.80 : 0.60),
                Color(hex: "00B4D8").opacity(isHovered ? 0.65 : 0.45)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        ZStack {
            // Outer glow
            if isHovered {
                Circle()
                    .fill(SectionTheme.theme(for: .spaceLens).glow.opacity(0.22))
                    .frame(width: bubble.radius * 2 + 16, height: bubble.radius * 2 + 16)
                    .blur(radius: 10)
            }

            // Main circle
            Circle()
                .fill(gradient)
                .frame(width: bubble.radius * 2, height: bubble.radius * 2)
                // Glass highlight
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.15), Color.clear],
                                center: .init(x: 0.35, y: 0.25),
                                startRadius: 0,
                                endRadius: bubble.radius * 0.9
                            )
                        )
                )
                // Border
                .overlay(
                    Circle()
                        .strokeBorder(
                            isHovered ? Color.white.opacity(0.35) : Color.white.opacity(0.1),
                            lineWidth: isHovered ? 1.5 : 0.5
                        )
                )
                .shadow(
                    color: (bubble.isSelected ? DS.danger : SectionTheme.theme(for: .spaceLens).glow)
                        .opacity(isHovered ? 0.5 : 0.15),
                    radius: isHovered ? 20 : 6, y: 2
                )

            // Labels
            if bubble.radius > 22 {
                VStack(spacing: bubble.radius > 50 ? 3 : 1) {
                    Image(systemName: bubble.entry.isDirectory ? "folder.fill" : bubble.entry.fileIcon)
                        .font(.system(size: iconSize))
                        .foregroundColor(.white.opacity(0.9))

                    if bubble.radius > 35 {
                        Text(bubble.entry.name)
                            .font(.system(size: nameSize, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(bubble.radius > 55 ? 2 : 1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: bubble.radius * 1.5)
                    }
                    if bubble.radius > 45 {
                        Text(bubble.entry.sizeFormatted)
                            .font(.system(size: sizeSize, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .scaleEffect(isHovered ? 1.06 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { h in
            localHover = h
            onHover(h)
        }
        .onTapGesture { onTap() }
        // Tooltip as overlay instead of popover to prevent flicker
        .overlay(alignment: .top) {
            if isHovered && bubble.radius > 10 {
                SLTooltipCard(entry: bubble.entry)
                    .offset(y: -(bubble.radius + 8))
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .zIndex(999)
            }
        }
    }

    private var iconSize: CGFloat { bubble.radius > 65 ? 22 : (bubble.radius > 45 ? 16 : 12) }
    private var nameSize: CGFloat { bubble.radius > 65 ? 12 : (bubble.radius > 45 ? 10 : 9) }
    private var sizeSize: CGFloat { bubble.radius > 65 ? 11 : 9 }
}

// MARK: =========  TOOLTIP CARD (overlay, not popover)  =========
struct SLTooltipCard: View {
    let entry: SpaceLensEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: entry.isDirectory ? "folder.fill" : entry.fileIcon)
                    .font(.system(size: 11))
                    .foregroundColor(SectionTheme.theme(for: .spaceLens).glow)
                Text(entry.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DS.textPrimary)
                    .lineLimit(1)
            }
            Text(entry.isDirectory ? "Folder" : entry.fileType)
                .font(.system(size: 10))
                .foregroundColor(DS.textMuted)
            Divider().opacity(0.2)
            HStack(spacing: 10) {
                Label(entry.sizeFormatted, systemImage: "internaldrive")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(DS.textSecondary)
                if entry.itemCount > 0 {
                    Label("\(formatCount(entry.itemCount)) items", systemImage: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundColor(DS.textMuted)
                }
            }
            if let date = entry.modifiedDate {
                Text("Modified \(date, format: .dateTime.month(.abbreviated).day().year())")
                    .font(.system(size: 10))
                    .foregroundColor(DS.textMuted)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(DS.bgElevated)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(DS.borderMid, lineWidth: 1))
                .shadow(color: .black.opacity(0.5), radius: 12, y: 4)
        )
        .frame(width: 210)
        .allowsHitTesting(false) // Don't steal mouse events!
    }

    func formatCount(_ c: Int) -> String {
        if c >= 1_000_000 { return String(format: "%.1fM", Double(c) / 1_000_000.0) }
        if c >= 1_000 { return String(format: "%.1fK", Double(c) / 1_000.0) }
        return "\(c)"
    }
}

// MARK: =========  REVIEW SHEET  =========
struct SLReviewSheet: View {
    @ObservedObject var engine: SpaceLensEngine
    let scanEngine: ScanEngine
    let onDismiss: () -> Void
    @State private var isRemoving = false
    @State private var removedSize: Int64 = 0
    @State private var showDone = false

    private var selected: [SpaceLensEntry] { engine.entries.filter(\.isSelected) }

    var body: some View {
        VStack(spacing: 0) {
            if showDone {
                completionView
            } else {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Review and Remove")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("\(selected.count) items • \(ByteCountFormatter.string(fromByteCount: engine.selectedSize, countStyle: .file)) will be moved to Trash")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                Divider()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(selected) { item in
                            HStack(spacing: 10) {
                                Image(systemName: item.isDirectory ? "folder.fill" : item.fileIcon)
                                    .font(.system(size: 14))
                                    .foregroundColor(item.isDirectory ? SectionTheme.theme(for: .spaceLens).glow : DS.textMuted)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .lineLimit(1)
                                    Text(item.path)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Text(item.sizeFormatted)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                                Button {
                                    engine.toggleEntry(item.id)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.secondary.opacity(0.4))
                                        .frame(width: 20, height: 20)
                                        .background(DS.bgElevated)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            Divider().padding(.leading, 50)
                        }
                    }
                }

                Divider()
                HStack {
                    Button("Cancel") { onDismiss() }
                        .font(.system(size: 13))
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        isRemoving = true
                        Task {
                            removedSize = await engine.removeSelected()
                            scanEngine.recordFreed(bytes: removedSize, description: "Space Lens cleanup")
                            isRemoving = false
                            showDone = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isRemoving {
                                ProgressView().scaleEffect(0.7).tint(.white)
                                Text("Moving to Trash…")
                            } else {
                                Image(systemName: "trash")
                                Text("Remove \(ByteCountFormatter.string(fromByteCount: engine.selectedSize, countStyle: .file))")
                            }
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(
                                    colors: [DS.danger, DS.danger.opacity(0.75)],
                                    startPoint: .leading, endPoint: .trailing))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isRemoving || selected.isEmpty)
                }
                .padding(20)
            }
        }
        .background(DS.bgPanel)
        .frame(width: 560, height: 460)
    }

    private var completionView: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [DS.brandGreen, DS.brandTeal],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .shadow(color: DS.brandGreen.opacity(0.45), radius: 20)
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            Text("Cleanup Complete!")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(DS.textPrimary)
            Text(ByteCountFormatter.string(fromByteCount: removedSize, countStyle: .file))
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(DS.brandGradient)
            Text("freed from your disk")
                .foregroundColor(DS.textSecondary)
            Spacer()
            Button("Done") {
                onDismiss()
                engine.rescan()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 10)
            .background(DS.brandGradient)
            .cornerRadius(10)
            .buttonStyle(.plain)
            .padding(.bottom, 24)
        }
    }
}

// MARK: ==========================================================
// MARK: - ENGINE
// MARK: ==========================================================

@MainActor
class SpaceLensEngine: ObservableObject {
    @Published var entries: [SpaceLensEntry] = []
    @Published var currentPath: String = ""
    @Published var isScanning = false
    @Published var scanStatus = ""
    @Published var otherItemsSize: Int64 = 0
    @Published var totalItemCount: Int = 0
    @Published var hoveredEntryId: UUID? = nil
    @Published var cachedBubbles: [BubbleLayout] = []
    var lastCanvasSize: CGSize = .zero

    private struct PathSnapshot {
        let items: [SpaceLensEntry]
        let otherSize: Int64
        let totalCount: Int
    }

    private var backStack: [String] = []
    private var forwardStack: [String] = []
    private let fm = FileManager.default
    private let maxDisplayItems = 20
    private var pathCache: [String: PathSnapshot] = [:]
    private var cacheOrder: [String] = []
    private let maxCachedPaths = 24
    private var scanTask: Task<Void, Never>?
    private var scanSession = UUID()

    var canGoBack: Bool { !backStack.isEmpty }
    var canGoForward: Bool { !forwardStack.isEmpty }

    var currentDirName: String {
        if currentPath == "/" { return "Macintosh HD" }
        return (currentPath as NSString).lastPathComponent
    }

    var currentDirSize: Int64 { entries.reduce(0) { $0 + $1.size } + otherItemsSize }
    var selectedCount: Int { entries.filter(\.isSelected).count }
    var selectedSize: Int64 { entries.filter(\.isSelected).reduce(0) { $0 + $1.size } }

    var selectionLabel: String {
        let s = selectedCount, t = entries.count
        if s == 0 { return "None" }
        if s == t { return "All" }
        return "Manually"
    }

    var breadcrumbs: [BreadcrumbItem] {
        guard !currentPath.isEmpty else { return [] }
        var items: [BreadcrumbItem] = []
        var p = currentPath
        while !p.isEmpty && p != "/" {
            let name = (p as NSString).lastPathComponent
            items.insert(BreadcrumbItem(name: name, path: p, icon: "folder.fill",
                                         isActive: p == currentPath), at: 0)
            p = (p as NSString).deletingLastPathComponent
        }
        items.insert(BreadcrumbItem(name: "Macintosh HD", path: "/", icon: "internaldrive.fill",
                                     isActive: currentPath == "/"), at: 0)
        return items
    }

    // MARK: Navigation
    func navigateTo(path: String) {
        guard !path.isEmpty else { return }
        if currentPath == path { return }
        if !currentPath.isEmpty {
            backStack.append(currentPath)
        }
        forwardStack.removeAll()
        openPath(path)
    }

    func goBack() {
        guard let prev = backStack.popLast() else { return }
        if !currentPath.isEmpty {
            forwardStack.append(currentPath)
        }
        openPath(prev)
    }

    func goForward() {
        guard let next = forwardStack.popLast() else { return }
        if !currentPath.isEmpty {
            backStack.append(currentPath)
        }
        openPath(next)
    }

    func startOver() {
        cancelScan()
        backStack.removeAll()
        forwardStack.removeAll()
        entries = []
        cachedBubbles = []
        currentPath = ""
        otherItemsSize = 0
        totalItemCount = 0
        hoveredEntryId = nil
        pathCache.removeAll()
        cacheOrder.removeAll()
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        scanSession = UUID()
        isScanning = false
        scanStatus = "Scan cancelled."
    }

    func rescan() {
        guard !currentPath.isEmpty else { return }
        invalidateCache(for: currentPath)
        scanDirectory(for: currentPath, force: true)
    }

    // MARK: Selection
    func toggleEntry(_ id: UUID) {
        guard let i = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[i].isSelected.toggle()
        updateBubbleSelections()
        cacheCurrentSnapshot()
    }
    func selectAll() {
        for i in entries.indices { entries[i].isSelected = true }
        updateBubbleSelections()
        cacheCurrentSnapshot()
    }
    func deselectAll() {
        for i in entries.indices { entries[i].isSelected = false }
        updateBubbleSelections()
        cacheCurrentSnapshot()
    }
    func selectFilesOnly() {
        for i in entries.indices { entries[i].isSelected = !entries[i].isDirectory }
        updateBubbleSelections()
        cacheCurrentSnapshot()
    }
    func selectFoldersOnly() {
        for i in entries.indices { entries[i].isSelected = entries[i].isDirectory }
        updateBubbleSelections()
        cacheCurrentSnapshot()
    }
    func selectLargeItems() {
        for i in entries.indices { entries[i].isSelected = entries[i].size > 100_000_000 }
        updateBubbleSelections()
        cacheCurrentSnapshot()
    }

    private func updateBubbleSelections() {
        // Update isSelected in cached bubbles without recalculating positions
        for i in cachedBubbles.indices {
            if let entryIdx = entries.firstIndex(where: { $0.id == cachedBubbles[i].entryId }) {
                cachedBubbles[i].isSelected = entries[entryIdx].isSelected
            }
        }
    }

    // MARK: Remove
    func removeSelected() async -> Int64 {
        var freed: Int64 = 0
        for item in entries.filter(\.isSelected) {
            do {
                try fm.trashItem(at: URL(fileURLWithPath: item.path), resultingItemURL: nil)
                freed += item.size
            } catch {}
        }
        if freed > 0 {
            pathCache.removeAll()
            cacheOrder.removeAll()
        }
        return freed
    }

    // MARK: Scan
    private func openPath(_ path: String) {
        currentPath = path
        hoveredEntryId = nil

        if let cached = pathCache[path] {
            applySnapshot(cached)
            isScanning = false
            scanStatus = ""
            recomputeLayout()
            return
        }

        scanDirectory(for: path, force: false)
    }

    private func applySnapshot(_ snapshot: PathSnapshot) {
        entries = snapshot.items
        otherItemsSize = snapshot.otherSize
        totalItemCount = snapshot.totalCount
        cachedBubbles = []
    }

    private func cacheCurrentSnapshot() {
        guard !currentPath.isEmpty else { return }
        let snapshot = PathSnapshot(items: entries, otherSize: otherItemsSize, totalCount: totalItemCount)
        storeSnapshot(snapshot, for: currentPath)
    }

    private func storeSnapshot(_ snapshot: PathSnapshot, for path: String) {
        pathCache[path] = snapshot
        cacheOrder.removeAll { $0 == path }
        cacheOrder.append(path)

        while cacheOrder.count > maxCachedPaths {
            let oldest = cacheOrder.removeFirst()
            pathCache.removeValue(forKey: oldest)
        }
    }

    private func invalidateCache(for path: String) {
        pathCache.removeValue(forKey: path)
        cacheOrder.removeAll { $0 == path }
    }

    private func scanDirectory(for path: String, force: Bool) {
        if !force, let cached = pathCache[path] {
            applySnapshot(cached)
            isScanning = false
            scanStatus = ""
            recomputeLayout()
            return
        }

        scanTask?.cancel()
        let session = UUID()
        scanSession = session

        isScanning = true
        scanStatus = "Reading contents..."
        entries = []
        cachedBubbles = []
        otherItemsSize = 0
        totalItemCount = 0

        let limit = maxDisplayItems
        scanTask = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            let result = SpaceLensEngine.scanDir(path: path, maxItems: limit)
            if Task.isCancelled { return }

            await MainActor.run {
                guard self.scanSession == session, self.currentPath == path else { return }

                let snapshot = PathSnapshot(
                    items: result.items,
                    otherSize: result.otherSize,
                    totalCount: result.totalCount
                )
                self.storeSnapshot(snapshot, for: path)
                self.applySnapshot(snapshot)
                self.isScanning = false
                self.scanStatus = ""
                self.scanTask = nil
                self.recomputeLayout()
            }
        }
    }

    // MARK: Layout (cached, stable)
    func computeLayoutIfNeeded() {
        if cachedBubbles.isEmpty && !entries.isEmpty && lastCanvasSize.width > 0 {
            recomputeLayout()
        }
    }

    func recomputeLayout() {
        guard !entries.isEmpty, lastCanvasSize.width > 50, lastCanvasSize.height > 50 else {
            cachedBubbles = []
            return
        }
        let snapshot = entries
        let size = lastCanvasSize
        Task {
            let bubbles = await Task.detached(priority: .userInitiated) {
                SpaceLensEngine.packBubbles(entries: snapshot, in: size)
            }.value
            self.cachedBubbles = bubbles
        }
    }

    nonisolated static func packBubbles(entries: [SpaceLensEntry], in size: CGSize) -> [BubbleLayout] {
        guard !entries.isEmpty, size.width > 20, size.height > 20 else { return [] }

        let sorted = entries.sorted { $0.size > $1.size }
        let totalSize = max(sorted.reduce(Int64(0)) { $0 + $1.size }, 1)
        let padding: CGFloat = 8
        let minR: CGFloat = 12
        let maxR: CGFloat = min(size.width, size.height) * 0.34
        let usableArea = max((size.width - padding * 2) * (size.height - padding * 2) * 0.42, 1)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        var circles: [(entry: SpaceLensEntry, x: CGFloat, y: CGFloat, r: CGFloat)] = sorted.map { entry in
            let fraction = max(CGFloat(Double(entry.size) / Double(totalSize)), 0.0001)
            let area = usableArea * fraction
            var radius = sqrt(area / .pi)
            radius = max(minR, min(radius, maxR))
            return (entry, center.x, center.y, radius)
        }

        let areaCap = usableArea * 0.86
        let currentArea = circles.reduce(CGFloat(0)) { $0 + (.pi * $1.r * $1.r) }
        if currentArea > areaCap {
            let scale = sqrt(areaCap / currentArea)
            for i in circles.indices {
                circles[i].r = max(minR * 0.8, circles[i].r * scale)
            }
        }

        var placed: [(x: CGFloat, y: CGFloat, r: CGFloat)] = []
        placed.reserveCapacity(circles.count)

        if let first = circles.first {
            placed.append((first.x, first.y, first.r))
        }

        for i in circles.indices.dropFirst() {
            var radius = circles[i].r
            var chosen: (x: CGFloat, y: CGFloat, r: CGFloat)?
            let seed = CGFloat(i) * 0.73

            for shrinkStep in 0..<10 where chosen == nil {
                let angleOffset = seed + CGFloat(shrinkStep) * 0.41
                var dist = (placed.first?.r ?? 0) + radius + 10
                let maxDist = max(size.width, size.height) * 1.6

                while dist <= maxDist && chosen == nil {
                    let steps = max(28, Int((2 * .pi * dist) / max(radius, 10)))
                    for step in 0..<steps {
                        let angle = angleOffset + (CGFloat(step) / CGFloat(steps)) * .pi * 2
                        let tx = center.x + cos(angle) * dist
                        let ty = center.y + sin(angle) * dist
                        if isValidPlacement(
                            x: tx,
                            y: ty,
                            r: radius,
                            existing: placed,
                            in: size,
                            padding: padding,
                            spacing: 3.5
                        ) {
                            chosen = (tx, ty, radius)
                            break
                        }
                    }
                    dist += max(6, radius * 0.22)
                }

                if chosen == nil {
                    radius = max(minR * 0.72, radius * 0.9)
                }
            }

            if chosen == nil {
                var fallbackRadius = max(minR * 0.72, radius * 0.85)
                while fallbackRadius >= minR * 0.55 && chosen == nil {
                    let step = max(8, fallbackRadius * 0.8)
                    var y = padding + fallbackRadius
                    while y <= size.height - padding - fallbackRadius && chosen == nil {
                        var x = padding + fallbackRadius
                        while x <= size.width - padding - fallbackRadius {
                            if isValidPlacement(
                                x: x,
                                y: y,
                                r: fallbackRadius,
                                existing: placed,
                                in: size,
                                padding: padding,
                                spacing: 2
                            ) {
                                chosen = (x, y, fallbackRadius)
                                break
                            }
                            x += step
                        }
                        y += step
                    }
                    fallbackRadius *= 0.9
                }
            }

            let fallback = chosen ?? (
                x: clamp(center.x, min: padding + radius, max: size.width - padding - radius),
                y: clamp(center.y, min: padding + radius, max: size.height - padding - radius),
                r: radius
            )
            circles[i].x = fallback.x
            circles[i].y = fallback.y
            circles[i].r = fallback.r
            placed.append(fallback)
        }

        resolveOverlaps(&placed, in: size, padding: padding, spacing: 2.5, iterations: 220)

        var result: [BubbleLayout] = []
        result.reserveCapacity(circles.count)
        for (i, circle) in circles.enumerated() {
            let p = placed[i]
            result.append(BubbleLayout(
                entryId: circle.entry.id,
                entry: circle.entry,
                x: p.x,
                y: p.y,
                radius: p.r,
                isSelected: circle.entry.isSelected
            ))
        }
        return result
    }

    nonisolated private static func isValidPlacement(
        x: CGFloat,
        y: CGFloat,
        r: CGFloat,
        existing: [(x: CGFloat, y: CGFloat, r: CGFloat)],
        in size: CGSize,
        padding: CGFloat,
        spacing: CGFloat
    ) -> Bool {
        if x - r < padding || x + r > size.width - padding || y - r < padding || y + r > size.height - padding {
            return false
        }
        for circle in existing {
            let dx = x - circle.x
            let dy = y - circle.y
            let minDist = r + circle.r + spacing
            if (dx * dx + dy * dy) < (minDist * minDist) {
                return false
            }
        }
        return true
    }

    nonisolated private static func resolveOverlaps(
        _ circles: inout [(x: CGFloat, y: CGFloat, r: CGFloat)],
        in size: CGSize,
        padding: CGFloat,
        spacing: CGFloat,
        iterations: Int
    ) {
        guard circles.count > 1 else { return }

        for _ in 0..<iterations {
            var moved = false

            for i in circles.indices {
                for j in circles.indices where j > i {
                    var dx = circles[j].x - circles[i].x
                    var dy = circles[j].y - circles[i].y
                    var dist = sqrt(dx * dx + dy * dy)
                    let minDist = circles[i].r + circles[j].r + spacing
                    if dist >= minDist { continue }

                    if dist < 0.001 {
                        dx = 0.001
                        dy = 0
                        dist = 0.001
                    }

                    let overlap = minDist - dist
                    let nx = dx / dist
                    let ny = dy / dist
                    let push = overlap * 0.52

                    circles[i].x -= nx * push
                    circles[i].y -= ny * push
                    circles[j].x += nx * push
                    circles[j].y += ny * push
                    moved = true
                }
            }

            for k in circles.indices {
                let r = circles[k].r
                circles[k].x = clamp(circles[k].x, min: padding + r, max: size.width - padding - r)
                circles[k].y = clamp(circles[k].y, min: padding + r, max: size.height - padding - r)
            }

            if !moved { break }
        }
    }

    nonisolated private static func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        if minValue > maxValue { return value }
        return Swift.max(minValue, Swift.min(value, maxValue))
    }

    // MARK: Static Scanner
    nonisolated static func scanDir(path: String, maxItems: Int) -> (items: [SpaceLensEntry], otherSize: Int64, totalCount: Int) {
        let fm = FileManager.default
        let contents: [String]

        if path == "/" {
            contents = ["Users", "Applications", "System", "Library",
                        "private", "opt", "usr", "bin", "sbin", "tmp", "var"]
                .filter { fm.fileExists(atPath: "/\($0)") }
        } else {
            guard let c = try? fm.contentsOfDirectory(atPath: path) else { return ([], 0, 0) }
            contents = c
        }

        var all: [SpaceLensEntry] = []
        let totalCount = contents.count

        for name in contents {
            let full = path == "/" ? "/\(name)" : "\(path)/\(name)"
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: full, isDirectory: &isDir) else { continue }

            let attrs = try? fm.attributesOfItem(atPath: full)
            let modDate = attrs?[.modificationDate] as? Date
            let size: Int64
            var itemCount = 0

            if isDir.boolValue {
                size = ScanEngine.calcSize(path: full)
                itemCount = (try? fm.contentsOfDirectory(atPath: full))?.count ?? 0
            } else {
                size = (attrs?[.size] as? Int64) ?? 0
            }

            all.append(SpaceLensEntry(
                name: name, path: full, size: size,
                isDirectory: isDir.boolValue, isSelected: false,
                itemCount: itemCount, modifiedDate: modDate
            ))
        }

        all.sort { $0.size > $1.size }

        if all.count > maxItems {
            let displayed = Array(all.prefix(maxItems))
            let other = all.dropFirst(maxItems).reduce(Int64(0)) { $0 + $1.size }
            return (displayed, other, totalCount)
        }
        return (all, 0, totalCount)
    }
}

// MARK: ==========================================================
// MARK: - MODELS
// MARK: ==========================================================

struct SpaceLensEntry: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    let isDirectory: Bool
    var isSelected: Bool
    let itemCount: Int
    let modifiedDate: Date?

    var sizeFormatted: String {
        if size < 1024 { return "< 1 KB" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var fileIcon: String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.fill"
        case "jpg", "jpeg", "png", "gif", "heic", "webp", "tiff": return "photo.fill"
        case "mp4", "mov", "avi", "mkv", "m4v": return "film.fill"
        case "mp3", "aac", "wav", "flac", "m4a": return "music.note"
        case "zip", "gz", "tar", "rar", "7z", "xz": return "doc.zipper"
        case "dmg", "iso": return "opticaldisc.fill"
        case "app": return "app.fill"
        case "plist", "json", "xml", "yaml", "yml": return "doc.text.fill"
        case "swift", "py", "js", "ts", "c", "cpp", "h", "m", "rs", "go": return "chevron.left.forwardslash.chevron.right"
        default: return "doc.fill"
        }
    }

    var fileType: String {
        if isDirectory { return "Folder" }
        let ext = (name as NSString).pathExtension
        if ext.isEmpty { return "File" }
        return "\(ext.uppercased()) file"
    }
}

struct BreadcrumbItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let icon: String
    let isActive: Bool
}

struct BubbleLayout: Identifiable {
    let id = UUID()
    let entryId: UUID
    let entry: SpaceLensEntry
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
    var isSelected: Bool
}
