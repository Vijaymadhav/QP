import SwiftUI

enum SwipeDirection {
    case left, right, up
}

struct SwipeDeckView: View {
    @EnvironmentObject var appState: AppState
    @State private var movies: [Movie] = demoMovies
    
    var body: some View {
        ZStack {
            QPBackgroundView()
            LogoBadgeBackground()
                .opacity(0.15)
                .scaleEffect(1.2)
                .offset(x: -40, y: 120)
            
            if movies.isEmpty {
                VStack(spacing: 16) {
                    LogoBadge(size: 120)
                        .opacity(0.2)
                    Text("You're all caught up!\nWe'll find more for you soon.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(QPTheme.textPrimary)
                        .padding()
                }
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
            RoundedRectangle(cornerRadius: 32)
                .fill(LinearGradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.13), Color.black], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    VStack(alignment: .leading, spacing: 12) {
                        if let url = movie.fullPosterURL {
                            CachedAsyncImage(url: url, cacheKey: movie.posterCacheKey) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    LogoBadge(size: 80)
                                        .foregroundColor(QPTheme.accent)
                                        .frame(maxWidth: .infinity)
                                case .empty:
                                    Color.white.opacity(0.05)
                                        .overlay(ProgressView().tint(QPTheme.accent))
                                }
                            }
                            .frame(height: 360)
                            .clipped()
                            .cornerRadius(20)
                        } else {
                            LogoBadge(size: 120)
                                .frame(height: 360)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(QPTheme.accent.opacity(0.7))
                                .background(Color.white.opacity(0.02))
                                .cornerRadius(20)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(movie.title)
                                .font(.title.bold())
                                .foregroundColor(QPTheme.textPrimary)
                            
                            Text("Mind-bending • Sci-Fi • \(movie.displayRuntime)")
                                .font(.subheadline)
                                .foregroundColor(QPTheme.textMuted)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Why this movie?")
                                    .font(.headline)
                                    .foregroundColor(QPTheme.textPrimary)
                                Text("• Matches your current mood")
                                Text("• People your age & background loved similar films")
                            }
                            .font(.footnote)
                            .foregroundColor(QPTheme.textMuted)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: QPTheme.accent.opacity(0.3), radius: 25, y: 12)
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
                .frame(width: 68, height: 68)
                .background(QPTheme.accent)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(color: QPTheme.accent.opacity(0.5), radius: 18, y: 8)
        }
    }
}
