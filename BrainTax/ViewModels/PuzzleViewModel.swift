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
    
    // Chess-specific
    @Published var chessBoard: ChessBoard?
    
    private var puzzleType: PuzzleType = .chess
    
    /// Load a puzzle into the view model
    func loadPuzzle(_ puzzle: AnyPuzzle) {
        currentPuzzle = puzzle
        puzzleType = puzzle.type
        isSolved = false
        feedbackMessage = ""
        showHint = false
        
        // Initialize chess board if it's a chess puzzle
        if let chessPuzzle = puzzle.asChessPuzzle() {
            let board = ChessBoard()
            board.loadFromFEN(chessPuzzle.fen)
            chessBoard = board
        }
    }
    
    /// Submit an answer for the current puzzle
    func submitAnswer(_ answer: Any) {
        guard let puzzle = currentPuzzle else { return }
        
        if puzzle.isAnswerCorrect(answer) {
            isSolved = true
            feedbackMessage = "Correct! 🎉"
            feedbackColor = .green
        } else {
            feedbackMessage = "Incorrect. Try again!"
            feedbackColor = .red
        }
    }
    
    /// Handle move from chess board
    func handleChessMove(_ move: String) {
        submitAnswer(move)
        
        // Update legal moves visualization (for future enhancement)
        if let board = chessBoard, !isSolved {
            board.legalMoves = []
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
