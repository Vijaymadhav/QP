import SwiftUI

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
