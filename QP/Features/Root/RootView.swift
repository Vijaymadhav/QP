import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.authSession == nil {
                LoginView()
            } else if appState.isOnboarded {
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
