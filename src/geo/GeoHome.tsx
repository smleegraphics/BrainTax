import { useState } from 'react';
import { ChevronRight, Header } from '../components/Header';
import { load, save } from '../lib/storage';
import { DEFAULT_GEO_STATS, GEO_STATS_KEY } from '../lib/stats';
import { REGION_FILTERS, regionSlug, type RegionFilter } from './countries';
import { bestKey, eligibleCountries, GEO_MODE_IDS, GEO_MODES, ROUND_LENGTH } from './quiz';

export default function GeoHome() {
  const [stats, setStats] = useState(() => load(GEO_STATS_KEY, DEFAULT_GEO_STATS));
  const region = REGION_FILTERS.includes(stats.region) ? stats.region : 'World';

  const chooseRegion = (next: RegionFilter) => {
    const updated = { ...stats, region: next };
    setStats(updated);
    save(GEO_STATS_KEY, updated);
  };

  return (
    <>
      <Header title="Geography" />
      <main>
        <div className="chips" role="radiogroup" aria-label="Region">
          {REGION_FILTERS.map((r) => (
            <button
              key={r}
              type="button"
              role="radio"
              aria-checked={r === region}
              className={r === region ? 'chip chip-on' : 'chip'}
              onClick={() => chooseRegion(r)}
            >
              {r}
            </button>
          ))}
        </div>
        <p className="meta meta-left">
          {eligibleCountries('flags', region).length} countries · {ROUND_LENGTH} questions a round
        </p>

        <nav className="card-list">
          {GEO_MODE_IDS.map((mode) => {
            const best = stats.best[bestKey(mode, region)];
            return (
              <a key={mode} className="card" href={`#/geo/${mode}/${regionSlug(region)}`}>
                <span className="card-icon" aria-hidden="true">
                  {GEO_MODES[mode].icon}
                </span>
                <span className="card-body">
                  <span className="card-title">{GEO_MODES[mode].title}</span>
                  <span className="card-sub">{GEO_MODES[mode].blurb}</span>
                </span>
                {best !== undefined && (
                  <span className="card-badge" aria-label={`Best score ${best} of ${ROUND_LENGTH}`}>
                    {best}/{ROUND_LENGTH}
                  </span>
                )}
                <ChevronRight />
              </a>
            );
          })}
        </nav>
      </main>
    </>
  );
}
