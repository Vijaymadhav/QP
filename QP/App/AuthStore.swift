import Foundation

struct AuthSession: Codable, Equatable {
    let id: String
    let name: String
    let email: String
}

final class AuthStore {
    static let shared = AuthStore()
    private let key = "qp.auth.session"
    private let defaults = UserDefaults.standard
    
    private(set) var currentSession: AuthSession?
    
    private init() {
        if let data = defaults.data(forKey: key),
           let session = try? JSONDecoder().decode(AuthSession.self, from: data) {
            currentSession = session
        }
    }
    
    @discardableResult
    func login(name: String, email: String) -> AuthSession {
        let session = AuthSession(id: UUID().uuidString, name: name.trimmingCharacters(in: .whitespacesAndNewlines), email: email.lowercased())
        save(session)
        return session
    }
    
    func logout() {
        defaults.removeObject(forKey: key)
        currentSession = nil
    }
    
    private func save(_ session: AuthSession) {
        currentSession = session
        if let data = try? JSONEncoder().encode(session) {
            defaults.set(data, forKey: key)
        }
    }
}
