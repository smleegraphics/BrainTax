//
//  PuzzleStore.swift
//  BrainTax
//
//  Store for managing puzzle collection and current puzzle
//

import Foundation
import SwiftUI
import Combine

/// Observable store for managing puzzles
@MainActor
class PuzzleStore: ObservableObject {
    @Published var puzzles: [AnyPuzzle] = []
    @Published var currentPuzzleIndex: Int = 0
    
    private let loader = PuzzleLoader.shared
    
    init() {
        loadPuzzles()
    }
    
    /// Load all puzzles from various sources
    func loadPuzzles() {
        let loadedPuzzles = loader.loadAllPuzzles()
        puzzles = loadedPuzzles.map { AnyPuzzle($0) }
    }
    
    /// Get current puzzle
    var currentPuzzle: AnyPuzzle? {
        guard currentPuzzleIndex >= 0 && currentPuzzleIndex < puzzles.count else {
            return nil
        }
        return puzzles[currentPuzzleIndex]
    }
    
    /// Move to next puzzle
    func nextPuzzle() {
        if currentPuzzleIndex < puzzles.count - 1 {
            currentPuzzleIndex += 1
        }
    }
    
    /// Move to previous puzzle
    func previousPuzzle() {
        if currentPuzzleIndex > 0 {
            currentPuzzleIndex -= 1
        }
    }
}
