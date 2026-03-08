import SwiftUI

struct NetworkMonitorView: View {
    @ObservedObject var engine: NetworkMonitorEngine
    @EnvironmentObject var navManager: NavigationManager

    @State private var searchText = ""
    @State private var filterSuspiciousOnly = false
    @State private var sortByRisk = true

    private var theme: SectionTheme { SectionTheme.theme(for: .networkMonitor) }

    private var filteredConnections: [NetworkConnection] {
        var conns = engine.connections
        if filterSuspiciousOnly { conns = conns.filter { $0.isSuspicious || $0.isBlocked } }
        if !searchText.isEmpty {
            conns = conns.filter {
                $0.remoteAddress.localizedCaseInsensitiveContains(searchText) ||
                $0.processName.localizedCaseInsensitiveContains(searchText) ||
                "\($0.remotePort)".contains(searchText)
            }
        }
        if sortByRisk {
            conns.sort { $0.isBlocked && !$1.isBlocked || ($0.isSuspicious && !$1.isSuspicious) }
        }
        return conns
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            toolBar

            if engine.connections.isEmpty && !engine.isMonitoring {
                emptyState
            } else {
                connectionTable
            }
        }
        .background(DS.bg)
    }

    // MARK: Header
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
                Text("Network Threat Monitor")
                    .font(MSFont.title2)
                    .foregroundColor(DS.textPrimary)
                Text(engine.isMonitoring
                     ? "\(engine.connections.count) active connections · \(engine.connections.filter { $0.isSuspicious }.count) suspicious"
                     : "Monitor active network connections for threats")
                    .font(MSFont.caption)
                    .foregroundColor(engine.isMonitoring ? theme.glow : DS.textMuted)
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    Task { await engine.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13))
                        .foregroundColor(DS.textSecondary)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(DS.bgElevated))
                }
                .buttonStyle(.plain)
                .disabled(!engine.isMonitoring)

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
        .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1), alignment: .bottom)
    }

    // MARK: Toolbar
    private var toolBar: some View {
        HStack(spacing: 12) {
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundColor(DS.textMuted)
                TextField("Search IP, process, port...", text: $searchText)
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

            // Filter toggles
            FilterChip(label: "Suspicious Only", isOn: $filterSuspiciousOnly, color: DS.warning)
            FilterChip(label: "Sort by Risk", isOn: $sortByRisk, color: theme.glow)

            Spacer()

            if !engine.blockedIPs.isEmpty {
                Text("\(engine.blockedIPs.count) blocked")
                    .font(MSFont.mono)
                    .foregroundColor(DS.danger)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(DS.danger.opacity(0.12)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(DS.bgPanel.opacity(0.6))
        .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1), alignment: .bottom)
    }

    // MARK: Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(theme.glow.opacity(0.10))
                    .frame(width: 120, height: 120)
                Image(systemName: "network")
                    .font(.system(size: 50))
                    .foregroundStyle(theme.linearGradient)
                    .shadow(color: theme.glow.opacity(0.4), radius: 16)
            }
            VStack(spacing: 8) {
                Text("Network Threat Monitor")
                    .font(MSFont.title)
                    .foregroundColor(DS.textPrimary)
                Text("Start monitoring to see active TCP connections\nand detect suspicious outbound traffic.")
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

    // MARK: Connection Table
    private var connectionTable: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack(spacing: 0) {
                Text("Status")
                    .frame(width: 50, alignment: .center)
                Text("Process")
                    .frame(width: 110, alignment: .leading)
                Text("Remote Address")
                    .frame(minWidth: 150, alignment: .leading)
                Text("Port")
                    .frame(width: 55, alignment: .trailing)
                Text("State")
                    .frame(width: 90, alignment: .center)
                Spacer()
                Text("Actions")
                    .frame(width: 120, alignment: .trailing)
            }
            .font(MSFont.mono)
            .foregroundColor(DS.textMuted)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(DS.bgElevated)
            .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1), alignment: .bottom)

            if filteredConnections.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 32))
                        .foregroundColor(DS.success)
                    Text(filterSuspiciousOnly ? "No suspicious connections" : "No connections found")
                        .font(MSFont.body)
                        .foregroundColor(DS.textMuted)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredConnections) { conn in
                            ConnectionRow(conn: conn,
                                          onBlock: { engine.blockConnection(conn) },
                                          onAllow: { engine.allowConnection(conn) })
                            Divider().background(DS.borderSubtle.opacity(0.5))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Connection Row

private struct ConnectionRow: View {
    let conn: NetworkConnection
    let onBlock: () -> Void
    let onAllow: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            // Status dot
            HStack {
                Circle()
                    .fill(conn.riskColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: conn.riskColor.opacity(0.6), radius: 3)
            }
            .frame(width: 50)

            // Process name
            Text(conn.processName)
                .font(MSFont.mono)
                .foregroundColor(DS.textSecondary)
                .lineLimit(1)
                .frame(width: 110, alignment: .leading)

            // Remote
            Text(conn.remoteAddress.isEmpty ? "*" : conn.remoteAddress)
                .font(MSFont.mono)
                .foregroundColor(conn.isSuspicious ? DS.warning : DS.textMuted)
                .lineLimit(1)
                .frame(minWidth: 150, alignment: .leading)

            // Port
            Text("\(conn.remotePort)")
                .font(MSFont.mono)
                .foregroundColor(conn.isSuspicious ? DS.warning : DS.textMuted)
                .frame(width: 55, alignment: .trailing)

            // State
            Text(conn.state)
                .font(MSFont.mono)
                .foregroundColor(DS.textMuted)
                .frame(width: 90, alignment: .center)

            Spacer()

            // Actions (show on hover)
            if isHovered || conn.isBlocked {
                HStack(spacing: 6) {
                    if conn.isBlocked {
                        Button(action: onAllow) {
                            Text("Unblock")
                                .font(MSFont.mono)
                                .foregroundColor(DS.success)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(RoundedRectangle(cornerRadius: 5).fill(DS.success.opacity(0.12)))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: onBlock) {
                            Text("Block")
                                .font(MSFont.mono)
                                .foregroundColor(DS.danger)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(RoundedRectangle(cornerRadius: 5).fill(DS.danger.opacity(0.12)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 120, alignment: .trailing)
                .transition(.opacity)
            } else {
                Color.clear.frame(width: 120)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 9)
        .background(
            conn.isBlocked ? DS.danger.opacity(0.07) :
            conn.isSuspicious ? DS.warning.opacity(0.05) :
            (isHovered ? DS.bgElevated : Color.clear)
        )
        .onHover { isHovered = $0 }
        .animation(Motion.fast, value: isHovered)
        .animation(Motion.fast, value: conn.isBlocked)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    @Binding var isOn: Bool
    let color: Color
    @State private var isHovered = false

    var body: some View {
        Button {
            withAnimation(Motion.fast) { isOn.toggle() }
        } label: {
            HStack(spacing: 6) {
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(color)
                }
                Text(label)
                    .font(MSFont.caption)
                    .foregroundColor(isOn ? color : DS.textMuted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isOn ? color.opacity(0.12) : DS.bgElevated)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(isOn ? color.opacity(0.35) : DS.borderSubtle, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}
