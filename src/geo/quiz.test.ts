import { describe, expect, it } from 'vitest';
import { COUNTRIES, parseRegion, REGION_FILTERS } from './countries';
import { eligibleCountries, GEO_MODE_IDS, isGeoMode, makeRound, ROUND_LENGTH } from './quiz';

/** mulberry32: small deterministic PRNG so failures are reproducible. */
function seeded(seed: number) {
  return () => {
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

describe('country data', () => {
  it('has 194 countries with unique codes and a capital each', () => {
    expect(COUNTRIES).toHaveLength(194);
    expect(new Set(COUNTRIES.map((c) => c.code)).size).toBe(194);
    expect(COUNTRIES.every((c) => c.capital && c.name && c.region)).toBe(true);
  });
});

describe('makeRound', () => {
  const cases = GEO_MODE_IDS.flatMap((mode) => REGION_FILTERS.map((region) => [mode, region] as const));

  it.each(cases)('builds a valid %s round for %s', (mode, region) => {
    for (let seed = 0; seed < 20; seed++) {
      const round = makeRound(mode, region, seeded(seed));
      expect(round).toHaveLength(ROUND_LENGTH);
      expect(new Set(round.map((q) => q.answer.code)).size).toBe(ROUND_LENGTH);
      for (const q of round) {
        expect(q.options).toHaveLength(4);
        expect(q.options).toContain(q.answer);
        const labels = q.options.map((o) => (mode === 'capitals' ? o.capital : o.code));
        expect(new Set(labels).size).toBe(4);
        if (region !== 'World') expect(q.answer.region).toBe(region);
        if (mode === 'map') expect(q.answer.inMap).toBe(true);
      }
    }
  });

  it('draws every distractor from the same subregion when it has enough countries', () => {
    const subregionSize = (s: string) => COUNTRIES.filter((c) => c.subregion === s).length;
    let checked = 0;
    for (let seed = 0; seed < 20; seed++) {
      for (const q of makeRound('flags', 'World', seeded(seed))) {
        if (subregionSize(q.answer.subregion) < 4) continue;
        expect(q.options.every((o) => o.subregion === q.answer.subregion)).toBe(true);
        checked++;
      }
    }
    expect(checked).toBeGreaterThan(100);
  });

  it('leaves countries without map shapes out of map mode', () => {
    expect(eligibleCountries('map', 'Oceania').map((c) => c.code)).not.toContain('tv');
    expect(eligibleCountries('flags', 'Oceania').map((c) => c.code)).toContain('tv');
  });
});

describe('route parsing', () => {
  it('validates modes and regions', () => {
    expect(isGeoMode('capitals')).toBe(true);
    expect(isGeoMode('toString')).toBe(false);
    expect(parseRegion('europe')).toBe('Europe');
    expect(parseRegion('atlantis')).toBe('World');
  });
});
