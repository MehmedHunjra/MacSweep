import SwiftUI

struct CleanResultSheet: View {
    @ObservedObject var cleanEngine: CleanEngine
    @ObservedObject var scanEngine:  ScanEngine
    @Binding var isPresented: Bool
    @State private var animateCheck = false
    @State private var glowPulse    = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated checkmark with glow ring
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(DS.brandGreen.opacity(0.25), lineWidth: 2)
                    .frame(width: 140, height: 140)
                    .scaleEffect(glowPulse ? 1.08 : 1.0)
                    .opacity(animateCheck ? 1 : 0)
                    .animation(Motion.breathe, value: glowPulse)

                Circle()
                    .fill(DS.brandGreen.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateCheck ? 1 : 0.5)
                    .opacity(animateCheck ? 1 : 0)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
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
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.brandGradient)
                }

                if let disk = scanEngine.diskInfo {
                    Rectangle()
                        .fill(DS.borderSubtle)
                        .frame(width: 1, height: 44)

                    VStack(spacing: 6) {
                        Text("Free Space")
                            .font(MSFont.caption)
                            .foregroundColor(DS.textMuted)
                        Text(disk.freeFormatted)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(DS.success)
                    }
                }
            }
            .opacity(animateCheck ? 1 : 0)
            .animation(.easeIn(duration: 0.4).delay(0.5), value: animateCheck)

            // Errors if any
            if !cleanEngine.errors.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Some items could not be cleaned:")
                        .font(MSFont.caption)
                        .foregroundColor(DS.warning)
                    ForEach(cleanEngine.errors, id: \.self) { error in
                        Text(error)
                            .font(MSFont.mono)
                            .foregroundColor(DS.textMuted)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DS.warning.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(DS.warning.opacity(0.2), lineWidth: 1))
                )
                .frame(maxWidth: 400)
            }

            Spacer()

            Button {
                isPresented = false
            } label: {
                Text("Done")
                    .font(MSFont.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 13)
                    .background(
                        Capsule()
                            .fill(DS.brandGradient)
                            .shadow(color: DS.brandGreen.opacity(0.3), radius: 10, y: 4)
                    )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 32)
        }
        .frame(width: 480, height: 440)
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
