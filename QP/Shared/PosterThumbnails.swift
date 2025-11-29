import Foundation

enum PosterThumbnails {
    static let bundled: [String: Data] = {
        var map: [String: Data] = [:]
        map["demo-1"] = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAIAAACjcKk8AAAAD0lEQVR42mP4GBXFMAAYAKL3MVdZ3X6NAAAAAElFTkSuQmCC")
        map["demo-2"] = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAIAAACjcKk8AAAAD0lEQVR42mP4ezqPYQAwAJ3LQlV4V5RpAAAAAElFTkSuQmCC")
        map["demo-3"] = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAIAAACjcKk8AAAAD0lEQVR42mPQO1PIMAAYAPF9KospPMGSAAAAAElFTkSuQmCC")
        map["demo-4"] = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAIAAACjcKk8AAAAD0lEQVR42mMwmXGbYQAwAIvDMZPLpNuAAAAAAElFTkSuQmCC")
        map["demo-5"] = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAIAAACjcKk8AAAAD0lEQVR42mOYHbmNYQAwALFDMe0PynWrAAAAAElFTkSuQmCC")
        map["demo-6"] = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAIAAACjcKk8AAAAD0lEQVR42mP4dXkCwwBgAKu8RufprcLeAAAAAElFTkSuQmCC")
        return map.compactMapValues { $0 }
    }()
}
