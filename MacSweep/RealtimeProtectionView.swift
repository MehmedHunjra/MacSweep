import SwiftUI

struct RealtimeProtectionView: View {
    @ObservedObject var engine: RealtimeProtectionEngine
    @EnvironmentObject var navManager: NavigationManager

    private var theme: SectionTheme { SectionTheme.theme(for: .realtimeProtect) }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar

            // Content
            HStack(spacing: 0) {
                // Left: Status + Stats
                leftPanel
                    .frame(width: 280)

                Divider().background(DS.borderSubtle)

                // Right: Activity Log
                activityLogPanel
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
                Text("Real-Time Protection")
                    .font(MSFont.title2)
                    .foregroundColor(DS.textPrimary)
                Text(engine.isEnabled ? "Actively monitoring your Mac" : "Protection is disabled")
                    .font(MSFont.caption)
                    .foregroundColor(engine.isEnabled ? DS.success : DS.textMuted)
            }

            Spacer()

            // Toggle
            Button {
                if engine.isEnabled {
                    engine.disable()
                } else {
                    engine.enable()
                }
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(engine.isEnabled ? DS.success : DS.textMuted)
                        .frame(width: 8, height: 8)
                        .shadow(color: engine.isEnabled ? DS.success.opacity(0.6) : .clear, radius: 4)
                    Text(engine.isEnabled ? "Disable" : "Enable Protection")
                        .font(MSFont.headline)
                        .foregroundColor(engine.isEnabled ? DS.danger : DS.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(engine.isEnabled ? DS.danger.opacity(0.12) : theme.glow.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(engine.isEnabled ? DS.danger.opacity(0.3) : theme.glow.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .animation(Motion.fast, value: engine.isEnabled)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(DS.bgPanel)
        .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1), alignment: .bottom)
    }

    // MARK: Left Panel
    private var leftPanel: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {

                // Big status shield
                ZStack {
                    Circle()
                        .fill(engine.isEnabled ? theme.glow.opacity(0.10) : DS.textMuted.opacity(0.08))
                        .frame(width: 120, height: 120)

                    Image(systemName: engine.isEnabled ? "shield.fill" : "shield.slash.fill")
                        .font(.system(size: 48))
                        .foregroundColor(engine.isEnabled ? theme.glow : DS.textMuted)
                        .shadow(color: engine.isEnabled ? theme.glow.opacity(0.4) : .clear, radius: 16)
                }
                .padding(.top, 24)
                .animation(Motion.std, value: engine.isEnabled)

                Text(engine.isEnabled ? "Protected" : "Unprotected")
                    .font(MSFont.headline)
                    .foregroundColor(engine.isEnabled ? theme.glow : DS.textMuted)

                // Stats cards
                VStack(spacing: 10) {
                    StatCard(icon: "doc.text.magnifyingglass", label: "Files Scanned", value: "\(engine.filesScanned)", color: theme.glow)
                    StatCard(icon: "shield.slash", label: "Threats Blocked", value: "\(engine.threatsBlocked)", color: DS.danger)
                }
                .padding(.horizontal, 16)

                // Feature list
                VStack(spacing: 0) {
                    FeatureRow(icon: "doc.fill", label: "File Scan on Open", enabled: engine.isEnabled)
                    Divider().background(DS.borderSubtle)
                    FeatureRow(icon: "network", label: "Download Protection", enabled: engine.isEnabled)
                    Divider().background(DS.borderSubtle)
                    FeatureRow(icon: "link", label: "Malicious URL Block", enabled: engine.isEnabled)
                    Divider().background(DS.borderSubtle)
                    FeatureRow(icon: "gearshape.2.fill", label: "LaunchAgent Watch", enabled: engine.isEnabled)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DS.bgPanel)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.borderSubtle, lineWidth: 1))
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .background(DS.bg)
    }

    // MARK: Activity Log
    private var activityLogPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Activity Log")
                    .font(MSFont.headline)
                    .foregroundColor(DS.textPrimary)
                Spacer()
                Button {
                    engine.clearLog()
                } label: {
                    Text("Clear")
                        .font(MSFont.caption)
                        .foregroundColor(DS.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(DS.bgPanel)
            .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1), alignment: .bottom)

            if engine.activityLog.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 36))
                        .foregroundColor(DS.textMuted)
                    Text(engine.isEnabled ? "Monitoring activity..." : "Enable protection to start logging")
                        .font(MSFont.body)
                        .foregroundColor(DS.textMuted)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(engine.activityLog) { entry in
                            LogEntryRow(entry: entry)
                            Divider().background(DS.borderSubtle.opacity(0.5))
                        }
                    }
                }
            }
        }
        .background(DS.bg)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 32)

            Text(label)
                .font(MSFont.body)
                .foregroundColor(DS.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(DS.bgPanel)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.borderSubtle, lineWidth: 1))
        )
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let label: String
    let enabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(enabled ? DS.success : DS.textMuted)
                .frame(width: 20)

            Text(label)
                .font(MSFont.body)
                .foregroundColor(DS.textSecondary)

            Spacer()

            Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(enabled ? DS.success : DS.textMuted)
                .font(.system(size: 13))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .animation(Motion.fast, value: enabled)
    }
}

// MARK: - Log Entry Row

private struct LogEntryRow: View {
    let entry: RealtimeProtectionEngine.ActivityLogEntry

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.level.icon)
                .font(.system(size: 11))
                .foregroundColor(entry.level.color)
                .frame(width: 16)

            Text(entry.message)
                .font(MSFont.mono)
                .foregroundColor(DS.textSecondary)
                .lineLimit(1)

            Spacer()

            Text(entry.timeFormatted)
                .font(MSFont.mono)
                .foregroundColor(DS.textMuted)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 7)
    }
}
