import SwiftUI
import Foundation

// MARK: - App Entry



// MARK: - Global State

final class AppState: ObservableObject {
    @Published var isOnboarded: Bool = false
    @Published var userProfile = UserProfile()
    @Published var watchlist: [Movie] = []
    @Published var likedMovies: [Movie] = []
    
    let vectorStore: any MovieVectorStore = MovieVectorStoreFactory.make()
}

// MARK: - Models

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

// Demo movies (until TMDB is wired fully)
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

// MARK: - TMDB Client (stub: add your API key)

struct TMDBClient {
    static let shared = TMDBClient()
    private let apiKey = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0YzJjZmRmN2JiYTFhZjE4YWFkYzhmYjkyZjZhZWRiNSIsIm5iZiI6MTc0ODY3MDY3MS4xNiwic3ViIjoiNjgzYTk4Y2Y3NWYxMTc0NGQxZmRhOGQ1Iiwic2NvcGVzIjpbImFwaV9yZWFkIl0sInZlcnNpb24iOjF9.g0TkiFEwCF9rR06Dyz793_We3oKFNBdERA8yW83AjWg" // <- put your key here
    private let baseURL = URL(string: "https://api.themoviedb.org/3")!
    
    func searchMovies(query: String) async throws -> [Movie] {
        guard !query.isEmpty else { return [] }
        
        var components = URLComponents(
            url: baseURL.appendingPathComponent("search/movie"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            .init(name: "api_key", value: apiKey),
            .init(name: "query", value: query),
            .init(name: "include_adult", value: "false")
        ]
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let decoded = try JSONDecoder().decode(TMDBSearchResponse.self, from: data)
        
        return decoded.results.map {
            Movie(
                id: $0.id,
                title: $0.title,
                overview: $0.overview,
                posterPath: $0.poster_path,
                runtimeMinutes: nil,
                tags: [],
                reasons: []
            )
        }
    }
}

struct TMDBSearchResponse: Codable {
    let results: [TMDBMovieDTO]
}

struct TMDBMovieDTO: Codable {
    let id: Int
    let title: String
    let overview: String
    let poster_path: String?
}

// MARK: - Vector Store Infrastructure

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

// MARK: - Root & Tabs

struct RootView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isOnboarded {
                MainTabView()
            } else {
                OnboardingFlowView()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            SwipeDeckView()
                .tabItem {
                    Label("Discover", systemImage: "sparkles.tv")
                }
            
            MoviesLikeXView()
                .tabItem {
                    Label("Like X", systemImage: "text.magnifyingglass")
                }
            
            WatchlistView()
                .tabItem {
                    Label("Watchlist", systemImage: "star.fill")
                }
        }
        .tint(.white)
    }
}

// MARK: - Onboarding Flow

enum OnboardingStep {
    case location, gender, age, favorites
}

struct OnboardingFlowView: View {
    @EnvironmentObject var appState: AppState
    @State private var step: OnboardingStep = .location
    
    var body: some View {
        NavigationStack {
            VStack {
                switch step {
                case .location:
                    LocationStep(step: $step)
                case .gender:
                    GenderStep(step: $step)
                case .age:
                    AgeStep(step: $step)
                case .favorites:
                    FavoritesStep()
                }
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Qouch Potato")
            .foregroundColor(.white)
        }
    }
}

struct LocationStep: View {
    @EnvironmentObject var appState: AppState
    @Binding var step: OnboardingStep
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Where did you grow up?")
                .font(.title.bold())
            
            TextField("City, Country", text: $appState.userProfile.location)
                .textFieldStyle(.roundedBorder)
                .foregroundColor(.black)
            
            HStack {
                ForEach(["Mumbai, India", "Los Angeles, USA", "Delhi, India"], id: \.self) { place in
                    Button(place) {
                        appState.userProfile.location = place
                    }
                    .font(.caption)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            Button {
                step = .gender
            } label: {
                Text("Next")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(appState.userProfile.location.isEmpty ? .gray : .white)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
            .disabled(appState.userProfile.location.isEmpty)
        }
    }
}

struct GenderStep: View {
    @EnvironmentObject var appState: AppState
    @Binding var step: OnboardingStep
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("What is your gender?")
                .font(.title.bold())
            
            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Gender.allCases) { gender in
                    Button {
                        appState.userProfile.gender = gender
                    } label: {
                        Text(gender.rawValue)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                appState.userProfile.gender == gender
                                ? Color.white
                                : Color.white.opacity(0.15)
                            )
                            .foregroundColor(appState.userProfile.gender == gender ? .black : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.4), lineWidth: appState.userProfile.gender == gender ? 0 : 1)
                            )
                    }
                    .animation(.easeInOut(duration: 0.12), value: appState.userProfile.gender)
                }
            }
            
            Spacer()
            
            Button {
                step = .age
            } label: {
                Text("Next")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
        }
    }
}

struct AgeStep: View {
    @EnvironmentObject var appState: AppState
    @Binding var step: OnboardingStep
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("How old are you?")
                .font(.title.bold())
            
            Text("\(Int(appState.userProfile.age)) years")
                .font(.headline)
            
            Slider(value: $appState.userProfile.age, in: 13...70, step: 1)
            
            Spacer()
            
            Button {
                step = .favorites
            } label: {
                Text("Next")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
        }
    }
}

struct FavoritesStep: View {
    @EnvironmentObject var appState: AppState
    @State private var query: String = ""
    @State private var results: [Movie] = []
    @State private var recommendedMovies: [Movie] = []
    @State private var isLoading = false
    @State private var searchTask: Task<Void, Never>? = nil
    
    private var recommendationAnchor: String {
        [
            appState.userProfile.location,
            appState.userProfile.gender.rawValue,
            String(Int(appState.userProfile.age))
        ].joined(separator: "-")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pick 5–10 movies you love")
                .font(.title.bold())
            
            HStack {
                TextField("Search any movie…", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .foregroundColor(.black)
                    .onSubmit { Task { await search(for: query) } }
                    .onChange(of: query) { newValue in
                        scheduleAutocomplete(for: newValue)
                    }
                
                if isLoading {
                    ProgressView()
                } else {
                    Button("Go") {
                        Task { await search(for: query) }
                    }
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !recommendedMovies.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top picks for you")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(recommendedMovies) { movie in
                                        Button {
                                            toggleFavorite(movie)
                                        } label: {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(movie.title)
                                                    .font(.subheadline.bold())
                                                    .multilineTextAlignment(.leading)
                                                Text(movie.displayRuntime.isEmpty ? movie.overview : movie.displayRuntime)
                                                    .font(.caption)
                                                    .lineLimit(2)
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                            .padding(12)
                                            .frame(width: 180, alignment: .leading)
                                            .background(
                                                appState.userProfile.favoriteMovies.contains(movie)
                                                ? Color.white
                                                : Color.white.opacity(0.08)
                                            )
                                            .foregroundColor(appState.userProfile.favoriteMovies.contains(movie) ? .black : .white)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Matches")
                                    .font(.headline)
                                if isLoading {
                                    ProgressView()
                                }
                            }
                            
                            if results.isEmpty && !isLoading {
                                Text("No matches yet. Keep typing to search TMDB.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(results.prefix(6)) { movie in
                                    Button {
                                        toggleFavorite(movie)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(movie.title)
                                                    .font(.subheadline.bold())
                                                Text(movie.overview)
                                                    .font(.caption2)
                                                    .foregroundColor(.white.opacity(0.7))
                                                    .lineLimit(2)
                                            }
                                            Spacer()
                                            if appState.userProfile.favoriteMovies.contains(movie) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(results.dropFirst(min(results.count, 6)))) { movie in
                            Button {
                                toggleFavorite(movie)
                            } label: {
                                HStack {
                                    Text(movie.title)
                                        .foregroundColor(.white)
                                    Spacer()
                                    if appState.userProfile.favoriteMovies.contains(movie) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            Text("Selected: \(appState.userProfile.favoriteMovies.count)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Button {
                appState.isOnboarded = true
            } label: {
                Text("Finish")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(appState.userProfile.favoriteMovies.count < 3 ? .gray : .white)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
            .disabled(appState.userProfile.favoriteMovies.count < 3)
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .onDisappear { searchTask?.cancel() }
        .task(id: recommendationAnchor) {
            await refreshRecommendations()
        }
    }
    
    private func toggleFavorite(_ movie: Movie) {
        if let idx = appState.userProfile.favoriteMovies.firstIndex(of: movie) {
            appState.userProfile.favoriteMovies.remove(at: idx)
        } else {
            appState.userProfile.favoriteMovies.append(movie)
        }
    }
    
    private func refreshRecommendations() async {
        let recs = await appState.vectorStore.recommendedMovies(for: appState.userProfile, limit: 4)
        await MainActor.run {
            self.recommendedMovies = recs.uniqued()
        }
    }
    
    private func scheduleAutocomplete(for text: String) {
        searchTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            isLoading = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await search(for: trimmed)
        }
    }
    
    private func search(for text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await MainActor.run {
                self.results = []
                self.isLoading = false
            }
            return
        }
        await MainActor.run { isLoading = true }
        var combined = await appState.vectorStore.autocompleteMovies(query: trimmed, limit: 12)
        if combined.count < 4 {
            do {
                let remote = try await TMDBClient.shared.searchMovies(query: trimmed)
                combined = (combined + remote).uniqued()
            } catch {
                print("Search error: \(error)")
            }
        }
        await MainActor.run {
            self.results = Array(combined.uniqued().prefix(12))
            self.isLoading = false
        }
    }
}


extension Array where Element: Identifiable, Element.ID: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element.ID>()
        var output: [Element] = []
        for element in self {
            if seen.insert(element.id).inserted {
                output.append(element)
            }
        }
        return output
    }
}

// MARK: - Swipe Deck


enum SwipeDirection {
    case left, right, up
}

struct SwipeDeckView: View {
    @EnvironmentObject var appState: AppState
    @State private var movies: [Movie] = demoMovies
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if movies.isEmpty {
                Text("You're all caught up!\nWe'll find more for you soon.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding()
            } else {
                VStack {
                    ZStack {
                        ForEach(movies) { movie in
                            SwipeCardView(
                                movie: movie,
                                onSwipe: { direction in
                                    handleSwipe(movie: movie, direction: direction)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 24)
                    
                    HStack(spacing: 40) {
                        CircleButton(systemName: "xmark") {
                            if let top = movies.last {
                                handleSwipe(movie: top, direction: .left)
                            }
                        }
                        CircleButton(systemName: "star.fill") {
                            if let top = movies.last {
                                handleSwipe(movie: top, direction: .up)
                            }
                        }
                        CircleButton(systemName: "heart.fill") {
                            if let top = movies.last {
                                handleSwipe(movie: top, direction: .right)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func handleSwipe(movie: Movie, direction: SwipeDirection) {
        guard let index = movies.firstIndex(of: movie) else { return }
        
        switch direction {
        case .left:
            break
        case .right:
            appState.likedMovies.append(movie)
        case .up:
            appState.watchlist.append(movie)
        }
        
        movies.remove(at: index)
    }
}

struct SwipeCardView: View {
    let movie: Movie
    let onSwipe: (SwipeDirection) -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    private let swipeThreshold: CGFloat = 120
    
    var body: some View {
        let dragGesture = DragGesture()
            .onChanged { value in
                offset = value.translation
                rotation = Double(value.translation.width / 20)
            }
            .onEnded { value in
                let translation = value.translation
                if translation.width > swipeThreshold {
                    swipe(.right)
                } else if translation.width < -swipeThreshold {
                    swipe(.left)
                } else if translation.height < -swipeThreshold {
                    swipe(.up)
                } else {
                    reset()
                }
            }
        
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    VStack(alignment: .leading, spacing: 12) {
                        if let url = movie.fullPosterURL {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.4)
                            }
                            .frame(height: 360)
                            .clipped()
                            .cornerRadius(20)
                        } else {
                            Color.gray.opacity(0.3)
                                .frame(height: 360)
                                .cornerRadius(20)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(movie.title)
                                .font(.title.bold())
                            
                            Text("Mind-bending • Sci-Fi • \(movie.displayRuntime)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Why this movie?")
                                    .font(.headline)
                                
                                Text("• Matches your current mood")
                                Text("• People your age & background loved similar films")
                            }
                            .font(.footnote)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(radius: 10)
        }
        .padding(.vertical, 24)
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .gesture(dragGesture)
        .animation(.spring(), value: offset)
    }
    
    private func swipe(_ direction: SwipeDirection) {
        withAnimation(.spring()) {
            switch direction {
            case .left:
                offset = CGSize(width: -800, height: 0)
            case .right:
                offset = CGSize(width: 800, height: 0)
            case .up:
                offset = CGSize(width: 0, height: -800)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onSwipe(direction)
        }
    }
    
    private func reset() {
        withAnimation(.spring()) {
            offset = .zero
            rotation = 0
        }
    }
}

struct CircleButton: View {
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .bold))
                .frame(width: 64, height: 64)
                .background(Color.white)
                .foregroundColor(.black)
                .clipShape(Circle())
                .shadow(radius: 6)
        }
    }
}

// MARK: - Movies like X

struct MoviesLikeXView: View {
    @State private var query = ""
    @State private var results: [Movie] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("Movies like Inception…", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .foregroundColor(.black)
                        .onSubmit { Task { await search() } }
                    
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Go") { Task { await search() } }
                    }
                }
                .padding()
                
                List(results) { movie in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(movie.title).font(.headline)
                        Text(movie.overview).font(.caption).lineLimit(2)
                    }
                }
            }
            .navigationTitle("Movies like X")
        }
    }
    
    private func search() async {
        guard !query.isEmpty else { return }
        isLoading = true
        do {
            let found = try await TMDBClient.shared.searchMovies(query: query)
            await MainActor.run {
                self.results = found
                self.isLoading = false
            }
        } catch {
            print("Search error: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
}

// MARK: - Watchlist

struct WatchlistView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            List(appState.watchlist) { movie in
                VStack(alignment: .leading) {
                    Text(movie.title).font(.headline)
                    Text(movie.overview).font(.caption).lineLimit(2)
                }
            }
            .navigationTitle("Watchlist")
        }
    }
}
