import { geoArea, geoAzimuthalEqualArea, geoCentroid, geoPath } from 'd3-geo';

export type Shape = GeoJSON.Feature<GeoJSON.Polygon | GeoJSON.MultiPolygon>;

export const MAP_WIDTH = 600;
export const MAP_HEIGHT = 400;
/** Never zoom in closer than ~2,000 km across, so tiny countries keep their neighbours in view. */
const MAX_SCALE = MAP_WIDTH / (2000 / 6371);
/** Targets smaller than this many pixels get a ring drawn around them. */
const MARKER_THRESHOLD = 14;

export interface MapView {
  /** SVG path data for every other country. */
  land: string;
  target: string;
  targetBounds: [[number, number], [number, number]];
  /** Center of a ring to draw around targets too small to see, if needed. */
  marker: [number, number] | null;
}

/** The parts of a country worth framing, dropping far-flung territory like French Guiana. */
function mainland(shape: Shape): Shape {
  if (shape.geometry.type !== 'MultiPolygon') return shape;
  const parts = shape.geometry.coordinates.map((coordinates) => {
    const polygon: GeoJSON.Polygon = { type: 'Polygon', coordinates };
    return { coordinates, area: geoArea(polygon) };
  });
  const largest = Math.max(...parts.map((p) => p.area));
  return {
    ...shape,
    geometry: {
      type: 'MultiPolygon',
      coordinates: parts.filter((p) => p.area >= largest * 0.2).map((p) => p.coordinates),
    },
  };
}

/** Projects the world centered on one country (by ISO numeric id) with its neighbours around it. */
export function frameCountry(shapes: readonly Shape[], numeric: string): MapView | null {
  const target = shapes.find((s) => s.id === numeric);
  if (!target) return null;

  // An equal-area projection centered on the country keeps any part of the globe
  // undistorted (including countries that straddle the antimeridian), and fitting it
  // to the middle of the frame leaves context visible around it.
  const focus = mainland(target);
  const [lon, lat] = geoCentroid(focus);
  const projection = geoAzimuthalEqualArea()
    .rotate([-lon, -lat])
    .clipAngle(90)
    .fitExtent([[MAP_WIDTH * 0.2, MAP_HEIGHT * 0.2], [MAP_WIDTH * 0.8, MAP_HEIGHT * 0.8]], focus);
  if (projection.scale() > MAX_SCALE) projection.scale(MAX_SCALE).translate([MAP_WIDTH / 2, MAP_HEIGHT / 2]);
  projection.clipExtent([[-10, -10], [MAP_WIDTH + 10, MAP_HEIGHT + 10]]);

  const path = geoPath(projection);
  const focusBounds = path.bounds(focus);
  const [[x0, y0], [x1, y1]] = focusBounds;
  const tiny = x1 - x0 < MARKER_THRESHOLD && y1 - y0 < MARKER_THRESHOLD;
  return {
    land: shapes
      .filter((s) => s !== target)
      .map((s) => path(s) ?? '')
      .join(''),
    target: path(target) ?? '',
    targetBounds: focusBounds,
    marker: tiny ? projection([lon, lat]) : null,
  };
}
