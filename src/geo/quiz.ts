import { shuffle, type Rng } from '../lib/random';
import { COUNTRIES, type Country, type RegionFilter } from './countries';

export const GEO_MODES = {
  flags: { title: 'Flags', blurb: 'Name the country from its flag', icon: '🚩' },
  'pick-flag': { title: 'Pick the flag', blurb: 'Find the right flag for a country', icon: '🎌' },
  capitals: { title: 'Capitals', blurb: 'Name the capital city', icon: '🏛️' },
  map: { title: 'Map', blurb: 'Name the highlighted country', icon: '🗺️' },
} as const;

export type GeoMode = keyof typeof GEO_MODES;
export const GEO_MODE_IDS = Object.keys(GEO_MODES) as GeoMode[];

export function isGeoMode(value: string | undefined): value is GeoMode {
  return value !== undefined && Object.hasOwn(GEO_MODES, value);
}

export const ROUND_LENGTH = 10;
const OPTION_COUNT = 4;

export interface Question {
  answer: Country;
  /** Includes the answer, in random order. */
  options: Country[];
}

export function bestKey(mode: GeoMode, region: RegionFilter): string {
  return `${mode}:${region}`;
}

export function eligibleCountries(mode: GeoMode, region: RegionFilter): Country[] {
  return COUNTRIES.filter(
    (c) => (region === 'World' || c.region === region) && (mode !== 'map' || c.inMap),
  );
}

export function makeRound(
  mode: GeoMode,
  region: RegionFilter,
  rng: Rng = Math.random,
  length = ROUND_LENGTH,
): Question[] {
  const pool = eligibleCountries(mode, region);
  return shuffle(pool, rng)
    .slice(0, length)
    .map((answer) => ({
      answer,
      options: shuffle([answer, ...pickDistractors(answer, pool, mode, rng)], rng),
    }));
}

/** Wrong options, drawn from the answer's neighbours first so questions aren't giveaways. */
function pickDistractors(answer: Country, pool: Country[], mode: GeoMode, rng: Rng): Country[] {
  // Capitals mode shows capital names, so two options must never share one.
  const label = (c: Country) => (mode === 'capitals' ? c.capital : c.code);
  const used = new Set([label(answer)]);
  const chosen: Country[] = [];
  const tiers = [
    pool.filter((c) => c.subregion === answer.subregion),
    pool.filter((c) => c.region === answer.region),
    COUNTRIES,
  ];
  for (const tier of tiers) {
    for (const c of shuffle(tier, rng)) {
      if (chosen.length === OPTION_COUNT - 1) return chosen;
      if (used.has(label(c))) continue;
      used.add(label(c));
      chosen.push(c);
    }
  }
  return chosen;
}
