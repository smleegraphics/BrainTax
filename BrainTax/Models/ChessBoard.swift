//
//  ChessBoard.swift
//  BrainTax
//
//  Chess board model for representing and manipulating board state
//

import Foundation
import Combine
import SwiftUI

/// Represents a chess piece
struct ChessPiece: Identifiable {
    let id = UUID()
    let type: PieceType
    let color: PieceColor
}

enum PieceType: String {
    case king = "K"
    case queen = "Q"
    case rook = "R"
    case bishop = "B"
    case knight = "N"
    case pawn = "P"
    
    var symbol: String {
        rawValue
    }
}

enum PieceColor {
    case white
    case black
    
    var symbol: Character {
        switch self {
        case .white: return "w"
        case .black: return "b"
        }
    }
}

/// Represents a square on the chess board
struct BoardSquare: Identifiable {
    let id: String // e.g., "e4"
    let row: Int // 0-7 (0 is rank 8, 7 is rank 1)
    let col: Int // 0-7 (0 is file a, 7 is file h)
    
    init(row: Int, col: Int) {
        self.row = row
        self.col = col
        let file = Character(UnicodeScalar(97 + col)!)
        let rank = 8 - row
        self.id = "\(file)\(rank)"
    }
    
    init?(squareId: String) {
        guard squareId.count == 2,
              let fileChar = squareId.first,
              let rankChar = squareId.last,
              let rank = Int(String(rankChar)) else {
            return nil
        }
        let file = Int(fileChar.asciiValue! - 97)
        guard file >= 0 && file < 8, rank >= 1 && rank <= 8 else {
            return nil
        }
        self.row = 8 - rank
        self.col = file
        self.id = squareId.lowercased()
    }
}

/// Represents the state of a chess board
class ChessBoard: ObservableObject {
    @Published var squares: [[ChessPiece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    @Published var selectedSquare: BoardSquare?
    @Published var legalMoves: [String] = []
    
    /// Parse a FEN string and populate the board
    func loadFromFEN(_ fen: String) {
        let components = fen.split(separator: " ")
        guard !components.isEmpty else { return }
        
        let boardPart = components[0]
        let ranks = boardPart.split(separator: "/")
        
        // Clear the board
        squares = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        
        for (rankIndex, rank) in ranks.enumerated() {
            var fileIndex = 0
            for char in rank {
                if let emptySquares = Int(String(char)) {
                    // Empty squares
                    fileIndex += emptySquares
                } else {
                    // Piece
                    let piece = parsePiece(char: char)
                    if fileIndex < 8 && rankIndex < 8 {
                        squares[rankIndex][fileIndex] = piece
                    }
                    fileIndex += 1
                }
            }
        }
    }
    
    /// Parse a single character into a ChessPiece
    private func parsePiece(char: Character) -> ChessPiece? {
        let isWhite = char.isUppercase
        let color: PieceColor = isWhite ? .white : .black
        let pieceChar = char.uppercased().first!
        
        let type: PieceType? = {
            switch pieceChar {
            case "K": return .king
            case "Q": return .queen
            case "R": return .rook
            case "B": return .bishop
            case "N": return .knight
            case "P": return .pawn
            default: return nil
            }
        }()
        
        guard let pieceType = type else { return nil }
        return ChessPiece(type: pieceType, color: color)
    }
    
    /// Get the piece at a specific square
    func piece(at square: BoardSquare) -> ChessPiece? {
        guard square.row >= 0 && square.row < 8 && square.col >= 0 && square.col < 8 else {
            return nil
        }
        return squares[square.row][square.col]
    }
    
    /// Clear selection
    func clearSelection() {
        selectedSquare = nil
        legalMoves = []
    }
    
    /// Get square from row and column
    func square(row: Int, col: Int) -> BoardSquare {
        BoardSquare(row: row, col: col)
    }
    
    /// Apply a move in UCI format (e.g., "e2e4") and update the board with animation
    func applyMove(uci: String) {
        // Expect exactly 4 characters like e2e4
        guard uci.count >= 4 else { return }
        let fromId = String(uci.prefix(2)).lowercased()
        let toId = String(uci.dropFirst(2).prefix(2)).lowercased()
        guard let from = BoardSquare(squareId: fromId), let to = BoardSquare(squareId: toId) else { return }
        guard from.row >= 0 && from.row < 8 && from.col >= 0 && from.col < 8 else { return }
        guard to.row >= 0 && to.row < 8 && to.col >= 0 && to.col < 8 else { return }
        let movingPiece = squares[from.row][from.col]
        // Clear selection and legal moves
        clearSelection()
        // Animate the board change
        DispatchQueue.main.async {
            withAnimation(Animation.easeInOut(duration: 0.25)) {
                self.squares[from.row][from.col] = nil
                self.squares[to.row][to.col] = movingPiece
            }
        }
    }
}
