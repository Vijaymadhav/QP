import SwiftUI

final class AppState: ObservableObject {
    @Published var isOnboarded: Bool = false
    @Published var userProfile = UserProfile()
    @Published var watchlist: [Movie] = []
    @Published var likedMovies: [Movie] = []
    
    let vectorStore: any MovieVectorStore = MovieVectorStoreFactory.make()
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
