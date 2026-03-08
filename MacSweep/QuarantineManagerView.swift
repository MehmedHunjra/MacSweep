import SwiftUI

struct QuarantineManagerView: View {
    @ObservedObject var quarantine: QuarantineManager
    @EnvironmentObject var navManager: NavigationManager

    @State private var selectedItem: QuarantineItem? = nil
    @State private var showDeleteConfirm = false
    @State private var showRestoreConfirm = false
    @State private var searchText = ""

    private var theme: SectionTheme { SectionTheme.theme(for: .quarantine) }

    private var filteredItems: [QuarantineItem] {
        if searchText.isEmpty { return quarantine.items }
        return quarantine.items.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.threatName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var totalSizeFormatted: String {
        let total = quarantine.items.compactMap { item -> Int64? in
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: item.quarantinePath),
                  let size = attrs[.size] as? Int64 else { return nil }
            return size
        }.reduce(0, +)
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            if quarantine.items.isEmpty {
                emptyState
            } else {
                HStack(spacing: 0) {
                    // Item list
                    itemList
                        .frame(maxWidth: .infinity)

                    Divider().background(DS.borderSubtle)

                    // Detail panel
                    detailPanel
                        .frame(width: 300)
                }
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
                Text("Quarantine Manager")
                    .font(MSFont.title2)
                    .foregroundColor(DS.textPrimary)
                if quarantine.items.isEmpty {
                    Text("No quarantined items")
                        .font(MSFont.caption)
                        .foregroundColor(DS.textMuted)
                } else {
                    Text("\(quarantine.items.count) item(s) · \(totalSizeFormatted)")
                        .font(MSFont.caption)
                        .foregroundColor(DS.textMuted)
                }
            }

            Spacer()

            if !quarantine.items.isEmpty {
                Button {
                    showDeleteConfirm = true
                } label: {
                    Text("Delete All")
                        .font(MSFont.headline)
                        .foregroundColor(DS.danger)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(DS.danger.opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.danger.opacity(0.25), lineWidth: 1)))
                }
                .buttonStyle(.plain)
                .alert("Delete all quarantined files?", isPresented: $showDeleteConfirm) {
                    Button("Delete All", role: .destructive) {
                        for item in quarantine.items { try? quarantine.delete(item) }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This will permanently delete all \(quarantine.items.count) quarantined files. This cannot be undone.")
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(DS.bgPanel)
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
                Image(systemName: "lock.doc.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(theme.linearGradient)
                    .shadow(color: theme.glow.opacity(0.4), radius: 16)
            }
            VStack(spacing: 8) {
                Text("Quarantine is Empty")
                    .font(MSFont.title)
                    .foregroundColor(DS.textPrimary)
                Text("Files quarantined from Malware Scanner will\nappear here, isolated from the rest of your system.")
                    .font(MSFont.body)
                    .foregroundColor(DS.textSecondary)
                    .multilineTextAlignment(.center)
            }
            // Quarantine directory info
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([QuarantineManager.quarantineDir])
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                    Text("Show in Finder")
                }
                .font(MSFont.caption)
                .foregroundColor(DS.textMuted)
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: Item List
    private var itemList: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundColor(DS.textMuted)
                TextField("Search quarantine...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(MSFont.body)
                    .foregroundColor(DS.textPrimary)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DS.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(DS.bgElevated)
            .overlay(Rectangle().fill(DS.borderSubtle).frame(height: 1), alignment: .bottom)

            if filteredItems.isEmpty {
                Spacer()
                Text("No results for \"\(searchText)\"")
                    .font(MSFont.body)
                    .foregroundColor(DS.textMuted)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredItems) { item in
                            QuarantineRow(item: item, isSelected: selectedItem?.id == item.id) {
                                withAnimation(Motion.fast) { selectedItem = item }
                            }
                            Divider().background(DS.borderSubtle.opacity(0.5))
                        }
                    }
                }
            }
        }
    }

    // MARK: Detail Panel
    private var detailPanel: some View {
        Group {
            if let item = selectedItem {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Icon + name
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(item.severityEnum.color.opacity(0.12))
                                    .frame(width: 72, height: 72)
                                Image(systemName: "lock.doc.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(item.severityEnum.color)
                            }
                            Text(item.name)
                                .font(MSFont.headline)
                                .foregroundColor(DS.textPrimary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)

                        // Info rows
                        VStack(spacing: 0) {
                            InfoDetailRow(label: "Threat", value: item.threatName)
                            Divider().background(DS.borderSubtle)
                            InfoDetailRow(label: "Severity", value: item.severity, valueColor: item.severityEnum.color)
                            Divider().background(DS.borderSubtle)
                            InfoDetailRow(label: "Size", value: item.sizeFormatted)
                            Divider().background(DS.borderSubtle)
                            InfoDetailRow(label: "Quarantined", value: item.dateFormatted)
                            Divider().background(DS.borderSubtle)
                            InfoDetailRow(label: "Original Path", value: item.originalPath, small: true)
                        }
                        .background(RoundedRectangle(cornerRadius: 10)
                            .fill(DS.bgPanel)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.borderSubtle, lineWidth: 1)))
                        .padding(.horizontal, 16)

                        // Actions
                        VStack(spacing: 8) {
                            Button {
                                showRestoreConfirm = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.uturn.backward.circle.fill")
                                    Text("Restore to Original Location")
                                        .font(MSFont.headline)
                                }
                                .foregroundColor(DS.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(RoundedRectangle(cornerRadius: 8)
                                    .fill(DS.bgElevated)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.borderMid, lineWidth: 1)))
                            }
                            .buttonStyle(.plain)
                            .alert("Restore this file?", isPresented: $showRestoreConfirm) {
                                Button("Restore", role: .destructive) {
                                    try? quarantine.restore(item)
                                    selectedItem = nil
                                }
                                Button("Cancel", role: .cancel) { }
                            } message: {
                                Text("This file may still be dangerous. Only restore if you are certain it is safe.")
                            }

                            Button {
                                try? quarantine.delete(item)
                                selectedItem = nil
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash.fill")
                                    Text("Delete Permanently")
                                        .font(MSFont.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(RoundedRectangle(cornerRadius: 8).fill(DS.danger))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
                .background(DS.bg)
            } else {
                VStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "hand.point.left.fill")
                            .font(.system(size: 28))
                            .foregroundColor(DS.textMuted)
                        Text("Select an item")
                            .font(MSFont.body)
                            .foregroundColor(DS.textMuted)
                    }
                    Spacer()
                }
                .background(DS.bg)
            }
        }
    }
}

// MARK: - Quarantine Row

private struct QuarantineRow: View {
    let item: QuarantineItem
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.severityEnum.color.opacity(0.14))
                        .frame(width: 36, height: 36)
                    Image(systemName: "lock.doc.fill")
                        .font(.system(size: 15))
                        .foregroundColor(item.severityEnum.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(MSFont.body)
                        .foregroundColor(DS.textPrimary)
                        .lineLimit(1)
                    Text(item.threatName)
                        .font(MSFont.caption)
                        .foregroundColor(item.severityEnum.color)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(item.sizeFormatted)
                        .font(MSFont.mono)
                        .foregroundColor(DS.textMuted)
                    Text(item.severity)
                        .font(MSFont.mono)
                        .foregroundColor(item.severityEnum.color)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ? SectionTheme.theme(for: .quarantine).glow.opacity(0.10) :
                (isHovered ? DS.bgElevated : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .overlay(
            isSelected ? Rectangle()
                .fill(SectionTheme.theme(for: .quarantine).glow)
                .frame(width: 3)
                .animation(Motion.fast, value: isSelected) : nil,
            alignment: .leading
        )
        .animation(Motion.fast, value: isSelected)
    }
}

// MARK: - Info Detail Row

private struct InfoDetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = DS.textSecondary
    var small: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(MSFont.mono)
                .foregroundColor(DS.textMuted)
            Text(value)
                .font(small ? MSFont.mono : MSFont.body)
                .foregroundColor(valueColor)
                .lineLimit(small ? 2 : 1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
