#!/usr/bin/env python3
"""Build src/data/chess-puzzles.json from the Lichess puzzle database.

Download and decompress the database (CC0) from https://database.lichess.org/#puzzles:

    curl -O https://database.lichess.org/lichess_db_puzzle.csv.zst
    zstd -d lichess_db_puzzle.csv.zst

The CSV is several hundred MB and is gitignored. This script streams it, keeps
only well-tested puzzles, and samples an even spread across rating bands so the
app's adaptive rating always has nearby puzzles to serve.

Lichess format reminder: FEN is the position *before* the opponent's move.
Moves[0] is the opponent's move; the solver's line starts at Moves[1].
"""

import argparse
import csv
import json
import random
from collections import defaultdict

BAND_WIDTH = 100


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--csv", default="Resources/lichess_db_puzzle.csv")
    parser.add_argument("--out", default="src/data/chess-puzzles.json")
    parser.add_argument("--per-band", type=int, default=100, help="puzzles per 100-point rating band")
    parser.add_argument("--min-rating", type=int, default=400)
    parser.add_argument("--max-rating", type=int, default=2900)
    parser.add_argument("--min-popularity", type=int, default=85)
    parser.add_argument("--min-plays", type=int, default=1000)
    parser.add_argument("--max-deviation", type=int, default=90)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    rng = random.Random(args.seed)
    reservoirs = defaultdict(list)  # band -> sampled rows
    seen = defaultdict(int)  # band -> eligible rows seen so far

    with open(args.csv, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            rating = int(row["Rating"])
            if not (args.min_rating <= rating < args.max_rating):
                continue
            if (
                int(row["Popularity"]) < args.min_popularity
                or int(row["NbPlays"]) < args.min_plays
                or int(row["RatingDeviation"]) > args.max_deviation
            ):
                continue

            band = rating // BAND_WIDTH
            seen[band] += 1
            reservoir = reservoirs[band]
            puzzle = [row["PuzzleId"], row["FEN"], row["Moves"], rating, row["Themes"]]
            # Reservoir sampling keeps a uniform sample without loading the whole file.
            if len(reservoir) < args.per_band:
                reservoir.append(puzzle)
            else:
                j = rng.randrange(seen[band])
                if j < args.per_band:
                    reservoir[j] = puzzle

    puzzles = sorted((p for r in reservoirs.values() for p in r), key=lambda p: p[3])
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(
            {"format": ["id", "fen", "moves", "rating", "themes"], "puzzles": puzzles},
            f,
            separators=(",", ":"),
        )

    for band in sorted(reservoirs):
        print(f"{band * BAND_WIDTH:>5}: {len(reservoirs[band])}")
    print(f"Wrote {len(puzzles)} puzzles to {args.out}")


if __name__ == "__main__":
    main()
