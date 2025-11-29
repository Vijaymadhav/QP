import os

enum AppLogger {
    static let network = Logger(subsystem: "com.vijay.QP", category: "network")
    static let cache = Logger(subsystem: "com.vijay.QP", category: "cache")
}
