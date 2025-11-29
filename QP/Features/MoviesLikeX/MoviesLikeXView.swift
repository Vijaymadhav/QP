import SwiftUI

struct MoviesLikeXView: View {
    @State private var query = ""
    @State private var results: [Movie] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                HStack(spacing: 12) {
                    TextField("Movies like Inception…", text: $query)
                        .textInputAutocapitalization(.words)
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(14)
                        .foregroundColor(QPTheme.textPrimary)
                        .onSubmit { Task { await search() } }
                    
                    if isLoading {
                        ProgressView().tint(QPTheme.accent)
                    } else {
                        Button("Go") { Task { await search() } }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(QPTheme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                
                if results.isEmpty {
                    VStack(spacing: 12) {
                        LogoBadge(size: 90).opacity(0.18)
                        Text("Search for a title to see similar movies")
                            .foregroundColor(QPTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(results) { movie in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(movie.title)
                                        .font(.headline)
                                        .foregroundColor(QPTheme.textPrimary)
                                    Text(movie.overview)
                                        .font(.caption)
                                        .foregroundColor(QPTheme.textMuted)
                                        .lineLimit(3)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(QPTheme.accent.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
            }
            .padding(24)
            .navigationTitle("Movies like X")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background(
                ZStack(alignment: .topTrailing) {
                    QPBackgroundView()
                    LogoBadge(size: 160)
                        .opacity(0.08)
                        .offset(x: -30, y: 50)
                }
            )
        }
    }
    
    private func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        do {
            let found = try await TMDBClient.shared.searchMovies(query: trimmed)
            await MainActor.run {
                self.results = found
                self.isLoading = false
            }
        } catch {
            let message = error.localizedDescription
            AppLogger.network.error("MoviesLikeX search failed: \(message, privacy: .public)")
            Analytics.shared.log(.searchError(query: trimmed, message: message))
            await MainActor.run { self.isLoading = false }
        }
    }
}
