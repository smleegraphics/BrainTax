//
//  PuzzleLoader.swift
//  BrainTax
//
//  Service for loading puzzles from JSON files (bundled and user-added)
//

import Foundation

/// Service for loading and managing puzzles
class PuzzleLoader {
    static let shared = PuzzleLoader()
    
    private let bundledPuzzlesFileName = "bundled_puzzles"
    private let userPuzzlesDirectory = "user_puzzles"
    
    private init() {}
    
    /// Load all puzzles (bundled and user-added)
    func loadAllPuzzles() -> [any Puzzle] {
        var puzzles: [any Puzzle] = []
        
        // Load bundled puzzles
        puzzles.append(contentsOf: loadBundledPuzzles())
        
        // Load user-added puzzles (for future implementation)
        // puzzles.append(contentsOf: loadUserPuzzles())
        
        return puzzles
    }
    
    /// Load bundled puzzles from JSON file in app bundle
    func loadBundledPuzzles() -> [any Puzzle] {
        guard let url = Bundle.main.url(forResource: bundledPuzzlesFileName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Could not load bundled puzzles file")
            return []
        }
        
        return parsePuzzleJSON(data: data)
    }
    
    /// Parse puzzle JSON data into Puzzle objects
    func parsePuzzleJSON(data: Data) -> [any Puzzle] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let puzzlesArray = json["puzzles"] as? [[String: Any]] else {
            print("Invalid puzzle JSON format")
            return []
        }
        
        var puzzles: [any Puzzle] = []
        
        for puzzleDict in puzzlesArray {
            guard let typeString = puzzleDict["type"] as? String,
                  let type = PuzzleType(rawValue: typeString) else {
                continue
            }
            
            switch type {
            case .chess:
                if let chessPuzzle = parseChessPuzzle(from: puzzleDict) {
                    puzzles.append(chessPuzzle)
                }
            case .geography:
                // Geography puzzles will be implemented later
                break
            }
        }
        
        return puzzles
    }
    
    /// Parse a single chess puzzle from dictionary
    private func parseChessPuzzle(from dict: [String: Any]) -> ChessPuzzle? {
        guard let id = dict["id"] as? String,
              let question = dict["question"] as? String,
              let difficultyString = dict["difficulty"] as? String,
              let difficulty = Difficulty(rawValue: difficultyString),
              let fen = dict["fen"] as? String,
              let correctMoves = dict["correctMoves"] as? [String] else {
            return nil
        }
        
        let hint = dict["hint"] as? String
        
        return ChessPuzzle(
            id: id,
            question: question,
            difficulty: difficulty,
            hint: hint,
            fen: fen,
            correctMoves: correctMoves
        )
    }
    
    /// Load user-added puzzles from Documents directory (for future implementation)
    func loadUserPuzzles() -> [any Puzzle] {
        // TODO: Implement user puzzle loading from Documents directory
        return []
    }
}
