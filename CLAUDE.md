# CLAUDE.md

BrainTax is a mobile-first static web app (React 19 + TypeScript + Vite 6) with two games: Lichess chess tactics and geography quizzes. It's deployed on Vercel and has no backend.

## Commands

```bash
npm run dev          # dev server on :5273 (preview uses :4273; 5173 is taken by another local project)
npm test             # vitest (node environment; tests live next to the code as *.test.ts)
npm run build        # tsc -b && vite build
npm run data:chess   # regenerate src/data/chess-puzzles.json from Resources/lichess_db_puzzle.csv
npm run data:countries
```

Local Node is 22.3, which is why Vite is pinned to 6 (Vite 7+ needs Node 22.12 or newer). The system npm (10.8.1) crashes resolving peer deps (`reading 'edgesOut'`), so use `npx npm@10.9.9 install` if that happens.

## Layout

- `src/App.tsx`: hash router (`#/`, `#/chess`, `#/geo`, `#/geo/<mode>/<region>`). Each page is `React.lazy`-loaded.
- `src/lib/`: `storage.ts` (localStorage wrappers that never throw), `stats.ts` (persisted stats shapes and keys), `random.ts`, `useTimers.ts`.
- `src/chess/`
  - `session.ts` is the pure puzzle logic. **Lichess convention:** the FEN is the position *before* the opponent's move, `moves[0]` is the opponent's setup move, and the solver plays the odd plies. Any checkmating move is accepted even if it isn't the stored one.
  - `puzzles.ts` loads the compact JSON (`[id, fen, moves, rating, themes]` rows) via `?url` + fetch, and picks a puzzle near the player's rating.
  - `rating.ts` is the Elo update.
  - `Board.tsx` wraps `react-chessboard` v5 (the `options` prop API) with tap-to-move and a promotion picker.
  - `ChessPage.tsx` handles game flow: intro → solving ⇄ opponent → solved/revealed. The first miss, hint, or solution view rates the puzzle as a loss.
- `src/geo/`
  - `countries.ts` and `quiz.ts` (round generation; distractors come from the same subregion first) are pure and tested.
  - `Flag.tsx` resolves flag-icons SVGs via `import.meta.glob`.
  - `WorldMap.tsx` draws the map with d3-geo: an azimuthal equal-area projection centered on the target's mainland, loaded lazily from `world-atlas/countries-50m.json?url`.
  - `GeoQuiz.tsx` is the quiz UI.

## Conventions

- Keep game logic in pure modules with Vitest coverage; components stay thin.
- Mobile first: tap targets of at least 44px, `100svh`, safe-area insets, and light/dark through the CSS variables in `styles.css`.
- Adding a geography mode: add an entry to `GEO_MODES` in `quiz.ts` and handle it in the `Prompt`/`Options`/`Feedback` components in `GeoQuiz.tsx`.
