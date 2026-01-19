//
//  PuzzleViewModel.swift
//  BrainTax
//
//  ViewModel for managing puzzle state and logic (MVVM pattern)
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing puzzle state and interactions
@MainActor
class PuzzleViewModel: ObservableObject {
    @Published var currentPuzzle: AnyPuzzle?
    @Published var feedbackMessage: String = ""
    @Published var feedbackColor: Color = .primary
    @Published var isSolved: Bool = false
    @Published var showHint: Bool = false
    @Published var puzzleResetToken: UUID = UUID()

    /// Load a puzzle into the view model
    func loadPuzzle(_ puzzle: AnyPuzzle) {
        currentPuzzle = puzzle
        isSolved = false
        feedbackMessage = ""
        showHint = false
        puzzleResetToken = UUID()
    }

    /// Submit an answer for the current puzzle
    /// Returns true if the answer is correct
    @discardableResult
    func submitAnswer(_ answer: Any) -> Bool {
        guard let puzzle = currentPuzzle else { return false }

        if puzzle.isAnswerCorrect(answer) {
            isSolved = true
            feedbackMessage = "Correct!"
            feedbackColor = .green
            return true
        } else {
            feedbackMessage = "Incorrect. Try again!"
            feedbackColor = .red
            return false
        }
    }

    /// Show hint for current puzzle
    func showPuzzleHint() {
        showHint = true
        if let hint = currentPuzzle?.hint {
            feedbackMessage = "Hint: \(hint)"
            feedbackColor = .orange
        } else {
            feedbackMessage = "No hint available for this puzzle."
            feedbackColor = .secondary
        }
    }

    /// Reset current puzzle
    func resetPuzzle() {
        guard let puzzle = currentPuzzle else { return }
        loadPuzzle(puzzle)
    }
}
