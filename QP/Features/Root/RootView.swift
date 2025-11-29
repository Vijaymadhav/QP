import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            QPBackgroundView()
            Group {
                if appState.authSession == nil {
                    LoginView()
                } else if appState.isOnboarded {
                    MainTabView()
                } else {
                    OnboardingFlowView()
                }
            }
            .animation(.easeInOut(duration: 0.25), value: appState.authSession == nil)
            .animation(.easeInOut(duration: 0.25), value: appState.isOnboarded)
            
            if appState.authSession != nil {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: appState.logout) {
                            Label("Log off", systemImage: "arrowshape.turn.up.backward.fill")
                                .font(.caption.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.08))
                                .foregroundColor(QPTheme.textPrimary)
                                .overlay(
                                    Capsule()
                                        .stroke(QPTheme.accent.opacity(0.6), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding([.top, .trailing], 20)
                .transition(.opacity)
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
        .tint(QPTheme.accent)
    }
}
