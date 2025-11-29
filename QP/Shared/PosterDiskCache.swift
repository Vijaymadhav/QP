import Foundation
import UIKit

final class PosterDiskCache {
    static let shared = PosterDiskCache()
    private let directory: URL
    private let ioQueue = DispatchQueue(label: "poster.disk.cache")
    private let fileManager = FileManager.default
    private let maxEntries = 500
    
    private init() {
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        directory = base.appendingPathComponent("PosterCache", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
    
    func bootstrapBundledThumbnails() {
        ioQueue.async {
            for (key, data) in PosterThumbnails.bundled where !self.hasImage(for: key) {
                self.write(data, for: key)
            }
        }
    }
    
    func image(for key: String) -> UIImage? {
        let url = fileURL(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    func hasImage(for key: String) -> Bool {
        fileManager.fileExists(atPath: fileURL(for: key).path)
    }
    
    func store(_ data: Data, for key: String) {
        ioQueue.async {
            self.write(data, for: key)
            self.pruneIfNeeded()
        }
    }
    
    private func write(_ data: Data, for key: String) {
        let url = fileURL(for: key)
        try? data.write(to: url, options: .atomic)
    }
    
    private func pruneIfNeeded() {
        guard let urls = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles),
              urls.count > maxEntries else { return }
        let sorted = urls.sorted {
            let date0 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let date1 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return date0 < date1
        }
        for url in sorted.dropLast(maxEntries) {
            try? fileManager.removeItem(at: url)
        }
    }
    
    private func fileURL(for key: String) -> URL {
        let safe = key.replacingOccurrences(of: "[^A-Za-z0-9._-]", with: "-", options: .regularExpression)
        return directory.appendingPathComponent(safe)
    }
}
