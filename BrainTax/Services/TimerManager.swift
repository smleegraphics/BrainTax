//
//  TimerManager.swift
//  BrainTax
//
//  Manages countdown timers for unlock duration
//

import Foundation

/// Manages a countdown timer for unlock durations
@Observable
class TimerManager {
    /// Remaining time in seconds
    private(set) var remainingTime: TimeInterval = 0

    /// Whether the timer is currently running
    private(set) var isRunning: Bool = false

    /// Target end time
    private var endTime: Date?

    /// Timer instance
    private var timer: Timer?

    /// Callback when timer expires
    private var onExpire: (() -> Void)?

    deinit {
        stop()
    }

    // MARK: - Public API

    /// Starts a countdown timer
    /// - Parameters:
    ///   - duration: Duration in seconds
    ///   - onExpire: Callback when timer reaches zero
    func start(duration: TimeInterval, onExpire: @escaping () -> Void) {
        stop() // Stop any existing timer

        self.onExpire = onExpire
        self.endTime = Date().addingTimeInterval(duration)
        self.remainingTime = duration
        self.isRunning = true

        // Update every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    /// Starts a timer that counts down to a specific end time
    /// - Parameters:
    ///   - until: The target end date
    ///   - onExpire: Callback when timer reaches zero
    func start(until: Date, onExpire: @escaping () -> Void) {
        let duration = until.timeIntervalSinceNow
        if duration > 0 {
            start(duration: duration, onExpire: onExpire)
        } else {
            onExpire()
        }
    }

    /// Stops the timer
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        onExpire = nil
    }

    // MARK: - Private

    private func tick() {
        guard let endTime = endTime else { return }

        remainingTime = max(0, endTime.timeIntervalSinceNow)

        if remainingTime <= 0 {
            stop()
            onExpire?()
        }
    }

    // MARK: - Formatting

    /// Returns remaining time as formatted string (MM:SS)
    var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Returns remaining time as formatted string with hours if needed
    var formattedTimeLong: String {
        let hours = Int(remainingTime) / 3600
        let minutes = (Int(remainingTime) % 3600) / 60
        let seconds = Int(remainingTime) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
