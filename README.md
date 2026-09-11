# BrainTax

A small puzzle site built to be played on a phone:

- **Chess tactics**: about 2,400 hand-filtered [Lichess](https://lichess.org) puzzles. You get an Elo-style rating that moves with every puzzle, and the next puzzle is picked near that rating.
- **Geography**: four modes (name the flag, pick the flag, capitals, and a zoomed map with the country highlighted) across the world or a single region. Each round is 10 questions.

Everything runs in the browser. There's no backend: progress is stored in `localStorage`, and the site is a static Vite build.

## Development

```bash
npm install
npm run dev        # http://localhost:5273
npm test           # Vitest unit tests (puzzle logic, quiz generation)
npm run build      # type-check + production build into dist/
npm run preview    # serve the production build locally on http://localhost:4273
```

To try it on your phone while developing, run `npm run dev -- --host` and open the printed network URL. Your phone must be on the same Wi-Fi.

## Deploying (Vercel)

Import the GitHub repo in Vercel. It detects Vite automatically (build command `npm run build`, output directory `dist`), so no `vercel.json` is needed. Routes use hash URLs (`/#/chess`), so no rewrite rules are needed either.

On iPhone, open the site in Safari and use **Share → Add to Home Screen**. It then launches full screen like an app.

## Data

Both data files are generated and committed, so a normal build never needs the source data.

| File | Source | Regenerate |
| --- | --- | --- |
| `src/data/chess-puzzles.json` | [Lichess puzzle database](https://database.lichess.org/#puzzles) (CC0) | `npm run data:chess`, which needs the decompressed CSV at `Resources/lichess_db_puzzle.csv` (gitignored) |
| `src/data/countries.json` | [`world-countries`](https://github.com/mledoze/countries) (ODbL-1.0) | `npm run data:countries` |

The map uses [`world-atlas`](https://github.com/topojson/world-atlas) (Natural Earth, public domain), and the flags come from [`flag-icons`](https://github.com/lipis/flag-icons) (MIT).

The chess script keeps only well-tested puzzles (popularity ≥ 85, ≥ 1,000 plays) and samples 100 per 100-point rating band. Run `python3 scripts/build_chess_puzzles.py --help` to see the options.

## History

This repo started as an iOS app that made you solve a puzzle before opening distracting apps. That version is preserved at the `ios-final` tag.
