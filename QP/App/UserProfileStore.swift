import Foundation

struct StoredUserData: Codable {
    var profile: UserProfile
    var onboardingComplete: Bool
    var watchlist: [Movie]
    var likedMovies: [Movie]
}

final class UserProfileStore {
    static let shared = UserProfileStore()
    private let fileManager = FileManager.default
    private let directory: URL
    
    private init() {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        directory = base.appendingPathComponent("QP", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
    
    func load(for userId: String) -> StoredUserData? {
        let url = directory.appendingPathComponent("user_\(userId).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(StoredUserData.self, from: data)
    }
    
    func save(_ data: StoredUserData, for userId: String) {
        let url = directory.appendingPathComponent("user_\(userId).json")
        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: url, options: .atomic)
        }
    }
    
    func delete(for userId: String) {
        let url = directory.appendingPathComponent("user_\(userId).json")
        try? fileManager.removeItem(at: url)
    }
}
