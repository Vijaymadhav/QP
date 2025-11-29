import Foundation

final class PosterPrefetcher {
    static let shared = PosterPrefetcher()
    private let defaults = UserDefaults.standard
    private let lastPrefetchKey = "qp.posterPrefetch.lastRun"
    private let maxPages = 50 // 20 movies per page ≈ 1000 posters
    private var task: Task<Void, Never>?
    private let lock = NSLock()
    private init() {}
    
    func startIfNeeded() {
        lock.lock(); defer { lock.unlock() }
        guard task == nil else { return }
        let lastRun = defaults.object(forKey: lastPrefetchKey) as? Date
        let shouldPrefetch: Bool
        if let lastRun {
            shouldPrefetch = abs(lastRun.timeIntervalSinceNow) > 60 * 60 * 24 * 7
        } else {
            shouldPrefetch = true
        }
        guard shouldPrefetch else { return }
        task = Task.detached(priority: .background) { [weak self] in
            await self?.prefetchPosters()
        }
    }
    
    private func markCompleted() {
        lock.lock()
        defaults.set(Date(), forKey: lastPrefetchKey)
        task = nil
        lock.unlock()
    }
    
    private func prefetchPosters() async {
        defer { markCompleted() }
        for page in 1...maxPages {
            if Task.isCancelled { return }
            do {
                let movies = try await TMDBClient.shared.fetchPopular(page: page)
                await cachePosters(for: movies)
            } catch {
                AppLogger.network.error("Poster prefetch page \(page) failed: \(error.localizedDescription, privacy: .public)")
                break
            }
        }
    }
    
    private func cachePosters(for movies: [TMDBMovieDTO]) async {
        await withTaskGroup(of: Void.self) { group in
            for movie in movies {
                guard let path = movie.poster_path else { continue }
                if PosterDiskCache.shared.hasImage(for: path) { continue }
                group.addTask(priority: .background) {
                    do {
                        let data = try await self.fetchPosterData(path: path)
                        PosterDiskCache.shared.store(data, for: path)
                    } catch {
                        AppLogger.network.error("Poster prefetch failed for \(path, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    }
                }
            }
        }
    }
    
    private func fetchPosterData(path: String) async throws -> Data {
        guard let url = URL(string: "https://image.tmdb.org/t/p/w500\(path)") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
