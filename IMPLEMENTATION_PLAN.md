# BrainTax: Behavioral Friction App

## Overview
A personal iOS app that reduces impulsive app usage through behavioral friction - requiring puzzle challenges before accessing distracting apps. Uses Shortcuts/App Intents integration instead of Screen Time APIs.

**No special entitlements required. No App Store. Personal use.**

## Core Concept
1. User creates iOS Shortcut that opens BrainTax instead of Instagram
2. User replaces Instagram icon on Home Screen with this Shortcut
3. Tapping the shortcut → BrainTax opens → Challenge presented
4. Complete challenge → BrainTax opens Instagram via URL scheme

---

## Architecture Overview

```
UI (SwiftUI)
 ├─ Home / Status         → Current state, quick actions
 ├─ Challenge View        → Chess puzzles / Quiz presentation
 ├─ Settings              → App rules, preferences
 └─ History / Streaks     → Usage stats, achievements

Core Logic
 ├─ ChallengeEngine       → Selects puzzles, scales difficulty
 ├─ UnlockStateMachine    → Manages locked/unlocking/unlocked states
 ├─ TimerManager          → Handles unlock duration countdown
 └─ Persistence           → UserDefaults storage

Integrations
 ├─ Shortcuts / App Intents  → iOS automation entry point
 ├─ Notifications            → Usage reminders
 └─ (Optional) DNS Controller → External HTTP API for blocking
```

---

## State Machine

### LockState
```swift
enum LockState {
    case locked              // Must complete challenge
    case unlocking           // Currently solving puzzle
    case unlocked(until: Date)  // Temporary access granted
}
```

### UnlockSession
```swift
struct UnlockSession {
    let startTime: Date
    let duration: TimeInterval
    let challengeType: ChallengeType
    let success: Bool
}
```

### State Transitions
```
┌──────────┐   start challenge   ┌───────────┐
│  locked  │────────────────────►│ unlocking │
└──────────┘                     └───────────┘
     ▲                                 │
     │ timer expires          success  │ fail
     │                                 ▼
┌────────────────┐            ┌──────────┐
│ unlocked(until)│◄───────────│  locked  │
└────────────────┘            └──────────┘
```

### ChallengeEngine
- Selects challenges based on rules (type, difficulty)
- Scales difficulty based on: time of day, daily attempt count, streak
- Tracks completion stats for adaptive difficulty

---

## Phase 1: Core Models & State Machine

### New Files

**`BrainTax/Models/LockState.swift`**
```swift
enum LockState: Codable {
    case locked
    case unlocking
    case unlocked(until: Date)
}

struct UnlockSession: Codable {
    let startTime: Date
    let duration: TimeInterval
    let challengeType: ChallengeType
    let success: Bool
}
```

**`BrainTax/Models/AppRule.swift`**
```swift
struct AppRule: Codable, Identifiable {
    var id: UUID
    var name: String                    // "Instagram", "TikTok"
    var urlScheme: String               // "instagram://", "tiktok://"
    var isEnabled: Bool
    var conditions: [RuleCondition]     // When to require challenge
    var challengeConfig: ChallengeConfig
}

struct RuleCondition: Codable {
    var type: ConditionType             // .timeOfDay, .openCount, .always
    var startTime: Date?                // For time-based
    var endTime: Date?
    var maxDailyOpens: Int?             // For count-based
}

struct ChallengeConfig: Codable {
    var puzzleType: String              // "chess", "any"
    var baseDifficulty: Difficulty
    var puzzleCount: Int
    var unlockDuration: TimeInterval    // How long app stays unlocked after success
}
```

**`BrainTax/Models/UsageStats.swift`**
```swift
struct UsageStats: Codable {
    var appId: UUID
    var date: Date
    var openCount: Int
    var challengesCompleted: Int
    var challengesFailed: Int
    var sessions: [UnlockSession]
}
```

**`BrainTax/Services/UnlockStateMachine.swift`**
```swift
@Observable
class UnlockStateMachine {
    private(set) var state: LockState = .locked

    func beginChallenge()                    // locked → unlocking
    func completeChallenge(success: Bool, duration: TimeInterval)  // unlocking → unlocked/locked
    func checkExpiration() -> Bool           // Auto-transition unlocked → locked if expired
}
```

**`BrainTax/Services/TimerManager.swift`**
```swift
@Observable
class TimerManager {
    private(set) var remainingTime: TimeInterval = 0
    private(set) var isRunning: Bool = false

    func start(duration: TimeInterval, onExpire: @escaping () -> Void)
    func stop()
}
```

---

## Phase 2: Challenge Engine

**`BrainTax/Services/ChallengeEngine.swift`**
```swift
@Observable
class ChallengeEngine {
    func selectChallenge(for config: ChallengeConfig, stats: UsageStats) -> AnyPuzzle
    func calculateDifficulty(base: Difficulty, stats: UsageStats, config: ChallengeConfig) -> Difficulty
}
```

**Difficulty Scaling Logic:**
- Base difficulty from rule config
- +1 level if opened > 3 times today
- +1 level if after 10pm
- +1 level for each consecutive failure
- Cap at .hard

---

## Phase 3: App Intents / Shortcuts Integration

**`BrainTax/Intents/OpenAppIntent.swift`**
```swift
import AppIntents

struct OpenAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Open App with Challenge"

    @Parameter(title: "App")
    var appName: String

    func perform() async throws -> some IntentResult {
        // 1. Find rule for appName
        // 2. Check if challenge needed
        // 3. Open BrainTax with deep link: braintax://challenge?app=instagram
        // 4. After challenge complete, open target app
    }
}
```

**`BrainTax/Intents/AppShortcuts.swift`**
```swift
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenAppIntent(),
            phrases: ["Open \(.applicationName) for Instagram"],
            shortTitle: "Open Instagram",
            systemImageName: "brain"
        )
    }
}
```

---

## Phase 4: Persistence & State

**`BrainTax/Services/PersistenceManager.swift`**
- Uses UserDefaults for simplicity (personal app)
- Stores: AppRules, UsageStats, current LockState
- Daily reset of usage counters

**`BrainTax/Services/NotificationManager.swift`**
- Schedule reminders: "You've opened Instagram 5 times today"
- Optional: Daily summary of challenges completed

---

## Phase 5: Views

**`BrainTax/Views/MainTabView.swift`**
```
Tabs:
- Home (status overview)
- Challenge (puzzle practice)
- Settings (app rules, preferences)
- History (streaks, statistics)
```

**`BrainTax/Views/Home/HomeView.swift`**
- Current lock state indicator
- Quick unlock status (time remaining if unlocked)
- Today's stats summary (challenges completed, apps opened)
- Quick action buttons

**`BrainTax/Views/Challenge/ChallengeView.swift`**
- Full-screen challenge presentation
- Progress indicator (1 of N puzzles)
- Timer display (if applicable)
- Reuses existing `ChessPuzzleView` for chess challenges
- On success: opens target app via URL scheme
- On failure: returns to locked state

**`BrainTax/Views/Settings/SettingsView.swift`**
- App rules list with enable/disable toggles
- Add/edit/delete rules
- Global preferences (default unlock duration, difficulty)

**`BrainTax/Views/Settings/RuleEditorView.swift`**
- App name and URL scheme input (with preset picker)
- Condition configuration (time of day, open count, always)
- Challenge settings (puzzle type, difficulty, count, unlock duration)

**`BrainTax/Views/History/HistoryView.swift`**
- Daily/weekly usage charts
- Current streak display
- Challenges completed vs failed
- Per-app breakdown

---

## Phase 6: Deep Linking

**URL Scheme:** `braintax://`

**Routes:**
- `braintax://challenge?app=instagram` - Start challenge for specific app
- `braintax://rules` - Open rules list
- `braintax://stats` - Open statistics

**`BrainTax/BrainTaxApp.swift`**
```swift
.onOpenURL { url in
    DeepLinkRouter.handle(url)
}
```

---

## Known App URL Schemes
```swift
static let knownApps: [String: String] = [
    "Instagram": "instagram://",
    "TikTok": "snssdk1128://",
    "Twitter/X": "twitter://",
    "Facebook": "fb://",
    "YouTube": "youtube://",
    "Reddit": "reddit://",
    "Snapchat": "snapchat://",
]
```

---

## Files Summary

### New Files (16)
| File | Purpose |
|------|---------|
| `Models/LockState.swift` | LockState enum + UnlockSession struct |
| `Models/AppRule.swift` | Rule configuration + conditions |
| `Models/UsageStats.swift` | Usage tracking + session history |
| `Services/UnlockStateMachine.swift` | State transitions (locked/unlocking/unlocked) |
| `Services/TimerManager.swift` | Unlock duration countdown |
| `Services/ChallengeEngine.swift` | Challenge selection & difficulty scaling |
| `Services/PersistenceManager.swift` | UserDefaults storage |
| `Services/NotificationManager.swift` | Local notifications |
| `Services/DeepLinkRouter.swift` | URL handling |
| `Intents/OpenAppIntent.swift` | App Intent for Shortcuts |
| `Intents/AppShortcuts.swift` | Shortcut phrases |
| `Views/MainTabView.swift` | Tab navigation (Home, Challenge, Settings, History) |
| `Views/Home/HomeView.swift` | Status overview |
| `Views/Challenge/ChallengeView.swift` | Challenge gate (full-screen) |
| `Views/Settings/SettingsView.swift` | Rules list + preferences |
| `Views/Settings/RuleEditorView.swift` | Rule configuration |
| `Views/History/HistoryView.swift` | Streaks + statistics |

### Modified Files (2)
| File | Changes |
|------|---------|
| `BrainTaxApp.swift` | Deep link handling, tab structure |
| `Services/PuzzleStore.swift` | Filter by difficulty/type for ChallengeEngine |

---

## User Setup Flow
1. Open BrainTax → Go to Rules tab
2. Add rule: "Instagram" with URL scheme "instagram://"
3. Configure: Always require 1 medium chess puzzle
4. Open iOS Shortcuts app
5. Create shortcut: "Open App with Challenge" → Instagram
6. Add shortcut to Home Screen, replace Instagram icon
7. Now tapping "Instagram" → BrainTax challenge → Instagram

---

## Verification Steps
1. Build app, test existing puzzle flow still works
2. Create AppRule, persist to UserDefaults, reload
3. Test LockStateMachine transitions
4. Test ChallengeEngine difficulty scaling
5. Build OpenAppIntent, test in Shortcuts app
6. Test deep link: `braintax://challenge?app=instagram`
7. End-to-end: Shortcut → Challenge → Target app opens
8. Test notifications for usage reminders

---

## Optional: DNS Blocking (HTTP API)

**`BrainTax/Services/DNSBlockingController.swift`**
```swift
// HTTP API integration for external DNS blocking (Pi-hole, NextDNS, etc.)
protocol DNSBlockingController {
    func block(domains: [String]) async throws
    func unblock(domains: [String]) async throws
    var isAvailable: Bool { get async }
}

class HTTPDNSBlockingController: DNSBlockingController {
    let baseURL: URL
    let apiKey: String?

    func block(domains: [String]) async throws {
        // POST to external API to add domains to blocklist
    }

    func unblock(domains: [String]) async throws {
        // POST to external API to remove domains from blocklist
    }
}
```

**Use Cases:**
- Pi-hole on home network
- NextDNS with API access
- Custom local proxy

This is optional and requires external infrastructure. The app functions without it.

---

## Implementation Order

**Phase 1: Core Models** (foundation)
- LockState, UnlockSession, AppRule, UsageStats models
- UnlockStateMachine + TimerManager

**Phase 2: Challenge Engine** (uses existing puzzle infrastructure)
- ChallengeEngine with difficulty scaling
- Connect to existing PuzzleStore

**Phase 3: Persistence** (enable state survival)
- PersistenceManager for UserDefaults
- Save/load rules, stats, current state

**Phase 4: Views** (user interface)
- MainTabView with 4 tabs
- HomeView, ChallengeView, SettingsView, HistoryView
- RuleEditorView

**Phase 5: Integrations** (shortcuts + notifications)
- Deep link routing
- App Intents for Shortcuts
- Notification scheduling

**Phase 6: Polish** (optional)
- DNS blocking integration
- Charts for history view
- Streak tracking
