import SwiftUI

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
