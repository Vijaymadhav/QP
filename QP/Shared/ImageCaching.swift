import SwiftUI
import UIKit

protocol ImageCache: AnyObject {
    subscript(_ url: URL) -> UIImage? { get set }
}

final class TemporaryImageCache: ImageCache {
    static let shared = TemporaryImageCache()
    private let cache = NSCache<NSURL, UIImage>()
    private init() {
        cache.countLimit = 200
    }
    subscript(_ key: URL) -> UIImage? {
        get { cache.object(forKey: key as NSURL) }
        set {
            if let newValue = newValue {
                cache.setObject(newValue, forKey: key as NSURL)
            } else {
                cache.removeObject(forKey: key as NSURL)
            }
        }
    }
}

enum CachedImagePhase {
    case empty
    case success(Image)
    case failure(Error)
}

@MainActor
final class ImageLoader: ObservableObject {
    @Published private(set) var phase: CachedImagePhase = .empty
    private let url: URL?
    private let cache: ImageCache
    private var loadTask: Task<Void, Never>?
    
    init(url: URL?, cache: ImageCache = TemporaryImageCache.shared) {
        self.url = url
        self.cache = cache
    }
    
    func load() {
        guard loadTask == nil else { return }
        guard let url else {
            phase = .failure(ImageLoaderError.invalidURL)
            return
        }
        if let cached = cache[url] {
            phase = .success(Image(uiImage: cached))
            return
        }
        loadTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                var request = URLRequest(url: url)
                request.cachePolicy = .returnCacheDataElseLoad
                let (data, _) = try await URLSession.shared.data(for: request)
                guard let image = UIImage(data: data) else {
                    throw ImageLoaderError.decodingFailed
                }
                await MainActor.run {
                    self.cache[url] = image
                    self.phase = .success(Image(uiImage: image))
                }
            } catch {
                await MainActor.run {
                    self.phase = .failure(error)
                }
            }
            await MainActor.run { self.loadTask = nil }
        }
    }
    
    func cancel() {
        loadTask?.cancel()
        loadTask = nil
    }
}

enum ImageLoaderError: Error {
    case invalidURL
    case decodingFailed
}

struct CachedAsyncImage<Content: View>: View {
    @StateObject private var loader: ImageLoader
    private let content: (CachedImagePhase) -> Content
    
    init(url: URL?, cache: ImageCache = TemporaryImageCache.shared, @ViewBuilder content: @escaping (CachedImagePhase) -> Content) {
        _loader = StateObject(wrappedValue: ImageLoader(url: url, cache: cache))
        self.content = content
    }
    
    var body: some View {
        content(loader.phase)
            .task { loader.load() }
            .onDisappear { loader.cancel() }
    }
}
