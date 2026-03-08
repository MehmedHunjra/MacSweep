# MacSweep

**MacSweep** is a free, open-source Mac cleaner and system optimizer built entirely in SwiftUI. It gives you full control over your Mac's storage, performance, security, and privacy — with no subscriptions, no tracking, and no hidden fees.

---

## Features

### Cleaning
- **Smart Scan** — one-click scan that finds junk across all categories
- **System Junk** — caches, logs, temp files, mail attachments
- **Large Files** — find and remove files taking up the most space
- **Duplicates** — detect and remove duplicate files
- **Browser Privacy** — clear cookies, caches, and history from Chrome, Safari, Firefox, Brave, and Edge
- **App Leftovers** — remove leftover data from uninstalled apps
- **Dev Cleaner** — Xcode DerivedData, simulator caches, npm/pip/gem packages, IDE caches

### Performance
- **Memory Optimizer** — inspect top memory consumers and free inactive RAM
- **Startup Optimizer** — manage login items, launch agents, and launch daemons
- **Maintenance** — run daily/weekly/monthly macOS maintenance scripts, repair permissions, clear font/launch caches

### Security
- **Malware Scanner** — heuristic scan for suspicious files and scripts
- **Real-Time Protection** — FSEvents-based live monitoring of Downloads, Desktop, and Documents
- **Adware Cleaner** — detect and remove browser extensions, login items, and launch agents associated with adware
- **Ransomware Guard** — real-time file-change monitoring with encryption rate detection
- **Network Monitor** — live view of all active TCP connections with suspicious port detection
- **Quarantine Manager** — safely quarantine and restore flagged threats
- **System Integrity** — scan launch agents, daemons, hosts file, SSH config, kernel and system extensions

### Privacy
- **Privacy Cleaner** — remove recent documents, clipboard history, and browser traces
- **Privacy & Protection** — scan and optionally clear browser login data, autofill, and download history

### Tools
- **Space Lens** — interactive disk-usage treemap to find what is using space
- **Applications Manager** — view all installed apps, last-used dates, sizes, and uninstall leftovers
- **Dashboard** — live CPU, RAM, disk, and network overview

### Menu Bar
- Always-on menu bar icon with live CPU/RAM/network stats
- Quick Actions panel — 24 one-tap actions (Empty Trash, Free RAM, Flush DNS, and more)
- All Tools grid — launch any tool directly from the menu bar

---

## Requirements

- macOS 13 Ventura or later
- Xcode 15 or later
- Swift 5.9+

---

## Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/MacSweep.git
   cd MacSweep
   ```

2. Open the project in Xcode:
   ```bash
   open MacSweep.xcodeproj
   ```

3. Select the **MacSweep** scheme, choose **My Mac** as the destination, and press **Run** (⌘R).

No third-party dependencies. No Swift Package Manager packages required.

---

## Project Structure

```
MacSweep/
├── MacSweepApp.swift          # App entry point, MenuBarExtra, MenuBarLabel
├── ContentView.swift          # Main window layout, section routing
├── Models.swift               # AppSettings, AppSection enum, ScanItem, design system (DS)
├── NavigationManager.swift    # Navigation history and routing
├── ScanEngine.swift           # Disk, CPU, RAM, network stats engine
├── CleanEngine.swift          # File deletion and cleaning engine
├── SecurityEngine.swift       # Malware, Adware, Network, Ransomware, Realtime, Integrity engines
│
├── SmartScanView.swift        # Smart Scan UI
├── SystemJunkView.swift       # System Junk UI
├── LargeFilesView.swift       # Large Files UI
├── DuplicateFinderView.swift  # Duplicate Finder UI
├── BrowserCleanerView.swift   # Browser Privacy UI
├── AppLeftoversView.swift     # App Leftovers UI
├── DevCleanerView.swift       # Dev Cleaner UI (+ DevCleanEngine)
│
├── MemoryOptimizerView.swift  # Memory Optimizer UI
├── PerformanceManagerView.swift # Startup Optimizer UI
├── MaintenanceView.swift      # Maintenance UI
│
├── MalwareScannerView.swift   # Malware Scanner UI
├── RealtimeProtectionView.swift # Real-Time Protection UI
├── AdwareCleanerView.swift    # Adware Cleaner UI
├── RansomwareGuardView.swift  # Ransomware Guard UI
├── NetworkMonitorView.swift   # Network Monitor UI
├── QuarantineManagerView.swift # Quarantine Manager UI
├── IntegrityMonitorView.swift # System Integrity UI
│
├── PrivacyView.swift          # Privacy Cleaner UI
├── ProtectionManagerView.swift # Privacy & Protection UI
│
├── SpaceLensView.swift        # Space Lens disk treemap UI
├── ApplicationsManagerView.swift # Applications Manager UI
├── DashboardView.swift        # Dashboard UI
│
├── SidebarView.swift          # Sidebar navigation
├── MenuBarView.swift          # Menu bar popup (Overview, Apps, Actions tabs)
├── SettingsView.swift         # Settings UI
└── Assets.xcassets/           # Icons, brand assets
```

---

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a pull request.

---

## License

MacSweep is released under the **MIT License**. See [LICENSE](LICENSE) for details.

---

## Disclaimer

MacSweep performs real system operations (file deletion, DNS flush, memory purge, etc.). Always review what will be removed before confirming any cleaning operation. The authors are not responsible for data loss caused by misuse.
