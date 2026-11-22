import { isComplete } from "./compare";
import { FORMAT } from "./exports";
import { Geometry, GeometryScan, TornTerritory } from "./types";

export const GEOMETRY_PAGE = 250;
export const GEOMETRY_EVERY = 7 * 86400;
const FIELDS = ["sector", "size", "density", "slots", "respect"] as const;

export interface TerritoryShape extends Geometry {
  label: number[];
  path: Array<string | number>;
}

export interface TerritoriesFile {
  format: number;
  version: number;
  generated_at: number;
  source: string;
  bounds: number[];
  territories: Record<string, TerritoryShape>;
}

export function territoriesKey(version: number): string {
  return `territories-v${version}.json.gz`;
}

export function geometryOf(api: TornTerritory): Geometry {
  return {
    sector: api.sector ?? null, size: api.size ?? null, density: api.density ?? null, slots: api.slots ?? null,
    respect: api.respect ?? null, neighbors: [...(api.neighbors ?? [])],
  };
}

export function sameGeometry(a: Geometry, b: Geometry): boolean {
  return FIELDS.every((f) => a[f] === b[f]) &&
    JSON.stringify([...a.neighbors].sort()) === JSON.stringify([...b.neighbors].sort());
}

export function newScan(version: number): GeometryScan {
  return { version, offset: 0, seen: [], changed: {}, missing: [] };
}

// Keeps only what differs from the file
export function scanPage(scan: GeometryScan, page: TornTerritory[], file: TerritoriesFile) {
  for (const api of page) {
    scan.seen.push(api.id);
    const old = file.territories[api.id];
    const geo = geometryOf(api);
    if (!old) scan.missing.push(api.id);
    else if (!sameGeometry(old, geo)) scan.changed[api.id] = geo;
  }
  scan.offset += GEOMETRY_PAGE;
}

export function pathBounds(territories: Record<string, TerritoryShape>): number[] {
  const xs: number[] = [];
  const ys: number[] = [];
  for (const t of Object.values(territories)) {
    const coords = t.path.filter((v): v is number => typeof v === "number");
    coords.forEach((v, i) => (i % 2 ? ys : xs).push(v));
  }
  return [Math.floor(Math.min(...xs)), Math.floor(Math.min(...ys)), Math.ceil(Math.max(...xs)),
    Math.ceil(Math.max(...ys))];
}

// Same shapes, new geometry, or null
export function nextTerritories(file: TerritoriesFile, scan: GeometryScan, now: number): TerritoriesFile | null {
  const seen = new Set(scan.seen);
  const known = Object.keys(file.territories);
  if (scan.missing.length || !isComplete(seen.size, known.length)) return null;
  const removed = known.filter((id) => !seen.has(id));
  if (!removed.length && !Object.keys(scan.changed).length) return null;
  const territories: Record<string, TerritoryShape> = {};
  for (const id of known.filter((code) => seen.has(code)).sort()) {
    const old = file.territories[id];
    const geo = scan.changed[id] ?? old;
    territories[id] = {
      sector: geo.sector, size: geo.size, density: geo.density, slots: geo.slots, respect: geo.respect,
      label: old.label, neighbors: geo.neighbors, path: old.path,
    };
  }
  return {
    format: FORMAT, version: file.version + 1, generated_at: now, source: file.source,
    bounds: pathBounds(territories), territories,
  };
}
