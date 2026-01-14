//
//  ContentView.swift
//  BrainTax
//
//  Main content view that displays puzzles
//

import SwiftUI

struct ContentView: View {
    @StateObject private var puzzleStore = PuzzleStore()
    
    var body: some View {
        NavigationView {
            if let puzzle = puzzleStore.currentPuzzle {
                PuzzleView(puzzle: puzzle)
                    .navigationTitle("BrainTax")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                VStack {
                    ProgressView()
                    Text("Loading puzzles...")
                        .foregroundColor(.secondary)
                        .padding()
                }
                .navigationTitle("BrainTax")
            }
        }
    }
}

#Preview {
    ContentView()
}
