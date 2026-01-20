//
//  AppRule.swift
//  BrainTax
//
//  Configuration for app locking rules
//

import Foundation

/// Defines when and how an app should be locked
struct AppRule: Codable, Identifiable {
    var id: UUID
    var name: String                    // Display name: "Instagram", "TikTok"
    var urlScheme: String               // URL to open: "instagram://", "tiktok://"
    var isEnabled: Bool
    var conditions: [RuleCondition]     // When to require challenge
    var challengeConfig: ChallengeConfig

    init(
        id: UUID = UUID(),
        name: String,
        urlScheme: String,
        isEnabled: Bool = true,
        conditions: [RuleCondition] = [RuleCondition(type: .always)],
        challengeConfig: ChallengeConfig = ChallengeConfig()
    ) {
        self.id = id
        self.name = name
        self.urlScheme = urlScheme
        self.isEnabled = isEnabled
        self.conditions = conditions
        self.challengeConfig = challengeConfig
    }
}

/// Condition types for when a challenge is required
enum ConditionType: String, Codable, CaseIterable {
    case always          // Always require challenge
    case timeOfDay       // Only during certain hours
    case openCount       // After N opens per day
}

/// A single condition for triggering a challenge
struct RuleCondition: Codable {
    var type: ConditionType
    var startHour: Int?           // For timeOfDay: start hour (0-23)
    var endHour: Int?             // For timeOfDay: end hour (0-23)
    var maxDailyOpens: Int?       // For openCount: threshold

    init(type: ConditionType, startHour: Int? = nil, endHour: Int? = nil, maxDailyOpens: Int? = nil) {
        self.type = type
        self.startHour = startHour
        self.endHour = endHour
        self.maxDailyOpens = maxDailyOpens
    }

    /// Evaluates if this condition requires a challenge
    func requiresChallenge(currentHour: Int, dailyOpenCount: Int) -> Bool {
        switch type {
        case .always:
            return true
        case .timeOfDay:
            guard let start = startHour, let end = endHour else { return false }
            if start <= end {
                return currentHour >= start && currentHour < end
            } else {
                // Handles overnight ranges like 22:00 - 06:00
                return currentHour >= start || currentHour < end
            }
        case .openCount:
            guard let max = maxDailyOpens else { return false }
            return dailyOpenCount >= max
        }
    }
}

/// Configuration for the challenge presented to unlock an app
struct ChallengeConfig: Codable {
    var puzzleType: PuzzleType      // Which type of puzzle to present
    var baseDifficulty: Difficulty   // Starting difficulty
    var puzzleCount: Int             // How many puzzles to solve
    var unlockDuration: TimeInterval // Seconds the app stays unlocked after success

    init(
        puzzleType: PuzzleType = .chess,
        baseDifficulty: Difficulty = .easy,
        puzzleCount: Int = 1,
        unlockDuration: TimeInterval = 300 // 5 minutes default
    ) {
        self.puzzleType = puzzleType
        self.baseDifficulty = baseDifficulty
        self.puzzleCount = puzzleCount
        self.unlockDuration = unlockDuration
    }
}

/// Known app URL schemes for easy configuration
enum KnownApp: String, CaseIterable {
    case instagram = "Instagram"
    case tiktok = "TikTok"
    case twitter = "Twitter/X"
    case facebook = "Facebook"
    case youtube = "YouTube"
    case reddit = "Reddit"
    case snapchat = "Snapchat"

    var urlScheme: String {
        switch self {
        case .instagram: return "instagram://"
        case .tiktok: return "snssdk1128://"
        case .twitter: return "twitter://"
        case .facebook: return "fb://"
        case .youtube: return "youtube://"
        case .reddit: return "reddit://"
        case .snapchat: return "snapchat://"
        }
    }

    /// Creates a default AppRule for this known app
    func createRule() -> AppRule {
        AppRule(name: rawValue, urlScheme: urlScheme)
    }
}
