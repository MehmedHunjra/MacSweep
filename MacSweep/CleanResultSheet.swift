import SwiftUI

struct CleanResultSheet: View {
    @ObservedObject var cleanEngine: CleanEngine
    @ObservedObject var scanEngine:  ScanEngine
    @Binding var isPresented: Bool
    @State private var animateCheck = false
    @State private var glowPulse    = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer(minLength: 28)

                    // Animated checkmark with glow ring
                    ZStack {
                        Circle()
                            .stroke(DS.brandGreen.opacity(0.25), lineWidth: 2)
                            .frame(width: 130, height: 130)
                            .scaleEffect(glowPulse ? 1.08 : 1.0)
                            .opacity(animateCheck ? 1 : 0)
                            .animation(Motion.breathe, value: glowPulse)

                        Circle()
                            .fill(DS.brandGreen.opacity(0.12))
                            .frame(width: 110, height: 110)
                            .scaleEffect(animateCheck ? 1 : 0.5)
                            .opacity(animateCheck ? 1 : 0)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 58))
                            .foregroundStyle(DS.brandGradient)
                            .scaleEffect(animateCheck ? 1 : 0.3)
                            .opacity(animateCheck ? 1 : 0)
                            .shadow(color: DS.brandGreen.opacity(0.4), radius: 20)
                    }
                    .animation(Motion.spring, value: animateCheck)

                    Text("Cleaning Complete!")
                        .font(MSFont.title)
                        .foregroundColor(DS.textPrimary)
                        .opacity(animateCheck ? 1 : 0)
                        .animation(.easeIn(duration: 0.4).delay(0.3), value: animateCheck)

                    // Stats
                    HStack(spacing: 28) {
                        VStack(spacing: 6) {
                            Text("Cleaned")
                                .font(MSFont.caption)
                                .foregroundColor(DS.textMuted)
                            Text(ByteCountFormatter.string(fromByteCount: cleanEngine.cleanedSize, countStyle: .file))
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(DS.brandGradient)
                        }

                        if let disk = scanEngine.diskInfo {
                            Rectangle()
                                .fill(DS.borderSubtle)
                                .frame(width: 1, height: 40)

                            VStack(spacing: 6) {
                                Text("Free Space")
                                    .font(MSFont.caption)
                                    .foregroundColor(DS.textMuted)
                                Text(disk.freeFormatted)
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundColor(DS.success)
                            }
                        }
                    }
                    .opacity(animateCheck ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.5), value: animateCheck)

                    // Errors if any — scrollable with max height cap
                    if !cleanEngine.errors.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(DS.warning)
                                Text("Some items could not be cleaned:")
                                    .font(MSFont.caption)
                                    .foregroundColor(DS.warning)
                            }
                            ScrollView(showsIndicators: true) {
                                VStack(alignment: .leading, spacing: 3) {
                                    ForEach(cleanEngine.errors, id: \.self) { error in
                                        Text(error)
                                            .font(MSFont.mono)
                                            .foregroundColor(DS.textMuted)
                                            .lineLimit(2)
                                    }
                                }
                            }
                            .frame(maxHeight: 90)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(DS.warning.opacity(0.08))
                                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(DS.warning.opacity(0.2), lineWidth: 1))
                        )
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 8)
                }
            }

            // Done button always pinned at bottom — never cut off
            Divider().opacity(0.5)
            Button {
                isPresented = false
            } label: {
                Text("Done")
                    .font(MSFont.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(DS.brandGradient)
                            .shadow(color: DS.brandGreen.opacity(0.3), radius: 10, y: 4)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
        }
        .frame(width: 460)
        .frame(minHeight: 380, maxHeight: 520)
        .background(DS.bgPanel)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateCheck = true
                DS.playCleanComplete()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    glowPulse = true
                }
            }
        }
    }
}
