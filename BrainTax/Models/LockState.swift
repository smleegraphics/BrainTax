//
//  LockState.swift
//  BrainTax
//
//  Core state machine types for app locking behavior
//

import Foundation

/// Represents the current lock state for a protected app
enum LockState: Codable, Equatable {
    case locked              // Must complete challenge to access
    case unlocking           // Currently solving a puzzle
    case unlocked(until: Date)  // Temporary access granted

    var isLocked: Bool {
        if case .locked = self { return true }
        return false
    }

    var isUnlocked: Bool {
        if case .unlocked = self { return true }
        return false
    }

    var isUnlocking: Bool {
        if case .unlocking = self { return true }
        return false
    }

    /// Returns remaining time if unlocked, nil otherwise
    var remainingTime: TimeInterval? {
        if case .unlocked(let until) = self {
            let remaining = until.timeIntervalSinceNow
            return remaining > 0 ? remaining : nil
        }
        return nil
    }
}

/// Records a single unlock session for history/stats
struct UnlockSession: Codable, Identifiable {
    let id: UUID
    let appRuleId: UUID
    let startTime: Date
    let duration: TimeInterval
    let challengeType: PuzzleType
    let success: Bool

    init(appRuleId: UUID, startTime: Date = Date(), duration: TimeInterval, challengeType: PuzzleType, success: Bool) {
        self.id = UUID()
        self.appRuleId = appRuleId
        self.startTime = startTime
        self.duration = duration
        self.challengeType = challengeType
        self.success = success
    }
}
