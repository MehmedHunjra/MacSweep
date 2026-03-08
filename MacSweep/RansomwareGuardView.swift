import SwiftUI

struct RansomwareGuardView: View {
    @ObservedObject var engine: RansomwareGuardEngine
    @EnvironmentObject var navManager: NavigationManager

    @State private var searchText = ""
    @State private var filterType: String? = nil   // nil = all

    private var theme: SectionTheme { SectionTheme.theme(for: .ransomwareGuard) }

    private var filteredEvents: [FileChangeEvent] {
        var events = engine.recentEvents
        if let type = filterType {
            events = events.filter { $0.eventType == type }
        }
        if !searchText.isEmpty {
            events = events.filter {
                $0.fileName.localizedCaseInsensitiveContains(searchText) ||
                $0.path.localizedCaseInsensitiveContains(searchText)
            }
        }
        return events
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            if engine.isMonitoring {
                statusCards
                toolBar
                eventTable
            } else {
                emptyState
            }
        }
        .background(DS.bg)
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
                Text("Ransomware Guard")
                    .font(MSFont.title2)
                    .foregroundColor(DS.textPrimary)
                Text(engine.isMonitoring
                     ? "\(engine.recentEvents.count) file events · Alert: \(engine.alertLevel.rawValue)"
                     : "Monitor file system for suspicious encryption activity")
                    .font(MSFont.caption)
                    .foregroundColor(engine.isMonitoring ? engine.alertLevel.color : DS.textMuted)
            }

            Spacer()

            HStack(spacing: 10) {
                if engine.isMonitoring {
                    Button {
                        engine.clearEvents()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundColor(DS.textSecondary)
                            .padding(8)
                            .contentShape(Rectangle())
                            .background(RoundedRectangle(cornerRadius: 6).fill(DS.bgElevated))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    if engine.isMonitoring {
                        engine.stopMonitoring()
                    } else {
                        engine.startMonitoring()
                    }
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

    // MARK: - Status Cards
    private var statusCards: some View {
        HStack(spacing: 12) {
            // Alert Level Card
            StatusCard(
                icon: engine.alertLevel.icon,
                title: "Status",
                value: engine.alertLevel.rawValue,
                color: engine.alertLevel.color
            )

            // File Changes / min
            StatusCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Changes / min",
                value: "\(engine.encryptionRate)",
                color: engine.encryptionRate > 50 ? DS.danger :
                       engine.encryptionRate > 20 ? DS.warning : DS.success
            )

            // Total Events
            StatusCard(
                icon: "doc.text.magnifyingglass",
                title: "Total Events",
                value: "\(engine.recentEvents.count)",
                color: theme.glow
            )

            // Monitored Folders
            StatusCard(
                icon: "folder.badge.gearshape",
                title: "Monitored Folders",
                value: "4",
                color: DS.textSecondary
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(DS.bgPanel.opacity(0.4))
        .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1).allowsHitTesting(false), alignment: .bottom)
    }

    // MARK: - Toolbar
    private var toolBar: some View {
        HStack(spacing: 12) {
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundColor(DS.textMuted)
                TextField("Search file name or path...", text: $searchText)
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

            // Event type filters
            EventFilterChip(label: "All", isSelected: filterType == nil, color: theme.glow) {
                filterType = nil
            }
            EventFilterChip(label: "Created", isSelected: filterType == "Created", color: DS.success) {
                filterType = (filterType == "Created") ? nil : "Created"
            }
            EventFilterChip(label: "Modified", isSelected: filterType == "Modified", color: DS.warning) {
                filterType = (filterType == "Modified") ? nil : "Modified"
            }
            EventFilterChip(label: "Deleted", isSelected: filterType == "Deleted", color: DS.danger) {
                filterType = (filterType == "Deleted") ? nil : "Deleted"
            }

            Spacer()

            Text("\(filteredEvents.count) events")
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
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(theme.linearGradient)
                    .shadow(color: theme.glow.opacity(0.4), radius: 16)
            }
            VStack(spacing: 8) {
                Text("Ransomware Guard")
                    .font(MSFont.title)
                    .foregroundColor(DS.textPrimary)
                Text("Monitors your Documents, Desktop, Downloads & Pictures\nfor suspicious file encryption activity in real time.")
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

    // MARK: - Event Table
    private var eventTable: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack(spacing: 0) {
                Text("Type")
                    .frame(width: 80, alignment: .center)
                Text("File")
                    .frame(minWidth: 160, alignment: .leading)
                Text("Path")
                    .frame(minWidth: 200, alignment: .leading)
                Spacer()
                Text("Time")
                    .frame(width: 100, alignment: .trailing)
            }
            .font(MSFont.mono)
            .foregroundColor(DS.textMuted)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(DS.bgElevated)
            .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1).allowsHitTesting(false), alignment: .bottom)

            if filteredEvents.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 32))
                        .foregroundColor(DS.success)
                    Text(engine.recentEvents.isEmpty
                         ? "No file changes detected yet — monitoring…"
                         : "No matching events")
                        .font(MSFont.body)
                        .foregroundColor(DS.textMuted)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredEvents) { event in
                            FileEventRow(event: event)
                            Divider().background(DS.borderSubtle.opacity(0.5))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - File Event Row

private struct FileEventRow: View {
    let event: FileChangeEvent
    @State private var isHovered = false

    private var typeColor: Color {
        switch event.eventType {
        case "Created":  return DS.success
        case "Modified": return DS.warning
        case "Deleted":  return DS.danger
        default:         return DS.textMuted
        }
    }

    private var typeIcon: String {
        switch event.eventType {
        case "Created":  return "plus.circle.fill"
        case "Modified": return "pencil.circle.fill"
        case "Deleted":  return "minus.circle.fill"
        default:         return "questionmark.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Type badge
            HStack(spacing: 5) {
                Image(systemName: typeIcon)
                    .font(.system(size: 11))
                    .foregroundColor(typeColor)
                Text(event.eventType)
                    .font(MSFont.mono)
                    .foregroundColor(typeColor)
            }
            .frame(width: 80, alignment: .center)

            // File name
            Text(event.fileName)
                .font(MSFont.mono)
                .foregroundColor(DS.textSecondary)
                .lineLimit(1)
                .frame(minWidth: 160, alignment: .leading)

            // Path (shortened)
            Text(shortenedPath(event.path))
                .font(MSFont.mono)
                .foregroundColor(DS.textMuted)
                .lineLimit(1)
                .frame(minWidth: 200, alignment: .leading)

            Spacer()

            // Time
            Text(event.timeFormatted)
                .font(MSFont.mono)
                .foregroundColor(DS.textMuted)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 9)
        .background(isHovered ? DS.bgElevated : Color.clear)
        .onHover { isHovered = $0 }
        .animation(Motion.fast, value: isHovered)
    }

    private func shortenedPath(_ path: String) -> String {
        path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }
}

// MARK: - Status Card

private struct StatusCard: View {
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

// MARK: - Event Filter Chip

private struct EventFilterChip: View {
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
