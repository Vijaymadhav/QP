import Foundation
import os

enum AnalyticsEvent {
    case loginStarted
    case loginFailed(reason: String)
    case loginCompleted
    case onboardingStepStarted(step: String)
    case onboardingCompleted
    case onboardingAbandoned(step: String)
    case searchError(query: String, message: String)
}

final class Analytics {
    static let shared = Analytics()
    private let logger = Logger(subsystem: "com.vijay.QP", category: "analytics")
    private init() {}
    
    func log(_ event: AnalyticsEvent) {
        switch event {
        case .loginStarted:
            logger.log("[Analytics] Login started")
        case .loginFailed(let reason):
            logger.error("[Analytics] Login failed: \(reason, privacy: .public)")
        case .loginCompleted:
            logger.log("[Analytics] Login completed")
        case .onboardingStepStarted(let step):
            logger.log("[Analytics] Onboarding step started: \(step, privacy: .public)")
        case .onboardingCompleted:
            logger.log("[Analytics] Onboarding completed")
        case .onboardingAbandoned(let step):
            logger.error("[Analytics] Onboarding abandoned on step: \(step, privacy: .public)")
        case .searchError(let query, let message):
            logger.error("[Analytics] Search error for \(query, privacy: .public): \(message, privacy: .public)")
        }
    }
}
