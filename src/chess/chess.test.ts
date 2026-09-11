import { describe, expect, it } from 'vitest';
import { pickPuzzle, themeLabels, type ChessPuzzle } from './puzzles';
import { updateRating } from './rating';
import { PuzzleSession } from './session';

describe('PuzzleSession', () => {
  // Lichess puzzle 0000D: White's d3d6 is the setup move; the solver plays Black.
  const fen = '5rk1/1p3ppp/pq3b2/8/8/1P1Q1N2/P4PPP/3R2K1 w - - 2 27';
  const moves = ['d3d6', 'f8d8', 'd6d8', 'f6d8'];

  it('plays the setup move and gives the solver the other side', () => {
    const s = new PuzzleSession(fen, moves);
    expect(s.solver).toBe('b');
    expect(s.lastMove).toEqual({ from: 'd3', to: 'd6' });
    expect(s.expected).toBe('f8d8');
  });

  it('rejects wrong and illegal moves without changing the position', () => {
    const s = new PuzzleSession(fen, moves);
    const before = s.fen;
    expect(s.tryMove('g8h8')).toBe('wrong');
    expect(s.fen).toBe(before);
    expect(s.mistakes).toBe(1);
    expect(s.tryMove('e2e4')).toBe('illegal');
    expect(s.mistakes).toBe(1);
  });

  it('walks a long line with opponent replies', () => {
    // Lichess puzzle 00008, solver plays White.
    const s = new PuzzleSession(
      'r6k/pp2r2p/4Rp1Q/3p4/8/1N1P2R1/PqP2bPP/7K b - - 0 24',
      'f2g3 e6e7 b2b1 b3c1 b1c1 h6c1'.split(' '),
    );
    expect(s.solver).toBe('w');
    expect(s.playOpponent()).toBeNull(); // solver's turn
    expect(s.tryMove('e6e7')).toBe('correct');
    expect(s.playOpponent()).toBe('b2b1');
    expect(s.tryMove('b3c1')).toBe('correct');
    expect(s.playOpponent()).toBe('b1c1');
    expect(s.isSolved).toBe(false);
    expect(s.tryMove('h6c1')).toBe('correct');
    expect(s.isSolved).toBe(true);
  });

  it('accepts a checkmate that differs from the stored line', () => {
    const s = new PuzzleSession('6k1/5ppp/8/8/8/8/5PPP/RR4K1 b - - 0 1', ['g8h8', 'a1a8']);
    expect(s.tryMove('b1b8')).toBe('correct');
    expect(s.isSolved).toBe(true);
  });

  it('requires the stored promotion piece', () => {
    const s = new PuzzleSession('8/P5k1/8/8/8/8/8/6K1 b - - 0 1', ['g7h7', 'a7a8q']);
    expect(s.tryMove('a7a8n')).toBe('wrong');
    expect(s.tryMove('a7a8q')).toBe('correct');
    expect(s.isSolved).toBe(true);
  });

  it('reveals the rest of the line with playNext', () => {
    const s = new PuzzleSession(fen, moves);
    expect([s.playNext(), s.playNext(), s.playNext(), s.playNext()]).toEqual(['f8d8', 'd6d8', 'f6d8', null]);
    expect(s.isSolved).toBe(true);
  });
});

describe('updateRating', () => {
  it('gains for a win and loses for a loss against an equal puzzle', () => {
    expect(updateRating(1500, 1500, true, 50)).toBe(1510);
    expect(updateRating(1500, 1500, false, 50)).toBe(1490);
  });

  it('moves faster during the first games', () => {
    expect(updateRating(1500, 1500, true, 0)).toBe(1520);
  });

  it('stays within bounds', () => {
    expect(updateRating(400, 2000, false, 0)).toBe(400);
  });
});

describe('pickPuzzle', () => {
  const puzzle = (id: string, rating: number): ChessPuzzle => ({ id, fen: '', moves: [], rating, themes: [] });
  const puzzles = [puzzle('a', 800), puzzle('b', 1200), puzzle('c', 1250), puzzle('d', 2000)];

  it('prefers unseen puzzles near the rating', () => {
    expect(pickPuzzle(puzzles, 1210, new Set(['b']), () => 0).id).toBe('c');
  });

  it('widens the search when nothing is close', () => {
    expect(pickPuzzle(puzzles, 1210, new Set(['b', 'c']), () => 0).id).toBe('a');
  });

  it('repeats once everything has been seen', () => {
    expect(pickPuzzle(puzzles, 1210, new Set(['a', 'b', 'c', 'd']), () => 0).id).toBe('a');
  });
});

describe('themeLabels', () => {
  it('humanizes tactic names and hides length/evaluation tags', () => {
    expect(themeLabels(['mateIn2', 'backRankMate', 'short', 'crushing', 'enPassant'])).toEqual([
      'Mate in 2',
      'Back rank mate',
      'En passant',
    ]);
  });
});
