import { useCallback, useEffect, useRef, useState } from 'react';
import { Header } from '../components/Header';
import { load, save } from '../lib/storage';
import { CHESS_STATS_KEY, DEFAULT_CHESS_STATS } from '../lib/stats';
import { useTimers } from '../lib/useTimers';
import { Board } from './Board';
import { loadPuzzles, pickPuzzle, themeLabels, type ChessPuzzle } from './puzzles';
import { updateRating } from './rating';
import { PuzzleSession, type LastMove, type Uci } from './session';

type Phase = 'intro' | 'solving' | 'opponent' | 'solved' | 'revealing' | 'revealed';

const SETUP_DELAY_MS = 700;
const REPLY_DELAY_MS = 500;
const REVEAL_STEP_MS = 800;

export default function ChessPage() {
  const [puzzles, setPuzzles] = useState<ChessPuzzle[] | null>(null);
  const [loadAttempt, setLoadAttempt] = useState(0);
  const [loadFailed, setLoadFailed] = useState(false);
  const [stats, setStats] = useState(() => load(CHESS_STATS_KEY, DEFAULT_CHESS_STATS));

  const [puzzle, setPuzzle] = useState<ChessPuzzle | null>(null);
  const [solver, setSolver] = useState<'w' | 'b'>('w');
  const [fen, setFen] = useState('');
  const [lastMove, setLastMove] = useState<LastMove | null>(null);
  const [phase, setPhase] = useState<Phase>('intro');
  const [feedback, setFeedback] = useState<'correct' | 'wrong' | null>(null);
  const [hintSquare, setHintSquare] = useState<string | null>(null);
  const [wrongSquare, setWrongSquare] = useState<string | null>(null);
  const [result, setResult] = useState<{ success: boolean; delta: number } | null>(null);

  const session = useRef<PuzzleSession | null>(null);
  const rated = useRef(false);
  const statsRef = useRef(stats);
  const timers = useTimers();

  useEffect(() => {
    statsRef.current = stats;
    save(CHESS_STATS_KEY, stats);
  }, [stats]);

  const startPuzzle = useCallback(
    (next: ChessPuzzle) => {
      timers.clear();
      const s = new PuzzleSession(next.fen, next.moves);
      session.current = s;
      rated.current = false;
      setPuzzle(next);
      setSolver(s.solver);
      setFen(next.fen);
      setLastMove(null);
      setPhase('intro');
      setFeedback(null);
      setHintSquare(null);
      setWrongSquare(null);
      setResult(null);
      // Show the starting position for a moment, then animate the opponent's move.
      timers.later(() => {
        setFen(s.fen);
        setLastMove(s.lastMove);
        setPhase('solving');
      }, SETUP_DELAY_MS);
    },
    [timers],
  );

  const serveNext = useCallback(
    (all: ChessPuzzle[]) => {
      const { rating, attempted } = statsRef.current;
      startPuzzle(pickPuzzle(all, rating, new Set(attempted)));
    },
    [startPuzzle],
  );

  useEffect(() => {
    let live = true;
    loadPuzzles().then(
      (all) => {
        if (!live) return;
        setPuzzles(all);
        serveNext(all);
      },
      () => {
        if (live) setLoadFailed(true);
      },
    );
    return () => {
      live = false;
    };
  }, [serveNext, loadAttempt]);

  /** Rates the puzzle once: a miss, hint, or peeking at the solution counts as a loss. */
  const recordResult = (success: boolean) => {
    if (rated.current || !puzzle) return;
    rated.current = true;
    const prev = statsRef.current;
    const rating = updateRating(prev.rating, puzzle.rating, success, prev.played);
    const streak = success ? prev.streak + 1 : 0;
    setResult({ success, delta: rating - prev.rating });
    setStats({
      rating,
      played: prev.played + 1,
      solved: prev.solved + (success ? 1 : 0),
      streak,
      bestStreak: Math.max(prev.bestStreak, streak),
      attempted: [...prev.attempted, puzzle.id],
    });
  };

  const finish = () => {
    recordResult(true);
    setPhase('solved');
  };

  const handleMove = (uci: Uci): boolean => {
    const s = session.current;
    if (!s || phase !== 'solving') return false;

    const outcome = s.tryMove(uci);
    if (outcome === 'illegal') return false;
    if (outcome === 'wrong') {
      recordResult(false);
      setFeedback('wrong');
      setWrongSquare(uci.slice(2, 4));
      timers.later(() => setWrongSquare(null), 600);
      return false;
    }

    setFen(s.fen);
    setLastMove(s.lastMove);
    setFeedback('correct');
    setHintSquare(null);
    if (s.isSolved) {
      finish();
      return true;
    }

    setPhase('opponent');
    timers.later(() => {
      s.playOpponent();
      setFen(s.fen);
      setLastMove(s.lastMove);
      if (s.isSolved) finish();
      else setPhase('solving');
    }, REPLY_DELAY_MS);
    return true;
  };

  const showHint = () => {
    const expected = session.current?.expected;
    if (!expected || phase !== 'solving') return;
    recordResult(false);
    setHintSquare(expected.slice(0, 2));
  };

  const showSolution = () => {
    const s = session.current;
    if (!s || phase !== 'solving') return;
    recordResult(false);
    setPhase('revealing');
    setFeedback(null);
    setHintSquare(null);
    const step = () => {
      s.playNext();
      setFen(s.fen);
      setLastMove(s.lastMove);
      if (s.isSolved) setPhase('revealed');
      else timers.later(step, REVEAL_STEP_MS);
    };
    timers.later(step, 300);
  };

  const nextPuzzle = () => {
    if (puzzles) serveNext(puzzles);
  };

  const side = solver === 'w' ? 'White' : 'Black';
  const done = phase === 'solved' || phase === 'revealed';

  let status: string;
  let tone: 'neutral' | 'good' | 'bad' = 'neutral';
  if (phase === 'intro') {
    status = 'Watch your opponent’s move…';
  } else if (phase === 'solved') {
    status = result?.success ? 'Solved!' : 'Solved — unrated after a miss';
    tone = 'good';
  } else if (phase === 'revealing' || phase === 'revealed') {
    status = 'Here’s the solution';
  } else if (feedback === 'wrong') {
    status = 'Not the move. Try again.';
    tone = 'bad';
  } else if (hintSquare) {
    status = 'Hint: move the highlighted piece';
  } else if (feedback === 'correct') {
    status = 'Correct — keep going';
    tone = 'good';
  } else {
    status = `Your turn: find the best move for ${side}`;
  }

  return (
    <>
      <Header
        title="Chess tactics"
        right={
          <span className="rating-badge" aria-label={`Rating ${stats.rating}`}>
            {stats.rating}
            {result && result.delta !== 0 && (
              <span className={result.delta > 0 ? 'delta delta-up' : 'delta delta-down'}>
                {result.delta > 0 ? `+${result.delta}` : `−${-result.delta}`}
              </span>
            )}
          </span>
        }
      />

      {loadFailed ? (
        <div className="empty">
          <p>Couldn’t load the puzzles.</p>
          <button
            type="button"
            className="btn"
            onClick={() => {
              setLoadFailed(false);
              setLoadAttempt((n) => n + 1);
            }}
          >
            Try again
          </button>
        </div>
      ) : !puzzle ? (
        <div className="empty">
          <div className="spinner" />
        </div>
      ) : (
        <main className="chess">
          <p className={`status status-${tone}`} aria-live="polite">
            <span className={`turn-dot turn-${solver}`} aria-hidden="true" />
            {status}
          </p>

          <Board
            fen={fen}
            orientation={solver === 'w' ? 'white' : 'black'}
            lastMove={lastMove}
            interactive={phase === 'solving'}
            hintSquare={hintSquare}
            wrongSquare={wrongSquare}
            onMove={handleMove}
          />

          <div className="actions">
            {done ? (
              <button type="button" className="btn btn-wide" onClick={nextPuzzle}>
                Next puzzle
              </button>
            ) : (
              <>
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={showHint}
                  disabled={phase !== 'solving' || hintSquare !== null}
                >
                  Hint
                </button>
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={showSolution}
                  disabled={phase !== 'solving'}
                >
                  Solution
                </button>
                {result && (
                  <button type="button" className="btn" onClick={nextPuzzle}>
                    Skip
                  </button>
                )}
              </>
            )}
          </div>

          {done && (
            <p className="meta">
              Puzzle rated {puzzle.rating}
              {themeLabels(puzzle.themes).map((t) => ` · ${t}`)} ·{' '}
              <a href={`https://lichess.org/training/${puzzle.id}`} target="_blank" rel="noreferrer">
                View on Lichess
              </a>
            </p>
          )}
          <p className="meta">
            {stats.solved} solved of {stats.played} · streak {stats.streak} (best {stats.bestStreak})
          </p>
        </main>
      )}
    </>
  );
}
