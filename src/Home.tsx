import { useState } from 'react';
import { ChevronRight } from './components/Header';
import { load, remove } from './lib/storage';
import { CHESS_STATS_KEY, DEFAULT_CHESS_STATS, DEFAULT_GEO_STATS, GEO_STATS_KEY } from './lib/stats';

export default function Home() {
  const [chess, setChess] = useState(() => load(CHESS_STATS_KEY, DEFAULT_CHESS_STATS));
  const [geo, setGeo] = useState(() => load(GEO_STATS_KEY, DEFAULT_GEO_STATS));

  const resetProgress = () => {
    if (!window.confirm('Reset all progress? Your chess rating and best scores will be cleared.')) return;
    remove(CHESS_STATS_KEY);
    remove(GEO_STATS_KEY);
    setChess(DEFAULT_CHESS_STATS);
    setGeo(DEFAULT_GEO_STATS);
  };

  return (
    <main className="home">
      <header className="hero">
        <h1>BrainTax</h1>
        <p>Pick a puzzle.</p>
      </header>

      <nav className="card-list">
        <a className="card" href="#/chess">
          {/* U+FE0E keeps iOS from rendering the knight as an emoji. */}
          <span className="card-icon card-icon-chess" aria-hidden="true">{'♞︎'}</span>
          <span className="card-body">
            <span className="card-title">Chess tactics</span>
            <span className="card-sub">
              {chess.played > 0
                ? `Rating ${chess.rating} · ${chess.solved} solved`
                : 'Puzzles that adapt to your rating'}
            </span>
          </span>
          <ChevronRight />
        </a>
        <a className="card" href="#/geo">
          <span className="card-icon" aria-hidden="true">🌍</span>
          <span className="card-body">
            <span className="card-title">Geography</span>
            <span className="card-sub">
              {geo.rounds > 0
                ? `${geo.rounds} ${geo.rounds === 1 ? 'round' : 'rounds'} played`
                : 'Flags, capitals and maps'}
            </span>
          </span>
          <ChevronRight />
        </a>
      </nav>

      {(chess.played > 0 || geo.rounds > 0) && (
        <button type="button" className="link-btn" onClick={resetProgress}>
          Reset progress
        </button>
      )}
    </main>
  );
}
