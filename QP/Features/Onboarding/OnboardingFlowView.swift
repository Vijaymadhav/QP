import SwiftUI

enum OnboardingStep {
    case location, gender, age, favorites
}

struct OnboardingFlowView: View {
    @EnvironmentObject var appState: AppState
    @State private var step: OnboardingStep = .location
    @State private var lastLoggedStep: OnboardingStep = .location
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
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
            .padding(.vertical, 32)
            .padding(.bottom, 40)
            .background(
                ZStack(alignment: .bottomTrailing) {
                    Color.clear
                    LogoBadgeBackground()
                        .opacity(0.18)
                        .offset(x: 50, y: 80)
                }
            )
            .navigationTitle("Qouch Potato")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .foregroundColor(QPTheme.textPrimary)
            .onAppear { logStepIfNeeded(step) }
            .onChange(of: step, perform: logStepIfNeeded)
            .onDisappear {
                if !appState.isOnboarded {
                    Analytics.shared.log(.onboardingAbandoned(step: lastLoggedStep.analyticsLabel))
                }
            }
        }
        .background(QPBackgroundView())
    }
    
    private func logStepIfNeeded(_ step: OnboardingStep) {
        if lastLoggedStep != step {
            lastLoggedStep = step
            Analytics.shared.log(.onboardingStepStarted(step: step.analyticsLabel))
        } else if lastLoggedStep == .location {
            Analytics.shared.log(.onboardingStepStarted(step: step.analyticsLabel))
        }
    }
}

struct LocationStep: View {
    @EnvironmentObject var appState: AppState
    @Binding var step: OnboardingStep
    
    var body: some View {
        OnboardingCard {
            VStack(alignment: .leading, spacing: 24) {
                Text("Where did you grow up?")
                    .font(.title.bold())
                    .foregroundColor(QPTheme.textPrimary)
                
                TextField("City, Country", text: $appState.userProfile.location)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(14)
                    .foregroundColor(QPTheme.textPrimary)
                
                HStack {
                    ForEach(["Mumbai, India", "Los Angeles, USA", "Delhi, India"], id: \.self) { place in
                        Button(place) {
                            appState.userProfile.location = place
                        }
                        .font(.caption)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(QPTheme.accent.opacity(0.18))
                        .overlay(
                            Capsule().stroke(QPTheme.accent, lineWidth: 1)
                        )
                        .foregroundColor(QPTheme.textPrimary)
                    }
                }
                
                Button {
                    step = .gender
                } label: {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(appState.userProfile.location.isEmpty ? QPTheme.accent.opacity(0.35) : QPTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .disabled(appState.userProfile.location.isEmpty)
            }
        }
    }
}

struct GenderStep: View {
    @EnvironmentObject var appState: AppState
    @Binding var step: OnboardingStep
    
    var body: some View {
        OnboardingCard {
            VStack(alignment: .leading, spacing: 24) {
                Text("What is your gender?")
                    .font(.title.bold())
                    .foregroundColor(QPTheme.textPrimary)
                
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
                                    appState.userProfile.gender == gender ? QPTheme.accent : Color.white.opacity(0.08)
                                )
                                .foregroundColor(appState.userProfile.gender == gender ? .white : QPTheme.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(QPTheme.accent.opacity(appState.userProfile.gender == gender ? 1 : 0.4), lineWidth: 1.5)
                                )
                        }
                        .animation(.easeInOut(duration: 0.12), value: appState.userProfile.gender)
                    }
                }
                
                Button {
                    step = .age
                } label: {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(QPTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
            }
        }
    }
}

struct AgeStep: View {
    @EnvironmentObject var appState: AppState
    @Binding var step: OnboardingStep
    
    var body: some View {
        OnboardingCard {
            VStack(alignment: .leading, spacing: 24) {
                Text("How old are you?")
                    .font(.title.bold())
                    .foregroundColor(QPTheme.textPrimary)
                
                Text("\(Int(appState.userProfile.age)) years")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(QPTheme.accent)
                
                Slider(value: $appState.userProfile.age, in: 13...70, step: 1)
                    .tint(QPTheme.accent)
                
                Button {
                    step = .favorites
                } label: {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(QPTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
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
        OnboardingCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Pick 5–10 movies you love")
                    .font(.title.bold())
                    .foregroundColor(QPTheme.textPrimary)
                
                HStack {
                    TextField("Search any movie…", text: $query)
                        .textInputAutocapitalization(.words)
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .foregroundColor(QPTheme.textPrimary)
                        .onSubmit { Task { await search(for: query) } }
                        .onChange(of: query) { newValue in
                            scheduleAutocomplete(for: newValue)
                        }
                    
                    if isLoading {
                        ProgressView()
                            .tint(QPTheme.accent)
                    } else {
                        Button("Go") {
                            Task { await search(for: query) }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(QPTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if !recommendedMovies.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Top picks for you")
                                    .font(.headline)
                                    .foregroundColor(QPTheme.textPrimary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(recommendedMovies) { movie in
                                            RecommendationChip(movie: movie, isSelected: appState.userProfile.favoriteMovies.contains(movie)) {
                                                toggleFavorite(movie)
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
                                        .foregroundColor(QPTheme.textPrimary)
                                    if isLoading { ProgressView().tint(QPTheme.accent) }
                                }
                                if results.isEmpty && !isLoading {
                                    Text("No matches yet. Keep typing to search TMDB.")
                                        .font(.caption)
                                        .foregroundColor(QPTheme.textMuted)
                                } else {
                                    ForEach(results.prefix(6)) { movie in
                                        ResultRow(movie: movie, isSelected: appState.userProfile.favoriteMovies.contains(movie)) {
                                            toggleFavorite(movie)
                                        }
                                    }
                                }
                            }
                        }
                        
                        ForEach(results.dropFirst(min(results.count, 6))) { movie in
                            ResultRow(movie: movie, isSelected: appState.userProfile.favoriteMovies.contains(movie)) {
                                toggleFavorite(movie)
                            }
                        }
                    }
                }
                .frame(maxHeight: 380)
                
                Text("Selected: \(appState.userProfile.favoriteMovies.count)")
                    .font(.subheadline)
                    .foregroundColor(QPTheme.textMuted)
                
                Button {
                    Analytics.shared.log(.onboardingCompleted)
                    appState.completeOnboarding()
                } label: {
                    Text("Finish")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(appState.userProfile.favoriteMovies.count < 3 ? QPTheme.accent.opacity(0.35) : QPTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .disabled(appState.userProfile.favoriteMovies.count < 3)
            }
            .onDisappear { searchTask?.cancel() }
            .task(id: recommendationAnchor) {
                await refreshRecommendations()
            }
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
                let message = error.localizedDescription
                AppLogger.network.error("Onboarding search error: \(message, privacy: .public)")
                Analytics.shared.log(.searchError(query: trimmed, message: message))
            }
        }
        await MainActor.run {
            self.results = Array(combined.uniqued().prefix(12))
            self.isLoading = false
        }
    }
}

private struct RecommendationChip: View {
    let movie: Movie
    let isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)
                Text(movie.overview)
                    .font(.caption2)
                    .foregroundColor(QPTheme.textMuted)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(width: 200, alignment: .leading)
            .background(isSelected ? QPTheme.accent : Color.white.opacity(0.08))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white.opacity(0.9) : QPTheme.accent.opacity(0.4), lineWidth: 1)
            )
        }
    }
}

private struct ResultRow: View {
    let movie: Movie
    let isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(movie.title)
                        .font(.subheadline.bold())
                        .foregroundColor(QPTheme.textPrimary)
                    Text(movie.overview)
                        .font(.caption2)
                        .foregroundColor(QPTheme.textMuted)
                        .lineLimit(2)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 6)
        }
    }
}

struct OnboardingCard<Content: View>: View {
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.15, green: 0.15, blue: 0.18), Color.black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(QPTheme.accent.opacity(0.4), lineWidth: 1.2)
                )
                .shadow(color: QPTheme.accent.opacity(0.25), radius: 25, y: 15)
            content
                .padding(24)
                .foregroundColor(QPTheme.textPrimary)
            LogoBadge(size: 54)
                .opacity(0.5)
                .padding(20)
        }
        .padding(.horizontal)
    }
}

extension OnboardingStep {
    var analyticsLabel: String {
        switch self {
        case .location: return "location"
        case .gender: return "gender"
        case .age: return "age"
        case .favorites: return "favorites"
        }
    }
}
