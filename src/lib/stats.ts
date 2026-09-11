import type { RegionFilter } from '../geo/countries';

export const CHESS_STATS_KEY = 'braintax:chess';
export const GEO_STATS_KEY = 'braintax:geo';

export interface ChessStats {
  rating: number;
  played: number;
  solved: number;
  streak: number;
  bestStreak: number;
  /** Puzzle ids already attempted, so they aren't served again. */
  attempted: string[];
}

export const DEFAULT_CHESS_STATS: ChessStats = {
  rating: 1200,
  played: 0,
  solved: 0,
  streak: 0,
  bestStreak: 0,
  attempted: [],
};

export interface GeoStats {
  /** Best round score keyed by `${mode}:${region}`. */
  best: Record<string, number>;
  rounds: number;
  /** Region last picked on the geography menu. */
  region: RegionFilter;
}

export const DEFAULT_GEO_STATS: GeoStats = { best: {}, rounds: 0, region: 'World' };
