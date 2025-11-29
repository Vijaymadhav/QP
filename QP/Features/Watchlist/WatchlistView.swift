import SwiftUI

struct WatchlistView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            Group {
                if appState.watchlist.isEmpty {
                    VStack(spacing: 16) {
                        LogoBadge(size: 120).opacity(0.15)
                        Text("Add movies to your watchlist from the Discover tab.")
                            .foregroundColor(QPTheme.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(appState.watchlist) { movie in
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
                                        .stroke(QPTheme.accent.opacity(0.25), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .padding(.horizontal, 24)
            .navigationTitle("Watchlist")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background(
                ZStack(alignment: .center) {
                    QPBackgroundView()
                    LogoBadgeBackground()
                        .opacity(0.12)
                }
            )
        }
    }
}
