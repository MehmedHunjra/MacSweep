import SwiftUI

struct IntegrityMonitorView: View {
    @ObservedObject var engine: IntegrityMonitorEngine
    @EnvironmentObject var navManager: NavigationManager

    @State private var searchText = ""
    @State private var filterKind: IntegrityItem.Kind? = nil
    @State private var showHighRiskOnly = false
    @State private var showWhitelisted = false
    @State private var selectedItem: IntegrityItem? = nil
    @State private var selectedIDs: Set<UUID> = []
    @State private var showBulkWhitelistConfirm = false

    private var theme: SectionTheme { SectionTheme.theme(for: .integrityMonitor) }

    private var filtered: [IntegrityItem] {
        var list = engine.items
        if !showWhitelisted { list = list.filter { !$0.isWhitelisted } }
        if let kind = filterKind { list = list.filter { $0.kind == kind } }
        if showHighRiskOnly { list = list.filter { $0.risk >= .high } }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                $0.name.lowercased().contains(q) ||
                $0.path.lowercased().contains(q) ||
                ($0.detail?.lowercased().contains(q) ?? false)
            }
        }
        return list.sorted { $0.risk > $1.risk }
    }

    /// Active kind filters (only show kinds that actually have items)
    private var activeKinds: [IntegrityItem.Kind] {
        let seen = Set(engine.items.map(\.kind))
        return IntegrityItem.Kind.allCases.filter { seen.contains($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            if engine.isMonitoring || !engine.items.isEmpty {
                statusCards
                if !selectedIDs.isEmpty {
                    bulkActionBar
                }
                toolBar
                itemTable
            } else {
                emptyState
            }
        }
        .background(DS.bg)
        .sheet(item: $selectedItem) { item in
            IntegrityDetailSheet(item: item, engine: engine, theme: theme)
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 16) {
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

            VStack(alignment: .leading, spacing: 2) {
                Text("System Integrity")
                    .font(MSFont.title2)
                    .foregroundColor(DS.textPrimary)
                Text(engine.isMonitoring
                     ? "\(engine.items.count) items monitored · \(engine.healthStatus.rawValue)"
                     : "Monitor persistence, configs & system trust")
                    .font(MSFont.caption)
                    .foregroundColor(engine.isMonitoring ? engine.healthStatus.color : DS.textMuted)
            }

            Spacer()

            HStack(spacing: 10) {
                if engine.isMonitoring {
                    // Select All / Deselect
                    if !filtered.isEmpty {
                        Button {
                            if selectedIDs.count == filtered.count {
                                selectedIDs.removeAll()
                            } else {
                                selectedIDs = Set(filtered.map(\.id))
                            }
                        } label: {
                            Text(selectedIDs.count == filtered.count && !filtered.isEmpty ? "Deselect" : "Select All")
                                .font(MSFont.caption)
                                .foregroundColor(DS.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                                .background(RoundedRectangle(cornerRadius: 6).fill(DS.bgElevated))
                        }
                        .buttonStyle(.plain)
                    }

                    // Settings gear
                    Button {
                        navManager.navigate(to: .settings, subState: "Integrity")
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                            .foregroundColor(DS.textSecondary)
                            .padding(8)
                            .contentShape(Rectangle())
                            .background(RoundedRectangle(cornerRadius: 6).fill(DS.bgElevated))
                    }
                    .buttonStyle(.plain)
                    .help("Integrity Settings")

                    // Export
                    Button {
                        exportToFile()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13))
                            .foregroundColor(DS.textSecondary)
                            .padding(8)
                            .contentShape(Rectangle())
                            .background(RoundedRectangle(cornerRadius: 6).fill(DS.bgElevated))
                    }
                    .buttonStyle(.plain)
                    .help("Export Report")

                    // Rescan
                    Button { engine.rescan() } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13))
                            .foregroundColor(DS.textSecondary)
                            .padding(8)
                            .contentShape(Rectangle())
                            .background(RoundedRectangle(cornerRadius: 6).fill(DS.bgElevated))
                    }
                    .buttonStyle(.plain)
                    .help("Rescan Now")
                }

                Button {
                    if engine.isMonitoring { engine.stopMonitoring() }
                    else { engine.startMonitoring() }
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(engine.isMonitoring ? DS.success : DS.textMuted)
                            .frame(width: 8, height: 8)
                            .shadow(color: engine.isMonitoring ? DS.success.opacity(0.7) : .clear, radius: 4)
                        Text(engine.isMonitoring ? "Stop" : "Start Monitoring")
                            .font(MSFont.headline)
                            .foregroundColor(engine.isMonitoring ? DS.danger : DS.textPrimary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(engine.isMonitoring ? DS.danger.opacity(0.12) : theme.glow.opacity(0.15))
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(engine.isMonitoring ? DS.danger.opacity(0.3) : theme.glow.opacity(0.3), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(DS.bgPanel)
        .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1).allowsHitTesting(false), alignment: .bottom)
    }

    // MARK: - Bulk Action Bar

    private var bulkActionBar: some View {
        HStack(spacing: 14) {
            Text("\(selectedIDs.count) selected")
                .font(MSFont.bodyBold)
                .foregroundColor(DS.textPrimary)

            Spacer()

            Button {
                showBulkWhitelistConfirm = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "eye.slash")
                    Text("Whitelist Selected")
                }
                .font(MSFont.caption)
                .foregroundColor(DS.warning)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(DS.warning.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .alert("Whitelist \(selectedIDs.count) items?", isPresented: $showBulkWhitelistConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Whitelist") {
                    for id in selectedIDs {
                        if let item = engine.items.first(where: { $0.id == id }) {
                            if !item.isWhitelisted {
                                engine.toggleWhitelist(path: item.path)
                            }
                        }
                    }
                    selectedIDs.removeAll()
                }
            }

            Button {
                selectedIDs.removeAll()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                    Text("Clear")
                }
                .font(MSFont.caption)
                .foregroundColor(DS.textMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(DS.bgElevated))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(theme.glow.opacity(0.08))
        .overlay(Rectangle().fill(theme.glow.opacity(0.3)).frame(height: 1).allowsHitTesting(false), alignment: .bottom)
    }

    // MARK: - Status Cards

    private var statusCards: some View {
        HStack(spacing: 12) {
            SIMStatusCard(
                icon: engine.healthStatus.icon,
                title: "Health",
                value: engine.healthStatus.rawValue,
                color: engine.healthStatus.color
            )

            SIMStatusCard(
                icon: "list.bullet.clipboard",
                title: "Total Items",
                value: "\(engine.items.count)",
                color: theme.glow
            )

            SIMStatusCard(
                icon: "exclamationmark.shield",
                title: "High / Critical",
                value: "\(engine.highRiskCount)",
                color: engine.highRiskCount > 0 ? DS.danger : DS.success
            )

            SIMStatusCard(
                icon: "clock",
                title: "Monitoring",
                value: monitoringDuration,
                color: DS.textSecondary
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(DS.bgPanel.opacity(0.4))
        .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1).allowsHitTesting(false), alignment: .bottom)
    }

    private var monitoringDuration: String {
        guard let start = engine.monitoringStartDate else { return "—" }
        let interval = Date().timeIntervalSince(start)
        if interval < 60 { return "\(Int(interval))s" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        return "\(Int(interval / 3600))h \(Int(interval.truncatingRemainder(dividingBy: 3600) / 60))m"
    }

    // MARK: - Toolbar

    private var toolBar: some View {
        HStack(spacing: 12) {
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundColor(DS.textMuted)
                TextField("Search items…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(MSFont.body)
                    .foregroundColor(DS.textPrimary)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(DS.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 8).fill(DS.bgElevated).overlay(
                RoundedRectangle(cornerRadius: 8).stroke(DS.borderSubtle, lineWidth: 1)))

            // Kind filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    SIMFilterChip(label: "All", isSelected: filterKind == nil, color: theme.glow) {
                        filterKind = nil
                    }
                    ForEach(activeKinds, id: \.self) { kind in
                        SIMFilterChip(label: kind.shortLabel, isSelected: filterKind == kind, color: theme.glow) {
                            filterKind = (filterKind == kind) ? nil : kind
                        }
                    }
                }
            }

            // High risk toggle
            SIMFilterChip(label: "⚠ High+", isSelected: showHighRiskOnly, color: DS.danger) {
                showHighRiskOnly.toggle()
            }

            // Whitelist toggle
            SIMFilterChip(label: "Whitelisted", isSelected: showWhitelisted, color: DS.textMuted) {
                showWhitelisted.toggle()
            }

            Spacer()

            Text("\(filtered.count) items")
                .font(MSFont.mono)
                .foregroundColor(DS.textMuted)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(DS.bgPanel.opacity(0.6))
        .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1).allowsHitTesting(false), alignment: .bottom)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(theme.glow.opacity(0.10))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(theme.linearGradient)
                    .shadow(color: theme.glow.opacity(0.4), radius: 16)
            }
            VStack(spacing: 8) {
                Text("System Integrity Monitor")
                    .font(MSFont.title)
                    .foregroundColor(DS.textPrimary)
                Text("Continuously audits persistence mechanisms, code signatures,\nand critical configurations for unauthorized changes.")
                    .font(MSFont.body)
                    .foregroundColor(DS.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                engine.startMonitoring()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("Start Monitoring")
                        .font(MSFont.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 13)
                .background(Capsule().fill(theme.linearGradient))
                .shadow(color: theme.glow.opacity(0.35), radius: 12, y: 4)
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: - Item Table

    private var itemTable: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 36)
                Text("Risk")
                    .frame(width: 50, alignment: .center)
                Text("Kind")
                    .frame(width: 110, alignment: .leading)
                Text("Name")
                    .frame(minWidth: 180, alignment: .leading)
                Spacer()
                Text("Signature")
                    .frame(width: 100, alignment: .center)
                Text("Level")
                    .frame(width: 80, alignment: .center)
                Text("Actions")
                    .frame(width: 100, alignment: .center)
            }
            .font(MSFont.mono)
            .foregroundColor(DS.textMuted)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(DS.bgElevated)
            .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1).allowsHitTesting(false), alignment: .bottom)

            if filtered.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 32))
                        .foregroundColor(DS.success)
                    Text(engine.items.isEmpty
                         ? "Scanning system persistence points…"
                         : "No matching items")
                        .font(MSFont.body)
                        .foregroundColor(DS.textMuted)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { item in
                            SIMItemRow(item: item, engine: engine, theme: theme, isSelected: selectedIDs.contains(item.id), onSelect: {
                                if selectedIDs.contains(item.id) {
                                    selectedIDs.remove(item.id)
                                } else {
                                    selectedIDs.insert(item.id)
                                }
                            }, onDetail: {
                                selectedItem = item
                            })
                            Divider().background(DS.borderSubtle.opacity(0.5))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Export

    private func exportToFile() {
        let report = engine.exportReport()
        let panel = NSSavePanel()
        panel.title = "Export Integrity Report"
        panel.nameFieldStringValue = "MacSweep_IntegrityReport.txt"
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            try? report.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

// MARK: - Item Row

private struct SIMItemRow: View {
    let item: IntegrityItem
    let engine: IntegrityMonitorEngine
    let theme: SectionTheme
    let isSelected: Bool
    let onSelect: () -> Void
    let onDetail: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            // Selection checkbox
            Button(action: onSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? theme.glow : DS.textMuted.opacity(0.5))
            }
            .buttonStyle(.plain)
            .frame(width: 36, alignment: .center)

            // Risk indicator
            HStack(spacing: 5) {
                Image(systemName: item.risk.icon)
                    .font(.system(size: 11))
                    .foregroundColor(item.risk.color)
            }
            .frame(width: 50, alignment: .center)

            // Kind badge
            HStack(spacing: 4) {
                Image(systemName: item.kind.icon)
                    .font(.system(size: 10))
                    .foregroundColor(theme.glow)
                Text(item.kind.shortLabel)
                    .font(MSFont.mono)
                    .foregroundColor(DS.textMuted)
            }
            .frame(width: 110, alignment: .leading)

            // Name + path + detail
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(MSFont.body)
                    .foregroundColor(item.isWhitelisted ? DS.textMuted : DS.textPrimary)
                    .strikethrough(item.isWhitelisted)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(shortenedPath(item.path))
                        .font(MSFont.mono)
                        .foregroundColor(DS.textMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if let detail = item.detail {
                        Text("·")
                            .foregroundColor(DS.textMuted)
                        Text(detail)
                            .font(MSFont.mono)
                            .foregroundColor(item.risk >= .high ? item.risk.color : DS.textMuted)
                            .lineLimit(1)
                    }
                }
            }
            .frame(minWidth: 180, alignment: .leading)

            Spacer()

            // Signature badge
            HStack(spacing: 4) {
                Image(systemName: item.codeSigned ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                Text(item.codeSigned ? "Signed" : "Unsigned")
                    .font(MSFont.mono)
            }
            .foregroundColor(item.codeSigned ? DS.success : DS.warning)
            .frame(width: 100, alignment: .center)

            // Risk pill
            Text(item.risk.rawValue)
                .font(MSFont.mono)
                .foregroundColor(item.risk.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(item.risk.color.opacity(0.12)))
                .frame(width: 80, alignment: .center)

            // Actions
            HStack(spacing: 6) {
                Button { onDetail() } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(DS.textMuted)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Details")

                Button { engine.toggleWhitelist(path: item.path) } label: {
                    Image(systemName: item.isWhitelisted ? "eye.slash" : "eye")
                        .font(.system(size: 12))
                        .foregroundColor(item.isWhitelisted ? DS.warning : DS.textMuted)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(item.isWhitelisted ? "Remove from whitelist" : "Whitelist")

                Button { engine.reveal(item) } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 12))
                        .foregroundColor(DS.textMuted)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Reveal in Finder")
            }
            .frame(width: 100, alignment: .center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 9)
        .background(isSelected ? theme.glow.opacity(0.08) : (isHovered ? DS.bgElevated : Color.clear))
        .onHover { isHovered = $0 }
        .animation(Motion.fast, value: isHovered)
    }

    private func shortenedPath(_ path: String) -> String {
        path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }
}

// MARK: - Detail Sheet

private struct IntegrityDetailSheet: View {
    let item: IntegrityItem
    let engine: IntegrityMonitorEngine
    let theme: SectionTheme
    @Environment(\.dismiss) private var dismiss
    @State private var showDisableConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: item.kind.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(theme.linearGradient)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(MSFont.title2)
                        .foregroundColor(DS.textPrimary)
                    Text(item.kind.rawValue)
                        .font(MSFont.caption)
                        .foregroundColor(DS.textMuted)
                }
                Spacer()
                Text(item.risk.rawValue)
                    .font(MSFont.headline)
                    .foregroundColor(item.risk.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(item.risk.color.opacity(0.12)))
            }
            .padding(20)

            Divider().background(DS.borderSubtle)

            // Properties
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    detailRow("Path", item.path)
                    if let target = item.targetExecutable {
                        detailRow("Target Executable", target)
                    }
                    detailRow("Code Signed", item.codeSigned ? "✓ Yes" : "✗ No")
                    if let team = item.teamIdentifier, team != "not set" {
                        detailRow("Team Identifier", team)
                    }
                    detailRow("Size", item.sizeFormatted)
                    detailRow("First Seen", formatDate(item.firstSeen))
                    detailRow("Last Changed", formatDate(item.lastChanged))
                    if let detail = item.detail {
                        detailRow("Details", detail)
                    }
                    detailRow("Whitelisted", item.isWhitelisted ? "Yes" : "No")
                }
                .padding(20)
            }

            Divider().background(DS.borderSubtle)

            // Footer buttons
            HStack(spacing: 12) {
                if item.kind == .launchAgent || item.kind == .launchDaemon {
                    Button {
                        showDisableConfirm = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Disable")
                        }
                        .font(MSFont.body)
                        .foregroundColor(DS.danger)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(DS.danger.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .alert("Disable \(item.name)?", isPresented: $showDisableConfirm) {
                        Button("Cancel", role: .cancel) { }
                        Button("Disable", role: .destructive) {
                            try? engine.disable(item)
                            dismiss()
                        }
                    } message: {
                        Text("This will unload the item and move it to Trash. You can restore it from the Trash if needed.")
                    }
                }

                Button {
                    engine.toggleWhitelist(path: item.path)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: item.isWhitelisted ? "eye.slash" : "eye")
                        Text(item.isWhitelisted ? "Remove Whitelist" : "Whitelist")
                    }
                    .font(MSFont.body)
                    .foregroundColor(DS.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(DS.bgElevated))
                }
                .buttonStyle(.plain)

                Button {
                    engine.reveal(item)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                        Text("Reveal")
                    }
                    .font(MSFont.body)
                    .foregroundColor(DS.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(DS.bgElevated))
                }
                .buttonStyle(.plain)

                Spacer()

                Button { dismiss() } label: {
                    Text("Done")
                        .font(MSFont.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(theme.linearGradient))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .frame(width: 600, height: 500)
        .background(DS.bg)
    }

    @ViewBuilder
    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(MSFont.caption)
                .foregroundColor(DS.textMuted)
            Text(value)
                .font(MSFont.body)
                .foregroundColor(DS.textPrimary)
                .textSelection(.enabled)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }
}

// MARK: - Status Card

private struct SIMStatusCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Text(title)
                    .font(MSFont.caption)
                    .foregroundColor(DS.textMuted)
            }
            Text(value)
                .font(MSFont.title2)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(DS.bgElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Filter Chip

private struct SIMFilterChip: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(color)
                }
                Text(label)
                    .font(MSFont.caption)
                    .foregroundColor(isSelected ? color : DS.textMuted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? color.opacity(0.12) : DS.bgElevated)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(isSelected ? color.opacity(0.35) : DS.borderSubtle, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}
