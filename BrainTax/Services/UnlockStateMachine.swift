//
//  UnlockStateMachine.swift
//  BrainTax
//
//  Manages state transitions for app locking
//

import Foundation

/// Manages the lock state for protected apps
@Observable
class UnlockStateMachine {
    /// Current lock state
    private(set) var state: LockState = .locked

    /// The app rule being processed (if any)
    private(set) var currentRule: AppRule?

    /// History of unlock sessions
    private(set) var sessions: [UnlockSession] = []

    /// Daily open counts per app rule ID
    private(set) var dailyOpenCounts: [UUID: Int] = [:]

    /// Date of last daily reset
    private var lastResetDate: Date = Date()

    init() {
        resetDailyCountsIfNeeded()
    }

    // MARK: - State Transitions

    /// Transition: locked → unlocking
    /// Call when user initiates a challenge for an app
    func beginChallenge(for rule: AppRule) {
        guard state.isLocked else { return }
        currentRule = rule
        state = .unlocking
    }

    /// Transition: unlocking → unlocked OR unlocking → locked
    /// Call when user completes or fails a challenge
    func completeChallenge(success: Bool) {
        guard state.isUnlocking, let rule = currentRule else { return }

        if success {
            let unlockUntil = Date().addingTimeInterval(rule.challengeConfig.unlockDuration)
            state = .unlocked(until: unlockUntil)

            // Record session
            let session = UnlockSession(
                appRuleId: rule.id,
                duration: rule.challengeConfig.unlockDuration,
                challengeType: rule.challengeConfig.puzzleType,
                success: true
            )
            sessions.append(session)

            // Increment daily open count
            dailyOpenCounts[rule.id, default: 0] += 1
        } else {
            state = .locked

            // Record failed session
            let session = UnlockSession(
                appRuleId: rule.id,
                duration: 0,
                challengeType: rule.challengeConfig.puzzleType,
                success: false
            )
            sessions.append(session)
        }
    }

    /// Check if unlock has expired and transition to locked if so
    /// Returns true if state changed to locked
    @discardableResult
    func checkExpiration() -> Bool {
        if case .unlocked(let until) = state {
            if Date() >= until {
                state = .locked
                currentRule = nil
                return true
            }
        }
        return false
    }

    /// Reset to locked state (e.g., user manually locks)
    func lock() {
        state = .locked
        currentRule = nil
    }

    // MARK: - Rule Evaluation

    /// Determines if a challenge is required for the given rule
    func requiresChallenge(for rule: AppRule) -> Bool {
        guard rule.isEnabled else { return false }

        resetDailyCountsIfNeeded()

        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        let openCount = dailyOpenCounts[rule.id, default: 0]

        // Check if any condition requires a challenge
        for condition in rule.conditions {
            if condition.requiresChallenge(currentHour: currentHour, dailyOpenCount: openCount) {
                return true
            }
        }

        return false
    }

    // MARK: - Daily Reset

    private func resetDailyCountsIfNeeded() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastResetDate) {
            dailyOpenCounts = [:]
            lastResetDate = Date()
        }
    }

    // MARK: - Stats

    /// Returns sessions for today
    var todaySessions: [UnlockSession] {
        let calendar = Calendar.current
        return sessions.filter { calendar.isDateInToday($0.startTime) }
    }

    /// Returns successful session count for today
    var todaySuccessCount: Int {
        todaySessions.filter { $0.success }.count
    }

    /// Returns failed session count for today
    var todayFailCount: Int {
        todaySessions.filter { !$0.success }.count
    }
}
