import { useEffect, useMemo, useState } from 'react';
import { feature } from 'topojson-client';
import type { GeometryCollection, Topology } from 'topojson-specification';
import worldUrl from 'world-atlas/countries-50m.json?url';
import { frameCountry, MAP_HEIGHT, MAP_WIDTH, type Shape } from './mapFrame';

type World = Topology<{ countries: GeometryCollection; land: GeometryCollection }>;

let shapesPromise: Promise<Shape[]> | null = null;

function loadShapes(): Promise<Shape[]> {
  shapesPromise ??= fetch(worldUrl)
    .then((res) => {
      if (!res.ok) throw new Error(`Failed to load map: HTTP ${res.status}`);
      return res.json() as Promise<World>;
    })
    .then((world) => feature(world, world.objects.countries).features as Shape[]);
  shapesPromise.catch(() => {
    shapesPromise = null;
  });
  return shapesPromise;
}

export default function WorldMap({ numeric }: { numeric: string }) {
  const [shapes, setShapes] = useState<Shape[] | null>(null);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    let live = true;
    loadShapes().then(
      (s) => {
        if (live) setShapes(s);
      },
      () => {
        if (live) setFailed(true);
      },
    );
    return () => {
      live = false;
    };
  }, []);

  const view = useMemo(() => (shapes ? frameCountry(shapes, numeric) : null), [shapes, numeric]);

  if (failed) return <div className="map-frame map-message">Couldn’t load the map.</div>;
  if (!view) return <div className="map-frame map-message">Loading map…</div>;

  return (
    <svg
      className="map-frame"
      viewBox={`0 0 ${MAP_WIDTH} ${MAP_HEIGHT}`}
      role="img"
      aria-label="Map with one country highlighted"
    >
      <path className="map-land" d={view.land} />
      <path className="map-target" d={view.target} />
      {view.marker && <circle className="map-marker" cx={view.marker[0]} cy={view.marker[1]} r={18} />}
    </svg>
  );
}
