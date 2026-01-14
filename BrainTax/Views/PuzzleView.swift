//
//  PuzzleView.swift
//  BrainTax
//
//  Main puzzle view that displays puzzles with appropriate interactive area
//

import SwiftUI

/// Type-erased wrapper for puzzles that can be used in SwiftUI views
struct AnyPuzzle: Identifiable {
    let id: String
    let type: PuzzleType
    let question: String
    let difficulty: Difficulty
    let hint: String?
    private let _isAnswerCorrect: (Any) -> Bool
    private let _underlying: Any
    
    init<P: Puzzle>(_ puzzle: P) {
        self.id = puzzle.id
        self.type = puzzle.type
        self.question = puzzle.question
        self.difficulty = puzzle.difficulty
        self.hint = puzzle.hint
        self._isAnswerCorrect = puzzle.isAnswerCorrect
        self._underlying = puzzle
    }
    
    func isAnswerCorrect(_ answer: Any) -> Bool {
        _isAnswerCorrect(answer)
    }
    
    func asChessPuzzle() -> ChessPuzzle? {
        _underlying as? ChessPuzzle
    }
}

struct PuzzleView: View {
    @StateObject private var viewModel = PuzzleViewModel()
    let puzzle: AnyPuzzle
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header section
                headerSection
                
                Divider()
                
                // Question area
                questionSection
                
                Divider()
                
                // Interactive area (changes based on puzzle type)
                interactiveArea
                
                Divider()
                
                // Controls section
                controlsSection
                
                // Feedback area
                feedbackSection
            }
            .padding()
        }
        .onAppear {
            viewModel.loadPuzzle(puzzle)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(puzzle.type.rawValue.capitalized)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(puzzle.difficulty.displayName)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(difficultyColor(for: puzzle.difficulty).opacity(0.2))
                    .foregroundColor(difficultyColor(for: puzzle.difficulty))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Question Section
    
    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Question")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(puzzle.question)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Interactive Area
    
    @ViewBuilder
    private var interactiveArea: some View {
        if puzzle.type == .chess {
            chessInteractiveArea
        } else {
            // Placeholder for geography puzzles
            Text("Geography puzzles coming soon")
                .foregroundColor(.secondary)
        }
    }
    
    private var chessInteractiveArea: some View {
        VStack(spacing: 16) {
            if let board = viewModel.chessBoard {
                ChessBoardView(board: board) { move in
                    viewModel.handleChessMove(move)
                }
                .padding()
            } else {
                ProgressView()
            }
        }
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        HStack(spacing: 16) {
            // Submit button (for future use - chess handles moves directly)
            if puzzle.type != .chess {
                Button("Submit") {
                    // Handle submission for non-chess puzzles
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Hint button
            Button("Hint") {
                viewModel.showPuzzleHint()
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.showHint || viewModel.isSolved)
            
            // Reset button
            Button("Reset") {
                viewModel.resetPuzzle()
            }
            .buttonStyle(.bordered)
            
            Spacer()
        }
    }
    
    // MARK: - Feedback Section
    
    @ViewBuilder
    private var feedbackSection: some View {
        if !viewModel.feedbackMessage.isEmpty {
            Text(viewModel.feedbackMessage)
                .font(.subheadline)
                .foregroundColor(viewModel.feedbackColor)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(viewModel.feedbackColor.opacity(0.1))
                .cornerRadius(8)
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Helper Methods
    
    private func difficultyColor(for difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy:
            return .green
        case .medium:
            return .orange
        case .hard:
            return .red
        }
    }
}

