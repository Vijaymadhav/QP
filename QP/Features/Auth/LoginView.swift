import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Welcome to Qouch Potato")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            Text("Sign in to get personalized recommendations.")
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                TextField("Full name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
            
            Button(action: continueTapped) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSubmit ? Color.white : Color.white.opacity(0.3))
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
            .disabled(!canSubmit)
            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }
    
    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && email.contains("@")
    }
    
    private func continueTapped() {
        guard canSubmit else {
            errorMessage = "Please enter your name and a valid email."
            return
        }
        appState.login(name: name, email: email)
    }
}
