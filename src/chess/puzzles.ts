import puzzlesUrl from '../data/chess-puzzles.json?url';
import { pick, type Rng } from '../lib/random';
import type { Uci } from './session';

export interface ChessPuzzle {
  id: string;
  /** Position before the opponent's setup move (Lichess convention). */
  fen: string;
  moves: Uci[];
  rating: number;
  themes: string[];
}

/** Compact row format written by scripts/build_chess_puzzles.py. */
type PuzzleRow = [id: string, fen: string, moves: string, rating: number, themes: string];

let cache: Promise<ChessPuzzle[]> | null = null;

export function loadPuzzles(): Promise<ChessPuzzle[]> {
  cache ??= fetch(puzzlesUrl)
    .then((res) => {
      if (!res.ok) throw new Error(`Failed to load puzzles: HTTP ${res.status}`);
      return res.json() as Promise<{ puzzles: PuzzleRow[] }>;
    })
    .then(({ puzzles }) =>
      puzzles.map(([id, fen, moves, rating, themes]) => ({
        id,
        fen,
        moves: moves.split(' '),
        rating,
        themes: themes ? themes.split(' ') : [],
      })),
    );
  // Let a later call retry after a network failure.
  cache.catch(() => {
    cache = null;
  });
  return cache;
}

/** Picks an unseen puzzle near the player's rating, widening the window until one is found. */
export function pickPuzzle(
  puzzles: readonly ChessPuzzle[],
  rating: number,
  exclude: ReadonlySet<string>,
  rng: Rng = Math.random,
): ChessPuzzle {
  for (let window = 100; window <= 3200; window *= 2) {
    const candidates = puzzles.filter((p) => !exclude.has(p.id) && Math.abs(p.rating - rating) <= window);
    if (candidates.length > 0) return pick(candidates, rng);
  }
  // Every puzzle has been attempted; start repeating.
  return pick(puzzles, rng);
}

/** Lichess tags that describe length or evaluation rather than the tactic itself. */
const HIDDEN_THEMES = new Set([
  'short', 'long', 'veryLong', 'oneMove', 'crushing', 'advantage', 'equality', 'mate',
  'master', 'masterVsMaster', 'superGM',
]);

/** Human-readable tactic names, e.g. "backRankMate" → "Back rank mate", "mateIn2" → "Mate in 2". */
export function themeLabels(themes: readonly string[]): string[] {
  return themes
    .filter((t) => !HIDDEN_THEMES.has(t))
    .map((t) => {
      const words = t.replace(/([A-Z]|\d+)/g, ' $1').toLowerCase().trim();
      return words.charAt(0).toUpperCase() + words.slice(1);
    });
}
