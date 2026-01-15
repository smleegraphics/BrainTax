# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

This is an Xcode iOS project with no external dependencies.

```bash
# Build the project
xcodebuild -project BrainTax.xcodeproj -scheme BrainTax -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests (when added)
xcodebuild -project BrainTax.xcodeproj -scheme BrainTax -destination 'platform=iOS Simulator,name=iPhone 16' test

# Clean build
xcodebuild -project BrainTax.xcodeproj -scheme BrainTax clean
```

Open `BrainTax.xcodeproj` in Xcode to run on simulator or device.

## Architecture

BrainTax is a chess puzzle app built with SwiftUI following the MVVM pattern.

### Core Components

**Puzzle System (Protocol-Based)**
- `Puzzle` protocol defines the interface all puzzle types must implement
- `ChessPuzzle` is the current implementation using FEN notation for board state and UCI notation for moves
- `AnyPuzzle` provides type erasure for storing heterogeneous puzzle collections

**Data Flow**
```
PuzzleStore (manages collection)
    → PuzzleViewModel (handles interaction logic)
    → PuzzleView (renders UI based on puzzle type)
    → ChessBoardView (interactive chess board)
```

**Chess Move Handling**
1. User taps source square, then destination square in `ChessBoardView`
2. Move generated as UCI string (e.g., "e2e4")
3. `ChessPuzzle.isAnswerCorrect()` validates against `correctMoves` array
4. `ChessBoard` model updates with animation if correct

### Key Files

- `Models/ChessBoard.swift` - Board state management, FEN parsing, move application
- `Services/PuzzleLoader.swift` - Loads puzzles from bundled JSON (supports Lichess format)
- `Services/PuzzleStore.swift` - Observable store managing puzzle collection and navigation
- `ViewModels/PuzzleViewModel.swift` - Puzzle interaction logic, answer validation
- `Views/ChessBoardView.swift` - Interactive 8x8 board with piece rendering

### Puzzle Data Format

`PuzzleLoader` reads all `*_puzzles.json` files from `Puzzles/` at runtime. The puzzle type is inferred from the filename (e.g., `chess_puzzles.json` → type "chess").

Puzzle files use Lichess format:
```json
{
  "id": "string",
  "fen": "FEN string",
  "solution": ["uci_move1", "uci_move2"],
  "rating": 1500,
  "themes": ["endgame", "short"]
}
```

Rating maps to difficulty: <1200=easy, 1200-1800=medium, >1800=hard

## Extending the App

To add a new puzzle type:
1. Create model conforming to `Puzzle` protocol in `Models/`
2. Add case to `PuzzleType` enum
3. Update `PuzzleLoader.parsePuzzleJSON()` to handle new format
4. Add rendering logic in `PuzzleView` for new type
