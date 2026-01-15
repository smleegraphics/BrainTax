import csv
import json
import random

input_file = "lichess_db_puzzle.csv"
output_file = "chess_puzzles.json"
num_puzzles = 100  # how many random puzzles to include

# read all rows
with open(input_file, newline='', encoding='utf-8') as f:
    reader = csv.reader(f)
    rows = list(reader)

# filter rows with non-empty solution (column 2)
rows_with_solution = [r for r in rows if len(r) > 2 and r[2].strip()]
print("Rows with solution:", len(rows_with_solution))

# pick a random subset
subset = random.sample(rows_with_solution, min(num_puzzles, len(rows_with_solution)))

# convert to JSON
puzzles = []
for r in subset:
    puzzles.append({
        "id": r[0],
        "fen": r[1],
        "solution": r[2].split(),  # space-separated UCI moves
        "rating": int(r[3]) if r[3] else None,
        "plays": int(r[4]) if r[4] else None,
        "themes": r[7].split() if len(r) > 7 and r[7] else [],
        "url": r[8] if len(r) > 8 else None
    })

# write to JSON
with open(output_file, "w", encoding='utf-8') as f:
    json.dump(puzzles, f, indent=2)

print(f"Saved {len(puzzles)} puzzles to {output_file}")
