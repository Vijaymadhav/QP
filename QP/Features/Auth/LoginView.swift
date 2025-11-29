import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 32) {
            welcomeLogo
            VStack(spacing: 8) {
                Text("Qouch Potato")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundColor(QPTheme.textPrimary)
                Text("Cinema tastes crafted just for you")
                    .font(.subheadline)
                    .foregroundColor(QPTheme.textMuted)
            }
            .multilineTextAlignment(.center)
            
            VStack(spacing: 24) {
                inputField(title: "Full name", text: $name, isEmail: false)
                inputField(title: "Email", text: $email, isEmail: true)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(QPTheme.accent.opacity(0.4), lineWidth: 1.5)
                    )
            )
            
            if let error = errorMessage {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(QPTheme.accent)
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(QPTheme.textPrimary)
                }
                .padding(12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(16)
            }
            
            Button(action: continueTapped) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Continue")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSubmit ? QPTheme.accent : QPTheme.accent.opacity(0.4))
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .disabled(!canSubmit)
            .shadow(color: QPTheme.accent.opacity(canSubmit ? 0.7 : 0), radius: 20, y: 10)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack(alignment: .bottomTrailing) {
                QPBackgroundView()
                LogoBadgeBackground()
                    .offset(x: 60, y: 80)
            }
            .ignoresSafeArea()
        )
    }
    
    private var welcomeLogo: some View {
        Image("QPLogo")
            .resizable()
            .scaledToFit()
            .frame(height: 160)
            .shadow(color: QPTheme.accent.opacity(0.5), radius: 18, x: 0, y: 15)
            .accessibilityLabel("Qouch Potato logo")
    }
    
    private func inputField(title: String, text: Binding<String>, isEmail: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundColor(QPTheme.textMuted)
                .kerning(1.2)
            TextField(title, text: text)
                .keyboardType(isEmail ? .emailAddress : .default)
                .textInputAutocapitalization(isEmail ? .never : .words)
                .disableAutocorrection(true)
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
                .foregroundColor(QPTheme.textPrimary)
        }
    }
    
    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && email.contains("@")
    }
    
    private func continueTapped() {
        Analytics.shared.log(.loginStarted)
        guard canSubmit else {
            errorMessage = "Please enter your name and a valid email."
            Analytics.shared.log(.loginFailed(reason: "Validation"))
            return
        }
        appState.login(name: name, email: email)
        Analytics.shared.log(.loginCompleted)
    }
}
