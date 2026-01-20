//
//  HomeView.swift
//  BrainTax
//
//  Main view showing all tracked apps and their lock status
//

import SwiftUI

struct HomeView: View {
    @State private var appStatuses: [String: Bool] = [:] // app name -> isBlocked
    @State private var isLoading = true
    @State private var selectedRule: AppRule?

    // Hardcoded test rules for now
    let rules: [AppRule] = [
        AppRule(
            name: "Instagram",
            urlScheme: "instagram://",
            challengeConfig: ChallengeConfig(unlockDuration: 300)
        ),
        AppRule(
            name: "TikTok",
            urlScheme: "snssdk1128://",
            challengeConfig: ChallengeConfig(unlockDuration: 300)
        ),
        AppRule(
            name: "Twitter",
            urlScheme: "twitter://",
            challengeConfig: ChallengeConfig(unlockDuration: 300)
        ),
        AppRule(
            name: "YouTube",
            urlScheme: "youtube://",
            challengeConfig: ChallengeConfig(unlockDuration: 300)
        ),
        AppRule(
            name: "Reddit",
            urlScheme: "reddit://",
            challengeConfig: ChallengeConfig(unlockDuration: 300)
        )
    ]

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Checking app status...")
                } else {
                    appList
                }
            }
            .navigationTitle("BrainTax")
            .refreshable {
                await loadAppStatuses()
            }
            .fullScreenCover(item: $selectedRule) { rule in
                ChallengeView(rule: rule) {
                    selectedRule = nil
                    Task {
                        await loadAppStatuses()
                    }
                }
            }
        }
        .task {
            await loadAppStatuses()
        }
    }

    // MARK: - App List

    private var appList: some View {
        List {
            Section {
                ForEach(rules) { rule in
                    AppRowView(
                        rule: rule,
                        isLocked: appStatuses[rule.name] ?? false,
                        onTap: {
                            if appStatuses[rule.name] ?? false {
                                selectedRule = rule
                            } else {
                                openApp(rule)
                            }
                        }
                    )
                }
            } header: {
                Text("Tracked Apps")
            } footer: {
                Text("Tap a locked app to complete a challenge and unlock it.")
            }
        }
    }

    // MARK: - Actions

    private func loadAppStatuses() async {
        isLoading = true

        let controller = NextDNSController()
        guard controller.isConfigured else {
            // If not configured, assume all unlocked
            for rule in rules {
                appStatuses[rule.name] = false
            }
            isLoading = false
            return
        }

        for rule in rules {
            do {
                appStatuses[rule.name] = try await controller.isAppBlocked(name: rule.name)
            } catch {
                appStatuses[rule.name] = false
            }
        }

        isLoading = false
    }

    private func openApp(_ rule: AppRule) {
        if let url = URL(string: rule.urlScheme) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - App Row View

struct AppRowView: View {
    let rule: AppRule
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // App icon placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(appColor.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: appIcon)
                        .font(.title2)
                        .foregroundColor(appColor)
                }

                // App info
                VStack(alignment: .leading, spacing: 4) {
                    Text(rule.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(isLocked ? "Locked - Tap to unlock" : "Unlocked")
                        .font(.caption)
                        .foregroundColor(isLocked ? .red : .green)
                }

                Spacer()

                // Lock indicator
                Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                    .font(.title2)
                    .foregroundColor(isLocked ? .red : .green)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private var appColor: Color {
        switch rule.name.lowercased() {
        case "instagram": return .pink
        case "tiktok": return .black
        case "twitter": return .blue
        case "youtube": return .red
        case "reddit": return .orange
        case "facebook": return .blue
        case "snapchat": return .yellow
        default: return .gray
        }
    }

    private var appIcon: String {
        switch rule.name.lowercased() {
        case "instagram": return "camera.fill"
        case "tiktok": return "music.note"
        case "twitter": return "bird.fill"
        case "youtube": return "play.rectangle.fill"
        case "reddit": return "bubble.left.and.bubble.right.fill"
        case "facebook": return "person.2.fill"
        case "snapchat": return "camera.viewfinder"
        default: return "app.fill"
        }
    }
}

// MARK: - Challenge View

struct ChallengeView: View {
    let rule: AppRule
    let onDismiss: () -> Void

    @State private var stateMachine = UnlockStateMachine()
    @State private var timer = TimerManager()
    @StateObject private var puzzleStore = PuzzleStore()
    @State private var isSolved = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isSolved {
                    successView
                } else if let puzzle = puzzleStore.currentPuzzle {
                    challengeContent(puzzle: puzzle)
                } else {
                    ProgressView("Loading puzzle...")
                }
            }
            .padding()
            .navigationTitle("Unlock \(rule.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
        }
        .onAppear {
            stateMachine.beginChallenge(for: rule)
        }
    }

    // MARK: - Challenge Content

    private func challengeContent(puzzle: AnyPuzzle) -> some View {
        VStack(spacing: 16) {
            // App being unlocked
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.orange)
                Text("Solve to unlock \(rule.name)")
                    .font(.headline)
            }

            Divider()

            // Puzzle
            PuzzleViewCompact(puzzle: puzzle) { success in
                if success {
                    handleSuccess()
                }
            }
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("\(rule.name) Unlocked!")
                .font(.title2)
                .fontWeight(.semibold)

            if timer.isRunning {
                VStack(spacing: 4) {
                    Text("Unlocked for")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(timer.formattedTime)
                        .font(.title.monospacedDigit())
                        .foregroundColor(.green)
                }
            }

            Button {
                openApp()
            } label: {
                Label("Open \(rule.name)", systemImage: "arrow.up.forward.app")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            Button("Done") {
                onDismiss()
            }
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Actions

    private func handleSuccess() {
        stateMachine.completeChallenge(success: true)
        isSolved = true

        // Unblock DNS
        Task {
            await unblockDNS()
        }

        // Start timer
        if case .unlocked(let until) = stateMachine.state {
            timer.start(until: until) {
                // Re-block when timer expires
                Task {
                    await reblockDNS()
                }
            }
        }
    }

    private func openApp() {
        if let url = URL(string: rule.urlScheme) {
            UIApplication.shared.open(url)
        }
    }

    private func unblockDNS() async {
        let controller = NextDNSController()
        guard controller.isConfigured else { return }

        do {
            try await controller.unblockApp(name: rule.name)
        } catch {
            print("Failed to unblock DNS: \(error)")
        }
    }

    private func reblockDNS() async {
        let controller = NextDNSController()
        guard controller.isConfigured else { return }

        do {
            try await controller.blockApp(name: rule.name)
        } catch {
            print("Failed to re-block DNS: \(error)")
        }
    }
}

// MARK: - Compact Puzzle View

struct PuzzleViewCompact: View {
    let puzzle: AnyPuzzle
    let onSolve: (Bool) -> Void

    @StateObject private var viewModel = PuzzleViewModel()

    var body: some View {
        VStack(spacing: 12) {
            // Question
            Text(puzzle.question)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Chess board
            if let chessPuzzle = puzzle.asChessPuzzle() {
                ChessPuzzleView(
                    puzzle: chessPuzzle,
                    resetToken: viewModel.puzzleResetToken,
                    onMove: { move in
                        let correct = viewModel.submitAnswer(move)
                        if viewModel.isSolved {
                            onSolve(true)
                        }
                        return correct
                    }
                )
                .id(chessPuzzle.id)
            }

            // Feedback
            if !viewModel.feedbackMessage.isEmpty {
                Text(viewModel.feedbackMessage)
                    .font(.caption)
                    .foregroundColor(viewModel.feedbackColor)
            }
        }
        .onAppear {
            viewModel.loadPuzzle(puzzle)
        }
    }
}

#Preview {
    HomeView()
}
