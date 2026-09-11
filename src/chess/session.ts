import { Chess } from 'chess.js';

/** A move in UCI notation, e.g. "e2e4" or "e7e8q". */
export type Uci = string;

export interface LastMove {
  from: string;
  to: string;
}

export type MoveOutcome = 'correct' | 'wrong' | 'illegal';

/**
 * Plays through a Lichess puzzle.
 *
 * Lichess stores the position *before* the opponent's move: moves[0] is the opponent's
 * setup move, and the solver plays moves[1], moves[3], ... with the opponent replying
 * in between. The constructor plays moves[0], so the session starts on the solver's turn.
 */
export class PuzzleSession {
  readonly chess: Chess;
  readonly moves: readonly Uci[];
  /** The side the solver plays. */
  readonly solver: 'w' | 'b';
  mistakes = 0;
  private ply = 1;

  constructor(fen: string, moves: readonly Uci[]) {
    this.chess = new Chess(fen);
    this.moves = moves;
    applyUci(this.chess, moves[0]);
    this.solver = this.chess.turn();
  }

  get fen(): string {
    return this.chess.fen();
  }

  get isSolved(): boolean {
    return this.ply >= this.moves.length;
  }

  /** The next move in the stored line (the solver's, when it is their turn). */
  get expected(): Uci | undefined {
    return this.moves[this.ply];
  }

  get lastMove(): LastMove | null {
    const history = this.chess.history({ verbose: true });
    const last = history[history.length - 1];
    return last ? { from: last.from, to: last.to } : null;
  }

  /** Tries a solver move. Wrong and illegal moves leave the position unchanged. */
  tryMove(uci: Uci): MoveOutcome {
    if (this.isSolved || this.chess.turn() !== this.solver) return 'illegal';
    if (!applyUci(this.chess, uci)) return 'illegal';

    // Like Lichess, accept any checkmate even if it isn't the stored move.
    if (this.chess.isCheckmate()) {
      this.ply = this.moves.length;
      return 'correct';
    }
    if (uci === this.moves[this.ply]) {
      this.ply++;
      return 'correct';
    }

    this.chess.undo();
    this.mistakes++;
    return 'wrong';
  }

  /** Plays the opponent's scripted reply if it is their turn. */
  playOpponent(): Uci | null {
    if (this.isSolved || this.chess.turn() === this.solver) return null;
    return this.playNext();
  }

  /** Plays the next scripted move for whichever side is to move (used to reveal the solution). */
  playNext(): Uci | null {
    if (this.isSolved) return null;
    const uci = this.moves[this.ply];
    applyUci(this.chess, uci);
    this.ply++;
    return uci;
  }
}

/** Applies a UCI move, returning null instead of throwing when it's illegal. */
function applyUci(chess: Chess, uci: Uci) {
  try {
    return chess.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
  } catch {
    return null;
  }
}
