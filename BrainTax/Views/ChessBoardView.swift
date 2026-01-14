//
//  ChessBoardView.swift
//  BrainTax
//
//  Interactive chess board view for displaying and interacting with chess puzzles
//

import SwiftUI

struct ChessBoardView: View {
    @ObservedObject var board: ChessBoard
    let onMoveSelected: (String) -> Void // Callback with UCI move (e.g., "e2e4")
    
    @State private var moveStart: BoardSquare?
    
    private let squareSize: CGFloat = 40
    private let lightSquareColor = Color(red: 0.93, green: 0.93, blue: 0.82)
    private let darkSquareColor = Color(red: 0.47, green: 0.47, blue: 0.37)
    private let selectedColor = Color.blue.opacity(0.5)
    private let legalMoveColor = Color.green.opacity(0.4)
    
    var body: some View {
        VStack(spacing: 0) {
            // File labels (a-h)
            HStack(spacing: 0) {
                Spacer()
                ForEach(0..<8, id: \.self) { col in
                    Text(fileLabel(for: col))
                        .font(.caption2)
                        .frame(width: squareSize)
                }
                Spacer()
            }
            
            // Board squares
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: 0) {
                    // Rank label (8-1)
                    Text("\(8 - row)")
                        .font(.caption2)
                        .frame(width: 20)
                    
                    ForEach(0..<8, id: \.self) { col in
                        let square = board.square(row: row, col: col)
                        let piece = board.piece(at: square)
                        let isLight = (row + col) % 2 == 0
                        let isSelected = moveStart?.id == square.id
                        let isLegalMove = board.legalMoves.contains { move in
                            move.hasSuffix(square.id)
                        }
                        
                        ZStack {
                            // Square background
                            Rectangle()
                                .fill(isLight ? lightSquareColor : darkSquareColor)
                                .frame(width: squareSize, height: squareSize)
                            
                            // Selection highlight
                            if isSelected {
                                Rectangle()
                                    .fill(selectedColor)
                                    .frame(width: squareSize, height: squareSize)
                            }
                            
                            // Legal move indicator
                            if isLegalMove && !isSelected {
                                Circle()
                                    .fill(legalMoveColor)
                                    .frame(width: squareSize * 0.3, height: squareSize * 0.3)
                            }
                            
                            // Piece
                            if let piece = piece {
                                Text(pieceSymbol(piece))
                                    .font(.system(size: squareSize * 0.7))
                                    .foregroundColor(piece.color == .white ? .white : .black)
                            }
                        }
                        .onTapGesture {
                            handleSquareTap(square: square)
                        }
                    }
                }
            }
        }
    }
    
    /// Handle tap on a square
    private func handleSquareTap(square: BoardSquare) {
        if let start = moveStart {
            // Second tap - complete the move
            let move = "\(start.id)\(square.id)"
            onMoveSelected(move)
            moveStart = nil
            board.clearSelection()
        } else {
            // First tap - select starting square
            if board.piece(at: square) != nil {
                moveStart = square
                board.selectedSquare = square
                // For now, we'll show legal moves after move validation in the view model
                // This is a simplified version - in a full implementation, we'd calculate legal moves here
            }
        }
    }
    
    /// Get file label (a-h)
    private func fileLabel(for col: Int) -> String {
        String(Character(UnicodeScalar(97 + col)!))
    }
    
    /// Get Unicode symbol for piece
    private func pieceSymbol(_ piece: ChessPiece) -> String {
        let symbols: [PieceType: (String, String)] = [
            .king: ("♔", "♚"),
            .queen: ("♕", "♛"),
            .rook: ("♖", "♜"),
            .bishop: ("♗", "♝"),
            .knight: ("♘", "♞"),
            .pawn: ("♙", "♟")
        ]
        
        guard let (whiteSymbol, blackSymbol) = symbols[piece.type] else {
            return ""
        }
        return piece.color == .white ? whiteSymbol : blackSymbol
    }
}
