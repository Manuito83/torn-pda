import { test } from "node:test";
import * as assert from "node:assert/strict";
import { TerritoriesFile, TerritoryShape, newScan, nextTerritories, scanPage } from "./territories";
import { TornTerritory } from "./types";

const NOW = 1794000000;

function shape(respect: number, neighbors: string[], path: Array<string | number>): TerritoryShape {
  return { sector: 1, size: 2, density: 3, slots: 6, respect, label: [1, 1], neighbors, path };
}

function file(): TerritoriesFile {
  const territories: Record<string, TerritoryShape> = {};
  for (let i = 0; i < 10; i++) territories[`A${i}A`] = shape(10, ["BBB", "CCC"], ["M", i, 0, "L", i + 1, 2, "Z"]);
  return { format: 1, version: 1, generated_at: 1, source: "torn.com", bounds: [], territories };
}

function api(id: string, respect = 10, neighbors = ["CCC", "BBB"]): TornTerritory {
  return { id, sector: 1, size: 2, density: 3, slots: 6, respect, neighbors };
}

function scanned(page: TornTerritory[]) {
  const scan = newScan(1);
  scanPage(scan, page, file());
  return scan;
}

const all = () => Object.keys(file().territories).map((id) => api(id));

test("geometry: same data in another neighbor order is no new version", () => {
  assert.equal(nextTerritories(file(), scanned(all()), NOW), null);
});

test("geometry: a new respect makes the next version with the same shapes", () => {
  const page = all();
  page[3] = api("A3A", 25);
  const next = nextTerritories(file(), scanned(page), NOW);
  assert.equal(next?.version, 2);
  assert.equal(next?.territories.A3A.respect, 25);
  assert.deepEqual(next?.territories.A3A.path, file().territories.A3A.path);
  assert.deepEqual(next?.bounds, [0, 0, 10, 2]);
});

test("geometry: a code without a shape keeps the version", () => {
  assert.equal(nextTerritories(file(), scanned([...all(), api("ZZZ")]), NOW), null);
});

test("geometry: a removed territory leaves; a short list removes nothing", () => {
  const next = nextTerritories(file(), scanned(all().slice(1)), NOW);
  assert.deepEqual(Object.keys(next?.territories ?? {}).length, 9);
  assert.equal(nextTerritories(file(), scanned(all().slice(2)), NOW), null);
});
