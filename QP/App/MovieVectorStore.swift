import Foundation

struct MovieEmbeddingRecord: Identifiable {
    let id: Int
    let movie: Movie
    let vector: [Float]
    
    init(movie: Movie) {
        self.id = movie.id
        self.movie = movie
        self.vector = MovieVectorizer.vectorize(text: "\(movie.title) \(movie.overview)")
    }
}

protocol MovieVectorStore: Sendable {
    func recommendedMovies(for profile: UserProfile, limit: Int) async -> [Movie]
    func autocompleteMovies(query: String, limit: Int) async -> [Movie]
}

enum MovieVectorStoreFactory {
    static func make() -> any MovieVectorStore {
        #if canImport(SimilarityIndex)
        if #available(iOS 18.0, macOS 15.0, *) {
            return SimilarityIndexMovieStore.shared
        }
        #endif
        return DemoVectorStore.shared
    }
}

actor DemoVectorStore: MovieVectorStore {
    static let shared = DemoVectorStore()
    
    private let embeddings: [MovieEmbeddingRecord]
    
    private init() {
        self.embeddings = demoMovies.map { MovieEmbeddingRecord(movie: $0) }
    }
    
    func recommendedMovies(for profile: UserProfile, limit: Int) async -> [Movie] {
        let anchor = MovieVectorizer.profileVector(for: profile)
        return topMatches(for: anchor, limit: limit)
    }
    
    func autocompleteMovies(query: String, limit: Int) async -> [Movie] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return topMatches(for: MovieVectorizer.vectorize(text: trimmed), limit: limit)
    }
    
    private func topMatches(for anchor: [Float], limit: Int) -> [Movie] {
        embeddings
            .map { ($0.movie, MovieVectorizer.cosine($0.vector, anchor)) }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map(\.0)
    }
}

enum MovieVectorizer {
    static let dimension = 64
    
    static func vectorize(text: String) -> [Float] {
        var vector = [Float](repeating: 0, count: dimension)
        let tokens = text.lowercased().split { character in
            !character.isLetter
        }
        for token in tokens {
            var hasher = Hasher()
            hasher.combine(token)
            let index = abs(hasher.finalize()) % dimension
            vector[index] += 1
        }
        return normalize(vector)
    }
    
    static func profileVector(for profile: UserProfile) -> [Float] {
        let descriptor = [
            profile.location,
            profile.gender.rawValue,
            String(Int(profile.age)),
            profile.favoriteMovies.map(\.title).joined(separator: " ")
        ].joined(separator: " ")
        return vectorize(text: descriptor)
    }
    
    static func cosine(_ lhs: [Float], _ rhs: [Float]) -> Float {
        guard lhs.count == rhs.count else { return 0 }
        let dotProduct = zip(lhs, rhs).reduce(Float.zero) { $0 + $1.0 * $1.1 }
        let lhsMag = sqrt(lhs.reduce(Float.zero) { $0 + $1 * $1 })
        let rhsMag = sqrt(rhs.reduce(Float.zero) { $0 + $1 * $1 })
        guard lhsMag > 0, rhsMag > 0 else { return 0 }
        return dotProduct / (lhsMag * rhsMag)
    }
    
    private static func normalize(_ vector: [Float]) -> [Float] {
        let magnitude = sqrt(vector.reduce(Float.zero) { $0 + $1 * $1 })
        guard magnitude > 0 else { return vector }
        return vector.map { $0 / magnitude }
    }
}

#if canImport(SimilarityIndex)
import SimilarityIndex

@available(iOS 18.0, macOS 15.0, *)
actor SimilarityIndexMovieStore: MovieVectorStore {
    static let shared = SimilarityIndexMovieStore()
    
    private let fallback = DemoVectorStore.shared
    
    private init() {
        bootstrapIfNeeded()
    }
    
    func recommendedMovies(for profile: UserProfile, limit: Int) async -> [Movie] {
        // TODO: Replace fallback once the SimilarityIndex framework is available at compile time.
        return await fallback.recommendedMovies(for: profile, limit: limit)
    }
    
    func autocompleteMovies(query: String, limit: Int) async -> [Movie] {
        // TODO: Replace fallback once the SimilarityIndex framework is available at compile time.
        return await fallback.autocompleteMovies(query: query, limit: limit)
    }
    
    private func bootstrapIfNeeded() {
        // Placeholder: When building with Xcode 16 / iOS 18 SDK, create the on-disk index here and seed demo data.
    }
}
#endif
