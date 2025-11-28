import SwiftUI

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
