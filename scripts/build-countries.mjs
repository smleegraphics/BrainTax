// Generates src/data/countries.json from the world-countries package (ODbL-1.0).
// Run with `npm run data:countries` after upgrading world-countries or world-atlas.
import { existsSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const countries = require('world-countries/countries.json');
const topology = require('world-atlas/countries-50m.json');

const mapIds = new Set(
  topology.objects.countries.geometries.map((g) => g.id).filter(Boolean),
);

const out = countries
  .filter((c) => c.independent)
  .map((c) => {
    const code = c.cca2.toLowerCase();
    if (!existsSync(`node_modules/flag-icons/flags/4x3/${code}.svg`)) {
      throw new Error(`No flag-icons SVG for ${c.name.common} (${code})`);
    }
    return {
      code,
      numeric: c.ccn3,
      name: c.name.common,
      capital: c.capital[0],
      region: c.region,
      subregion: c.subregion,
      inMap: mapIds.has(c.ccn3),
    };
  })
  .sort((a, b) => a.name.localeCompare(b.name));

writeFileSync('src/data/countries.json', JSON.stringify(out, null, 1) + '\n');
console.log(
  `Wrote ${out.length} countries (${out.filter((c) => !c.inMap).length} without map shapes)`,
);
