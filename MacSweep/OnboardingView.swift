import SwiftUI
import AppKit
import ApplicationServices
import UserNotifications
import CoreLocation

// MARK: - First-Launch Onboarding View

/// A beautiful multi-step onboarding screen shown only on first launch.
/// Guides users through welcome, permissions, and legal acceptance.
/// Saved via @AppStorage so it only appears once.

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var acceptedPrivacy = false
    @State private var acceptedTerms = false
    @State private var showPrivacySheet = false
    @State private var showTermsSheet = false
    @State private var animateIn = false

    // Live permission status
    @State private var hasFDA = false
    @State private var hasAccessibility = false
    @State private var hasNotifications = false
    @State private var hasLocation = false
    @State private var permissionTimer: Timer?

    private let totalPages = 3

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Animated floating orbs
            floatingOrbs

            VStack(spacing: 0) {
                // Page content (scrollable so bottom bar never gets clipped)
                Group {
                    switch currentPage {
                    case 0: welcomePage
                    case 1: permissionsPage
                    case 2: legalPage
                    default: welcomePage
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom bar with dots + button — always visible
                bottomBar
            }
        }
        .frame(minWidth: 700, minHeight: 520)
        .onAppear {
            withAnimation(Motion.slow) {
                animateIn = true
            }
            checkPermissions()
            startPermissionPolling()
        }
        .onDisappear {
            permissionTimer?.invalidate()
            permissionTimer = nil
        }
    }

    // MARK: - Permission Polling

    private func startPermissionPolling() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            checkPermissions()
        }
    }

    private func checkPermissions() {
        // Full Disk Access — try reading a TCC-protected path
        let fdaTestPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mail").path
        let fdaGranted = FileManager.default.isReadableFile(atPath: fdaTestPath)
        if fdaGranted != hasFDA {
            withAnimation(Motion.std) { hasFDA = fdaGranted }
        }

        // Accessibility
        let axGranted = AXIsProcessTrusted()
        if axGranted != hasAccessibility {
            withAnimation(Motion.std) { hasAccessibility = axGranted }
        }

        // Notifications
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let granted = settings.authorizationStatus == .authorized
            DispatchQueue.main.async {
                if granted != hasNotifications {
                    withAnimation(Motion.std) { hasNotifications = granted }
                }
            }
        }

        // Location
        let locStatus = CLLocationManager().authorizationStatus
        let locGranted = locStatus == .authorizedAlways
        if locGranted != hasLocation {
            withAnimation(Motion.std) { hasLocation = locGranted }
        }
    }

    // MARK: - Background colors per page

    private var backgroundColors: [Color] {
        [DS.bg, DS.bgPanel]
    }

    // MARK: - Floating Orbs

    private var floatingOrbs: some View {
        ZStack {
            Circle()
                .fill(DS.brandGreen.opacity(0.08))
                .frame(width: 300, height: 300)
                .offset(x: -150, y: -100)
                .blur(radius: 60)

            Circle()
                .fill(DS.brandTeal.opacity(0.06))
                .frame(width: 250, height: 250)
                .offset(x: 200, y: 150)
                .blur(radius: 50)
        }
        .opacity(animateIn ? 1 : 0)
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                Spacer(minLength: 24)

                // App icon
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: DS.brandGreen.opacity(0.4), radius: 16, y: 6)
                    .scaleEffect(animateIn ? 1 : 0.5)
                    .opacity(animateIn ? 1 : 0)
                    .animation(Motion.spring, value: animateIn)

                Text("Welcome to MacSweep")
                    .font(MSFont.title)
                    .foregroundColor(DS.textPrimary)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(Motion.std.delay(0.15), value: animateIn)

                Text("Your all-in-one Mac cleaner and optimizer.\nKeep your Mac fast, clean, and clutter-free.")
                    .font(MSFont.body)
                    .foregroundColor(DS.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(Motion.std.delay(0.25), value: animateIn)

                // Version badge
                Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "3.3")")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(DS.brandGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(DS.brandGreen.opacity(0.12))
                    .clipShape(Capsule())
                    .opacity(animateIn ? 1 : 0)
                    .animation(Motion.std.delay(0.3), value: animateIn)

                // Feature highlights
                VStack(spacing: 8) {
                    featureRow(icon: "xmark.bin.fill",        title: "Deep Clean",           desc: "Remove system junk, caches, and logs",          color: DS.danger)
                    featureRow(icon: "chart.pie.fill",        title: "Space Lens",           desc: "Visualize what's taking up disk space",          color: SectionTheme.theme(for: .spaceLens).glow)
                    featureRow(icon: "shield.lefthalf.filled",title: "Privacy Protection",   desc: "Clear browser data and digital footprints",      color: DS.brandTeal)
                    featureRow(icon: "bolt.fill",             title: "Performance",          desc: "Speed up your Mac with maintenance tools",       color: DS.warning)
                    featureRow(icon: "doc.on.doc.fill",       title: "Duplicate Finder",     desc: "Find and remove duplicate files",                color: SectionTheme.theme(for: .duplicates).glow)
                    featureRow(icon: "memorychip",       title: "Memory Optimizer",     desc: "Free up RAM and monitor processes",              color: SectionTheme.theme(for: .performance).glow)
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 30)
                .animation(Motion.std.delay(0.35), value: animateIn)

                Spacer(minLength: 16)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func featureRow(icon: String, title: String, desc: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MSFont.headline)
                    .foregroundColor(DS.textPrimary)
                Text(desc)
                    .font(MSFont.caption)
                    .foregroundColor(DS.textSecondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundColor(color.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(DS.bgPanel)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(DS.borderSubtle, lineWidth: 1))
    }

    // MARK: - Page 2: Permissions

    private var permissionsPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                Spacer(minLength: 24)

                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [DS.brandGreen, DS.brandTeal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: DS.brandGreen.opacity(0.4), radius: 16, y: 6)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }

                Text("Permissions Setup")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DS.textPrimary)

                Text("MacSweep needs a few permissions to clean\nyour system effectively. Grant them below.")
                    .font(MSFont.body)
                    .foregroundColor(DS.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                // Permission status summary
                HStack(spacing: 16) {
                    permissionStatusPill(granted: hasFDA, label: "Disk Access")
                    permissionStatusPill(granted: hasAccessibility, label: "Accessibility")
                    permissionStatusPill(granted: hasNotifications, label: "Notifications")
                    permissionStatusPill(granted: hasLocation, label: "Location")
                }
                .padding(.horizontal, 40)

                VStack(spacing: 8) {
                    permissionCard(
                        icon: "internaldrive.fill",
                        title: "Full Disk Access",
                        desc: "Required to scan and clean system caches, logs, and application data across your Mac.",
                        color: DS.brandGreen,
                        isGranted: hasFDA,
                        isRequired: true,
                        action: {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
                        }
                    )

                    permissionCard(
                        icon: "hand.point.up.fill",
                        title: "Accessibility",
                        desc: "Optional — used for advanced process management and system monitoring features.",
                        color: DS.warning,
                        isGranted: hasAccessibility,
                        isRequired: false,
                        action: {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                        }
                    )

                    permissionCard(
                        icon: "bell.badge.fill",
                        title: "Notifications",
                        desc: "Optional — get alerts when scans complete or when disk space is low.",
                        color: DS.danger,
                        isGranted: hasNotifications,
                        isRequired: false,
                        action: {
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                                checkPermissions()
                            }
                        }
                    )

                    permissionCard(
                        icon: "location.fill",
                        title: "Location Services",
                        desc: "Optional — used for accurate Wi-Fi network details in the menu bar.",
                        color: DS.brandTeal,
                        isGranted: hasLocation,
                        isRequired: false,
                        action: {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")!)
                        }
                    )
                }
                .padding(.horizontal, 40)

                Text("You can always change permissions later in\nSystem Settings → Privacy & Security")
                    .font(MSFont.caption)
                    .foregroundColor(DS.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)

                Spacer(minLength: 16)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func permissionStatusPill(granted: Bool, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: granted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(granted ? DS.success : DS.textMuted)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(granted ? DS.success : DS.textMuted)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(granted ? DS.success.opacity(0.1) : DS.bgElevated)
        )
        .overlay(
            Capsule()
                .strokeBorder(granted ? DS.success.opacity(0.3) : DS.borderSubtle, lineWidth: 1)
        )
    }

    private func permissionCard(icon: String, title: String, desc: String, color: Color, isGranted: Bool, isRequired: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isGranted ? DS.success.opacity(0.18) : color.opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: isGranted ? "checkmark.shield.fill" : icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isGranted ? DS.success : color)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(MSFont.headline)
                        .foregroundColor(DS.textPrimary)
                    if isRequired {
                        Text("Required")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DS.danger.cornerRadius(3))
                    }
                }
                Text(desc)
                    .font(MSFont.caption)
                    .foregroundColor(DS.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            if isGranted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                    Text("Granted")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(DS.success)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(DS.success.opacity(0.15))
                .clipShape(Capsule())
            } else {
                Button("Grant") { action() }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(color.opacity(0.15))
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(isGranted ? DS.success.opacity(0.04) : DS.bgPanel)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isGranted ? DS.success.opacity(0.25) : DS.borderSubtle, lineWidth: 1)
        )
        .animation(Motion.std, value: isGranted)
    }

    // MARK: - Page 3: Legal Acceptance

    private var legalPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                Spacer(minLength: 24)

                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [DS.brandTeal, DS.brandGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: DS.brandTeal.opacity(0.4), radius: 16, y: 6)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }

                Text("Privacy & Terms")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DS.textPrimary)

                Text("Please review and accept our policies\nbefore using MacSweep.")
                    .font(MSFont.body)
                    .foregroundColor(DS.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                VStack(spacing: 10) {
                    // Privacy Policy checkbox
                    legalCheckItem(
                        checked: $acceptedPrivacy,
                        title: "Privacy Policy",
                        desc: "No data collection, no telemetry, no tracking — everything stays on your Mac.",
                        icon: "hand.raised.fill",
                        color: DS.brandGreen,
                        onReadMore: { showPrivacySheet = true }
                    )

                    // Terms of Service checkbox
                    legalCheckItem(
                        checked: $acceptedTerms,
                        title: "Terms of Service",
                        desc: "You are responsible for any files you choose to remove. MacSweep always shows a review list and confirmation before deleting.",
                        icon: "doc.text.fill",
                        color: DS.brandTeal,
                        onReadMore: { showTermsSheet = true }
                    )
                }
                .padding(.horizontal, 40)

                // Important disclaimer
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DS.warning)
                        .font(.system(size: 14))
                    Text("MacSweep permanently deletes files at your direction. Always review items before cleaning. We recommend regular backups.")
                        .font(MSFont.caption)
                        .foregroundColor(DS.textSecondary)
                        .lineSpacing(3)
                }
                .padding(14)
                .background(DS.warning.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(DS.warning.opacity(0.25), lineWidth: 1))
                .padding(.horizontal, 40)

                Spacer(minLength: 16)
            }
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showPrivacySheet) {
            LegalSheet(type: .privacy)
        }
        .sheet(isPresented: $showTermsSheet) {
            LegalSheet(type: .terms)
        }
    }

    private func legalCheckItem(checked: Binding<Bool>, title: String, desc: String, icon: String, color: Color, onReadMore: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            // Checkbox
            Button {
                withAnimation(Motion.fast) {
                    checked.wrappedValue.toggle()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(checked.wrappedValue ? color : DS.bgElevated)
                        .frame(width: 24, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(checked.wrappedValue ? color : DS.borderMid, lineWidth: 1.5)
                        )

                    if checked.wrappedValue {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(.plain)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(MSFont.headline)
                        .foregroundColor(DS.textPrimary)
                    Button("Read Full →") { onReadMore() }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(color)
                        .buttonStyle(.plain)
                }
                Text(desc)
                    .font(MSFont.caption)
                    .foregroundColor(DS.textMuted)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .background(checked.wrappedValue ? color.opacity(0.08) : DS.bgPanel)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(checked.wrappedValue ? color.opacity(0.35) : DS.borderSubtle, lineWidth: 1)
        )
        .animation(Motion.fast, value: checked.wrappedValue)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            // Page indicator dots
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { page in
                    Capsule()
                        .fill(currentPage == page ? DS.brandGreen : DS.textMuted.opacity(0.4))
                        .frame(width: currentPage == page ? 24 : 8, height: 8)
                        .animation(Motion.std, value: currentPage)
                }
            }

            Spacer()

            // Navigation buttons
            HStack(spacing: 12) {
                if currentPage > 0 {
                    Button {
                        withAnimation(Motion.std) {
                            currentPage -= 1
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DS.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    if currentPage < totalPages - 1 {
                        withAnimation(Motion.std) {
                            currentPage += 1
                        }
                    } else {
                        // Final page — complete onboarding
                        completeOnboarding()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(nextButtonTitle)
                            .font(.system(size: 14, weight: .bold))
                        if currentPage < totalPages - 1 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                isGetStartedEnabled
                                    ? LinearGradient(colors: [DS.brandGreen, DS.brandTeal], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [DS.textMuted.opacity(0.3), DS.textMuted.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(currentPage == totalPages - 1 && !isGetStartedEnabled)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
        .background(DS.bgPanel)
    }

    private var nextButtonTitle: String {
        switch currentPage {
        case 0: return "Continue"
        case 1: return "Next"
        case 2: return "Get Started"
        default: return "Continue"
        }
    }

    private var isGetStartedEnabled: Bool {
        acceptedPrivacy && acceptedTerms
    }

    private func completeOnboarding() {
        guard isGetStartedEnabled else { return }
        permissionTimer?.invalidate()
        permissionTimer = nil
        withAnimation(Motion.std) {
            hasCompletedOnboarding = true
        }
    }
}
