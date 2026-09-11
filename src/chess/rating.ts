export const MIN_RATING = 400;
export const MAX_RATING = 3000;

/** Elo update for the player after attempting a puzzle of the given rating. */
export function updateRating(player: number, puzzle: number, won: boolean, gamesPlayed: number): number {
  const expected = 1 / (1 + 10 ** ((puzzle - player) / 400));
  // Move fast while the rating is still finding its level, then settle down.
  const k = gamesPlayed < 20 ? 40 : 20;
  const next = Math.round(player + k * ((won ? 1 : 0) - expected));
  return Math.min(MAX_RATING, Math.max(MIN_RATING, next));
}
