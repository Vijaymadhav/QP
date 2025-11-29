import Foundation
import os

struct TMDBClient {
    static let shared = TMDBClient()
    private let apiKey = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0YzJjZmRmN2JiYTFhZjE4YWFkYzhmYjkyZjZhZWRiNSIsIm5iZiI6MTc0ODY3MDY3MS4xNiwic3ViIjoiNjgzYTk4Y2Y3NWYxMTc0NGQxZmRhOGQ1Iiwic2NvcGVzIjpbImFwaV9yZWFkIl0sInZlcnNpb24iOjF9.g0TkiFEwCF9rR06Dyz793_We3oKFNBdERA8yW83AjWg"
    private let baseURL = URL(string: "https://api.themoviedb.org/3")!
    
    func searchMovies(query: String) async throws -> [Movie] {
        guard !query.isEmpty else { return [] }
        
        var components = URLComponents(
            url: baseURL.appendingPathComponent("search/movie"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            .init(name: "api_key", value: apiKey),
            .init(name: "query", value: query),
            .init(name: "include_adult", value: "false")
        ]
        
        do {
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            let decoded = try JSONDecoder().decode(TMDBSearchResponse.self, from: data)
            return decoded.results.map {
                Movie(
                    id: $0.id,
                    title: $0.title,
                    overview: $0.overview,
                    posterPath: $0.poster_path,
                    runtimeMinutes: nil,
                    tags: [],
                    reasons: []
                )
            }
        } catch {
            AppLogger.network.error("TMDB search failed for \(query, privacy: .public): \(error.localizedDescription, privacy: .public)")
            Analytics.shared.log(.searchError(query: query, message: error.localizedDescription))
            throw error
        }
    }

    func fetchPopular(page: Int) async throws -> [TMDBMovieDTO] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("movie/popular"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            .init(name: "api_key", value: apiKey),
            .init(name: "page", value: String(page)),
            .init(name: "language", value: "en-US")
        ]
        do {
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            let decoded = try JSONDecoder().decode(TMDBPaginatedResponse.self, from: data)
            return decoded.results
        } catch {
            AppLogger.network.error("TMDB popular fetch failed page \(page, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

}

struct TMDBSearchResponse: Codable {
    let results: [TMDBMovieDTO]
}

struct TMDBPaginatedResponse: Codable {
    let results: [TMDBMovieDTO]
}

struct TMDBMovieDTO: Codable {
    let id: Int
    let title: String
    let overview: String
    let poster_path: String?
}
