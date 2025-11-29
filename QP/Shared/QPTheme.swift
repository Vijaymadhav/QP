import SwiftUI

enum QPTheme {
    static let background = Color.black
    static let accent = Color(red: 0.84, green: 0.11, blue: 0.13)
    static let accentSecondary = Color(red: 0.45, green: 0.05, blue: 0.08)
    static let textPrimary = Color.white
    static let textMuted = Color.white.opacity(0.7)
    
    static let backgroundGradient = LinearGradient(
        colors: [Color.black, Color(red: 0.07, green: 0.07, blue: 0.08), accentSecondary.opacity(0.4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static func cardBackground() -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.13, green: 0.13, blue: 0.15), Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(accent.opacity(0.3), lineWidth: 1.5)
            )
    }
}

struct QPBackgroundView: View {
    var body: some View {
        ZStack {
            QPTheme.backgroundGradient.ignoresSafeArea()
            Circle()
                .stroke(QPTheme.accent.opacity(0.15), lineWidth: 120)
                .scaleEffect(1.4)
                .blur(radius: 80)
        }
    }
}
