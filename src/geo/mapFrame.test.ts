import { feature } from 'topojson-client';
import type { GeometryCollection, Topology } from 'topojson-specification';
import { describe, expect, it } from 'vitest';
import world from 'world-atlas/countries-50m.json';
import { COUNTRIES } from './countries';
import { frameCountry, MAP_HEIGHT, MAP_WIDTH, type Shape } from './mapFrame';

const topology = world as unknown as Topology<{ countries: GeometryCollection }>;
const shapes = feature(topology, topology.objects.countries).features as Shape[];
const mappable = COUNTRIES.filter((c) => c.inMap).map((c) => [c.name, c.numeric] as const);

describe('frameCountry', () => {
  it.each(mappable)('puts %s on screen', (_, numeric) => {
    const view = frameCountry(shapes, numeric);
    expect(view).not.toBeNull();
    expect(view!.target).not.toBe('');
    const [[x0, y0], [x1, y1]] = view!.targetBounds;
    const [cx, cy] = [(x0 + x1) / 2, (y0 + y1) / 2];
    expect(cx).toBeGreaterThan(0);
    expect(cx).toBeLessThan(MAP_WIDTH);
    expect(cy).toBeGreaterThan(0);
    expect(cy).toBeLessThan(MAP_HEIGHT);
  });

  it('rings countries too small to see, but not large ones', () => {
    expect(frameCountry(shapes, '492')?.marker).not.toBeNull(); // Monaco
    expect(frameCountry(shapes, '250')?.marker).toBeNull(); // France
  });
});
