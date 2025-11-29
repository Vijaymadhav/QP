import SwiftUI

final class AppState: ObservableObject {
    @Published private(set) var authSession: AuthSession?
    @Published var isOnboarded: Bool = false {
        didSet { persistUserState() }
    }
    @Published var userProfile = UserProfile() {
        didSet { persistUserState() }
    }
    @Published var watchlist: [Movie] = [] {
        didSet { persistUserState() }
    }
    @Published var likedMovies: [Movie] = [] {
        didSet { persistUserState() }
    }
    
    let vectorStore: any MovieVectorStore = MovieVectorStoreFactory.make()
    private var isRestoringState = false
    
    init() {
        PosterDiskCache.shared.bootstrapBundledThumbnails()
        self.authSession = AuthStore.shared.currentSession
        restoreUserState()
    }
    
    func login(name: String, email: String) {
        let session = AuthStore.shared.login(name: name, email: email)
        authSession = session
        restoreUserState()
    }
    
    func completeOnboarding() {
        isOnboarded = true
    }
    
    func logout() {
        guard authSession != nil else { return }
        AuthStore.shared.logout()
        isRestoringState = true
        authSession = nil
        userProfile = UserProfile()
        watchlist = []
        likedMovies = []
        isOnboarded = false
        isRestoringState = false
    }
    
    private func restoreUserState() {
        guard let session = authSession,
              let stored = UserProfileStore.shared.load(for: session.id) else {
            isRestoringState = true
            userProfile = UserProfile()
            watchlist = []
            likedMovies = []
            isOnboarded = false
            isRestoringState = false
            return
        }
        
        isRestoringState = true
        userProfile = stored.profile
        watchlist = stored.watchlist
        likedMovies = stored.likedMovies
        isOnboarded = stored.onboardingComplete
        isRestoringState = false
    }
    
    private func persistUserState() {
        guard !isRestoringState, let session = authSession else { return }
        let stored = StoredUserData(
            profile: userProfile,
            onboardingComplete: isOnboarded,
            watchlist: watchlist,
            likedMovies: likedMovies
        )
        UserProfileStore.shared.save(stored, for: session.id)
    }
}


enum Gender: String, CaseIterable, Identifiable, Codable {
    case male = "Male"
    case female = "Female"
    case nonBinary = "Non-binary"
    case preferNotToSay = "Prefer not to say"
    
    var id: String { rawValue }
}

struct UserProfile: Codable {
    var location: String = ""
    var gender: Gender = .preferNotToSay
    var age: Double = 30
    var favoriteMovies: [Movie] = []
}

struct Movie: Identifiable, Codable, Equatable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let runtimeMinutes: Int?
    var tags: [String] = []
    var reasons: [String] = []
    
    var displayRuntime: String {
        guard let runtimeMinutes else { return "" }
        let h = runtimeMinutes / 60
        let m = runtimeMinutes % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
    
    var fullPosterURL: URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }

    var posterCacheKey: String {
        posterPath ?? "demo-\(id)"
    }
}

let demoMovies: [Movie] = [
    Movie(id: 1, title: "Inception",
          overview: "A mind-bending heist through dreams.",
          posterPath: nil, runtimeMinutes: 148),
    Movie(id: 2, title: "Lagaan",
          overview: "Villagers challenge the British to a game of cricket.",
          posterPath: nil, runtimeMinutes: 224),
    Movie(id: 3, title: "Dangal",
          overview: "A father trains his daughters to become wrestlers.",
          posterPath: nil, runtimeMinutes: 161),
    Movie(id: 4, title: "Mad Max: Fury Road",
          overview: "A high-octane escape across the wasteland.",
          posterPath: nil, runtimeMinutes: 120),
    Movie(id: 5, title: "Spirited Away",
          overview: "A young girl becomes trapped in a spirit world bathhouse.",
          posterPath: nil, runtimeMinutes: 125),
    Movie(id: 6, title: "The Social Network",
          overview: "The founding of Facebook sparks friendship and legal battles.",
          posterPath: nil, runtimeMinutes: 120)
]
