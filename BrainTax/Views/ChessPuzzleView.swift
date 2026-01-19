//
//  ChessPuzzleView.swift
//  BrainTax
//
//  Chess-specific puzzle view using ChessboardKit
//

import SwiftUI
import ChessboardKit
import ChessKit

/// View for displaying and interacting with chess puzzles
struct ChessPuzzleView: View {
    let puzzle: ChessPuzzle
    let resetToken: UUID
    let onMove: (String) -> Bool

    @State private var chessboardModel: ChessboardModel
    @State private var currentToken: UUID
    @State private var lastValidFen: String
    @State private var moveToken: UUID = UUID()

    private var sideToMoveText: String {
        let components = puzzle.fen.split(separator: " ")
        if components.count > 1 && components[1] == "b" {
            return "Black to move"
        }
        return "White to move"
    }

    private static func makePerspective(from fen: String) -> PieceColor {
        let components = fen.split(separator: " ")
        if components.count > 1 && components[1] == "b" {
            return .black
        }
        return .white
    }

    init(puzzle: ChessPuzzle, resetToken: UUID, onMove: @escaping (String) -> Bool) {
        self.puzzle = puzzle
        self.resetToken = resetToken
        self.onMove = onMove
        self._chessboardModel = State(initialValue: ChessboardModel(
            fen: puzzle.fen,
            perspective: Self.makePerspective(from: puzzle.fen)
        ))
        self._currentToken = State(initialValue: resetToken)
        self._lastValidFen = State(initialValue: puzzle.fen)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(sideToMoveText)
                .font(.headline)

            Chessboard(chessboardModel: chessboardModel)
                .onMove { move, isLegal, from, to, lan, promotionPiece in
                    // Only process legal moves
                    guard isLegal else { return }

                    // Generate new token to invalidate any pending resets
                    let currentMoveToken = UUID()
                    moveToken = currentMoveToken

                    let fenBeforeMove = lastValidFen

                    // Apply the move visually (animate piece to new position)
                    chessboardModel.setFen(fenBeforeMove, lan: lan)

                    let isCorrect = onMove(lan)
                    if isCorrect {
                        // Correct answer - update tracking, piece stays in new position
                        lastValidFen = chessboardModel.fen
                    } else {
                        // Wrong answer - animate back after 0.5 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // Only reset if this move hasn't been superseded
                            guard moveToken == currentMoveToken else { return }
                            chessboardModel.setFen(fenBeforeMove, lan: nil)
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)
        }
        .onChange(of: resetToken) { _, newToken in
            if newToken != currentToken {
                chessboardModel.setFen(puzzle.fen, lan: nil)
                lastValidFen = puzzle.fen
                currentToken = newToken
            }
        }
    }
}
