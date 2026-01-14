//
//  Puzzle.swift
//  BrainTax
//
//  Puzzle protocol that all puzzle types must conform to
//

import Foundation

/// Protocol that all puzzle types must conform to
protocol Puzzle: Codable, Identifiable {
    var id: String { get }
    var type: PuzzleType { get }
    var question: String { get }
    var difficulty: Difficulty { get }
    var hint: String? { get }
    
    /// Validates if the given answer is correct
    func isAnswerCorrect(_ answer: Any) -> Bool
}

/// Types of puzzles available in the app
enum PuzzleType: String, Codable {
    case chess
    case geography
}

/// Difficulty levels for puzzles
enum Difficulty: String, Codable {
    case easy
    case medium
    case hard
    
    var displayName: String {
        rawValue.capitalized
    }
}
