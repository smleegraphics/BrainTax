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

    private let userPuzzlesDirectory = "user_puzzles"

    private init() {}

    /// Load all puzzles (bundled and user-added)
    func loadAllPuzzles() -> [any Puzzle] {
        var puzzles: [any Puzzle] = []

        // Load bundled puzzles from all *_puzzles.json files
        puzzles.append(contentsOf: loadBundledPuzzles())

        // Load user-added puzzles (for future implementation)
        // puzzles.append(contentsOf: loadUserPuzzles())

        return puzzles
    }

    /// Load bundled puzzles from all *_puzzles.json files in the bundle
    func loadBundledPuzzles() -> [any Puzzle] {
        var puzzles: [any Puzzle] = []

        guard let resourcePath = Bundle.main.resourcePath else {
            print("Could not get bundle resource path")
            return []
        }

        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(atPath: resourcePath) else {
            print("Could not list bundle contents")
            return []
        }

        for file in files where file.hasSuffix("_puzzles.json") {
            // Infer type from filename (e.g., "chess_puzzles.json" -> "chess")
            let typeName = String(file.dropLast("_puzzles.json".count))

            let resourceName = String(file.dropLast(".json".count))
            guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                print("Could not load \(file)")
                continue
            }

            print("Loading puzzles from \(file) (type: \(typeName))")
            puzzles.append(contentsOf: parsePuzzleJSON(data: data, defaultType: typeName))
        }

        return puzzles
    }
    
    /// Parse puzzle JSON data into Puzzle objects
    /// - Parameters:
    ///   - data: JSON data to parse
    ///   - defaultType: Type to use if puzzle doesn't have explicit "type" field (inferred from filename)
    func parsePuzzleJSON(data: Data, defaultType: String? = nil) -> [any Puzzle] {
        // Support two formats:
        // 1) { "puzzles": [ ... ] }
        // 2) [ ... ]
        var rawArray: [[String: Any]] = []
        if let topObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let puzzlesArray = topObject["puzzles"] as? [[String: Any]] {
            rawArray = puzzlesArray
        } else if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            rawArray = array
        } else {
            print("Invalid puzzle JSON format")
            return []
        }

        var puzzles: [any Puzzle] = []

        for puzzleDict in rawArray {
            // Use explicit type if present, otherwise fall back to defaultType from filename
            let typeString = (puzzleDict["type"] as? String) ?? defaultType
            guard let typeString, let type = PuzzleType(rawValue: typeString) else {
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
        // Common required fields
        guard let id = dict["id"] as? String else { return nil }

        // FEN can be present as "fen"
        guard let fen = dict["fen"] as? String else { return nil }

        // Moves can be provided as our internal "correctMoves" or lichess-style "solution"
        let moves: [String]
        if let correctMoves = dict["correctMoves"] as? [String] {
            moves = correctMoves
        } else if let solution = dict["solution"] as? [String] {
            moves = solution
        } else {
            return nil
        }

        // Question: accept provided question or synthesize a default
        let question = (dict["question"] as? String) ?? "Find the winning line from this position."

        // Difficulty: accept provided difficulty or map from rating if available
        let difficulty: Difficulty
        if let difficultyString = dict["difficulty"] as? String, let d = Difficulty(rawValue: difficultyString) {
            difficulty = d
        } else if let rating = dict["rating"] as? Int {
            if rating < 800 {
                difficulty = .easy
            } else if rating < 1600 {
                difficulty = .medium
            } else {
                difficulty = .hard
            }
        } else {
            // Default difficulty if none provided
            difficulty = .medium
        }

        let hint = dict["hint"] as? String

        return ChessPuzzle(
            id: id,
            question: question,
            difficulty: difficulty,
            hint: hint,
            fen: fen,
            correctMoves: moves
        )
    }
    
    /// Load user-added puzzles from Documents directory (for future implementation)
    func loadUserPuzzles() -> [any Puzzle] {
        // TODO: Implement user puzzle loading from Documents directory
        return []
    }
}

