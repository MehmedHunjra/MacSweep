import SwiftUI

struct AdwareCleanerView: View {
    @ObservedObject var engine: AdwareCleanEngine
    @EnvironmentObject var navManager: NavigationManager

    @State private var selectedTypes: Set<AdwareItem.AdwareType> = Set(AdwareItem.AdwareType.allCases)
    @State private var showConfirm = false

    private var theme: SectionTheme { SectionTheme.theme(for: .adwareCleaner) }
    private var selectedItems: [AdwareItem] { engine.items.filter { $0.isSelected } }
    private var suspiciousCount: Int { engine.items.filter { $0.isSuspicious }.count }

    var body: some View {
        VStack(spacing: 0) {
            if engine.isScanning {
                navHeader(title: "Scanning...", subtitle: nil)
                scanningContent
            } else if engine.items.isEmpty && engine.progress == 0 {
                navHeader(title: nil, subtitle: nil)
                landingContent
            } else {
                resultsView
            }
        }
        .background(
            RadialGradient(
                gradient: Gradient(colors: [theme.glow.opacity(0.08), DS.bg]),
                center: .center, startRadius: 40, endRadius: 500
            )
        )
    }

    // MARK: - Navigation Header (reusable)
    private func navHeader(title: String?, subtitle: String?) -> some View {
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

            if let title = title {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MSFont.title2)
                        .foregroundColor(DS.textPrimary)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(MSFont.caption)
                            .foregroundColor(DS.textMuted)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: Landing
    private var landingContent: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(theme.glow.opacity(0.12))
                    .frame(width: 140, height: 140)
                Image(systemName: "ant.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(theme.linearGradient)
                    .shadow(color: theme.glow.opacity(0.5), radius: 20)
            }

            VStack(spacing: 8) {
                Text("Adware & Persistence Cleaner")
                    .font(MSFont.heroTitle)
                    .foregroundColor(DS.textPrimary)
                Text("Scan for adware, unwanted launch agents, daemons\nand suspicious browser extensions.")
                    .font(MSFont.body)
                    .foregroundColor(DS.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // What we scan
            VStack(spacing: 8) {
                ForEach(AdwareItem.AdwareType.allCases, id: \.self) { type in
                    ScanTargetRow(type: type)
                }
            }
            .frame(maxWidth: 400)

            Button {
                engine.scan()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("Scan for Adware")
                        .font(MSFont.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 44)
                .padding(.vertical, 14)
                .background(Capsule().fill(theme.linearGradient))
                .shadow(color: theme.glow.opacity(0.35), radius: 12, y: 4)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 60)
    }

    // MARK: Scanning
    private var scanningContent: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(theme.glow.opacity(0.15), lineWidth: 2)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: CGFloat(engine.progress))
                    .stroke(theme.glow, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(Motion.std, value: engine.progress)

                Image(systemName: "ant.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(theme.linearGradient)
                    .shadow(color: theme.glow.opacity(0.4), radius: 12)
            }

            VStack(spacing: 10) {
                Text("Scanning Persistence Locations...")
                    .font(MSFont.title)
                    .foregroundColor(DS.textPrimary)
                Text("Checking LaunchAgents, Daemons, Login Items & Extensions")
                    .font(MSFont.body)
                    .foregroundColor(DS.textSecondary)
                    .multilineTextAlignment(.center)

                if !engine.items.isEmpty {
                    let sus = engine.items.filter { $0.isSuspicious }.count
                    Text("\(engine.items.count) item(s) found\(sus > 0 ? " · \(sus) suspicious" : "")")
                        .font(MSFont.caption)
                        .foregroundColor(sus > 0 ? DS.warning : DS.success)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    // MARK: Results
    private var resultsView: some View {
        VStack(spacing: 0) {
            // Header with nav buttons inline
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

                VStack(alignment: .leading, spacing: 3) {
                    Text("Scan Results")
                        .font(MSFont.title2)
                        .foregroundColor(DS.textPrimary)
                    if engine.items.isEmpty {
                        Label("No persistence items found", systemImage: "checkmark.shield.fill")
                            .font(MSFont.body)
                            .foregroundColor(DS.success)
                    } else if suspiciousCount > 0 {
                        Label("\(engine.items.count) items found · \(suspiciousCount) suspicious", systemImage: "exclamationmark.triangle.fill")
                            .font(MSFont.body)
                            .foregroundColor(DS.warning)
                    } else {
                        Label("\(engine.items.count) items found · all look clean", systemImage: "checkmark.shield.fill")
                            .font(MSFont.body)
                            .foregroundColor(DS.success)
                    }
                }
                Spacer()
                HStack(spacing: 10) {
                    // Select All / Deselect All
                    if !engine.items.isEmpty {
                        let allSelected = engine.items.allSatisfy { $0.isSelected }
                        Button {
                            let newValue = !allSelected
                            for i in engine.items.indices {
                                engine.items[i].isSelected = newValue
                            }
                        } label: {
                            Text(allSelected ? "Deselect All" : "Select All")
                                .font(MSFont.caption)
                                .foregroundColor(DS.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 6).fill(DS.bgElevated))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        engine.items = []
                        withAnimation(Motion.std) { engine.progress = 0 }
                    } label: {
                        Text("New Scan")
                            .font(MSFont.headline)
                            .foregroundColor(DS.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(DS.bgElevated))
                    }
                    .buttonStyle(.plain)

                    if !selectedItems.isEmpty {
                        Button {
                            showConfirm = true
                        } label: {
                            Text("Remove Selected (\(selectedItems.count))")
                                .font(MSFont.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(DS.danger))
                        }
                        .buttonStyle(.plain)
                        .alert("Remove \(selectedItems.count) item(s)?", isPresented: $showConfirm) {
                            Button("Remove", role: .destructive) { engine.removeSelected() }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("This will permanently delete the selected persistence items.")
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(DS.bgPanel)
            .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1), alignment: .bottom)

            if engine.items.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 64))
                        .foregroundColor(DS.success)
                        .shadow(color: DS.success.opacity(0.4), radius: 20)
                    Text("No persistence items found")
                        .font(MSFont.title2)
                        .foregroundColor(DS.textPrimary)
                    Text("No launch agents, daemons, login items or extensions were detected.")
                        .font(MSFont.body)
                        .foregroundColor(DS.textSecondary)
                }
                Spacer()
            } else {
                // Group by type
                let grouped = Dictionary(grouping: engine.items, by: { $0.type })

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(AdwareItem.AdwareType.allCases, id: \.self) { type in
                            if let groupItems = grouped[type], !groupItems.isEmpty {
                                AdwareGroupSection(type: type, items: groupItems, engine: engine)
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(DS.bg)
    }
}

// MARK: - Adware Group Section

private struct AdwareGroupSection: View {
    let type: AdwareItem.AdwareType
    let items: [AdwareItem]
    @ObservedObject var engine: AdwareCleanEngine

    private var theme: SectionTheme { SectionTheme.theme(for: .adwareCleaner) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack(spacing: 10) {
                Image(systemName: items[0].typeIcon)
                    .font(.system(size: 13))
                    .foregroundColor(theme.glow)
                Text(type.rawValue)
                    .font(MSFont.headline)
                    .foregroundColor(DS.textSecondary)
                Spacer()
                Text("\(items.count)")
                    .font(MSFont.mono)
                    .foregroundColor(theme.glow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(theme.glow.opacity(0.15)))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DS.bgElevated)

            // Items
            ForEach(items) { item in
                let idx = engine.items.firstIndex(where: { $0.id == item.id })
                if let i = idx {
                    AdwareItemRow(item: item, isSelected: engine.items[i].isSelected) {
                        engine.items[i].isSelected.toggle()
                    } onRemove: {
                        engine.remove(engine.items[i])
                    } onReveal: {
                        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.path)])
                    }
                    if item.id != items.last?.id {
                        Divider().background(DS.borderSubtle)
                    }
                }
            }
        }
        .background(DS.bgPanel)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.borderSubtle, lineWidth: 1))
    }
}

// MARK: - Adware Item Row

private struct AdwareItemRow: View {
    let item: AdwareItem
    let isSelected: Bool
    let onToggle: () -> Void
    let onRemove: () -> Void
    let onReveal: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? SectionTheme.theme(for: .adwareCleaner).glow : DS.textMuted)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(MSFont.body)
                        .foregroundColor(item.isSuspicious ? DS.warning : DS.textPrimary)
                    if item.isSuspicious {
                        Text("SUSPICIOUS")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(DS.warning)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(DS.warning.opacity(0.18)))
                    }
                }
                Text(item.path)
                    .font(MSFont.mono)
                    .foregroundColor(DS.textMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            if isHovered {
                HStack(spacing: 6) {
                    Button(action: onReveal) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 11))
                            Text("Reveal")
                                .font(MSFont.caption)
                        }
                        .foregroundColor(DS.brandTeal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(DS.brandTeal.opacity(0.12)))
                    }
                    .buttonStyle(.plain)

                    Button(action: onRemove) {
                        Text("Remove")
                            .font(MSFont.caption)
                            .foregroundColor(DS.danger)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(DS.danger.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isHovered ? DS.bgElevated : Color.clear)
        .onHover { isHovered = $0 }
        .animation(Motion.fast, value: isHovered)
    }
}

// MARK: - Scan Target Row

private struct ScanTargetRow: View {
    let type: AdwareItem.AdwareType

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type == .launchAgent ? "gearshape.2.fill" :
                             type == .launchDaemon ? "server.rack" :
                             type == .loginItem ? "arrow.right.circle.fill" : "puzzlepiece.extension.fill")
                .font(.system(size: 14))
                .foregroundColor(SectionTheme.theme(for: .adwareCleaner).glow)
                .frame(width: 24)

            Text(type.rawValue)
                .font(MSFont.body)
                .foregroundColor(DS.textSecondary)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundColor(DS.success)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DS.bgPanel)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.borderSubtle, lineWidth: 1))
        )
    }
}

// MARK: AdwareItem.AdwareType CaseIterable
extension AdwareItem.AdwareType: CaseIterable {
    static var allCases: [AdwareItem.AdwareType] {
        [.launchAgent, .launchDaemon, .loginItem, .browserExt]
    }
}
