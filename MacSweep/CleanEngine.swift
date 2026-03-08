import Foundation

@MainActor
class CleanEngine: ObservableObject {

    @Published var isCleaning    = false
    @Published var cleanProgress = 0.0
    @Published var currentPath   = ""
    @Published var cleanedSize   : Int64 = 0
    @Published var cleanComplete = false
    @Published var errors        : [String] = []

    private let fm = FileManager.default

    private func removeItemSafely(at url: URL) throws {
        do {
            try fm.trashItem(at: url, resultingItemURL: nil)
        } catch {
            try fm.removeItem(at: url)
        }
    }

    func clean(items: [ScanItem]) async {
        let toDelete = items.filter(\.isSelected)
        guard !toDelete.isEmpty else { return }

        isCleaning    = true
        cleanComplete = false
        cleanedSize   = 0
        cleanProgress = 0
        errors        = []

        let total = Double(toDelete.count)

        for (index, item) in toDelete.enumerated() {
            currentPath = item.path

            if !fm.fileExists(atPath: item.path) {
                cleanProgress = Double(index + 1) / total
                continue
            }

            do {
                let url = URL(fileURLWithPath: item.path)
                try removeItemSafely(at: url)
                cleanedSize += item.size
            } catch {
                errors.append("\(item.name): \(error.localizedDescription)")
            }

            cleanProgress = Double(index + 1) / total
        }

        isCleaning    = false
        cleanComplete = true
        currentPath   = ""
    }
}
