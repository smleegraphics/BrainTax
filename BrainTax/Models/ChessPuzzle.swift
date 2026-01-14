//
//  ChessPuzzle.swift
//  BrainTax
//
//  Chess puzzle model conforming to Puzzle protocol
//

import Foundation

/// Represents a chess puzzle with FEN position and correct moves
struct ChessPuzzle: Puzzle {
    let id: String
    let type: PuzzleType = .chess
    let question: String
    let difficulty: Difficulty
    let hint: String?
    
    /// FEN (Forsyth-Edwards Notation) string representing the board position
    let fen: String
    
    /// Array of correct moves in UCI (Universal Chess Interface) notation (e.g., "e2e4")
    let correctMoves: [String]
    
    /// Validates if the given move is correct
    /// - Parameter answer: The move string in UCI notation (e.g., "e2e4")
    func isAnswerCorrect(_ answer: Any) -> Bool {
        guard let moveString = answer as? String else { return false }
        // Convert to lowercase for case-insensitive comparison
        let normalizedMove = moveString.lowercased().trimmingCharacters(in: .whitespaces)
        return correctMoves.contains { correctMove in
            correctMove.lowercased() == normalizedMove
        }
    }
}
