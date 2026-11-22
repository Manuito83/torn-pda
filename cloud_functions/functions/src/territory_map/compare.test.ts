import { test } from "node:test";
import * as assert from "node:assert/strict";
import { readFileSync } from "fs";
import { join } from "path";
import {
  isComplete, irradiationsFrom, linkBombTerritories, matchIrradiations, mergeBombs, ownerRow, ownershipChanges,
  parseFactionCsv, racketChanges, racketRow, recentDetonations, takeSample, warChanges, warRow,
} from "./compare";
import { Owner, TornWar, War } from "./types";

const FIXTURES = join(__dirname, "../../src/territory_map/fixtures");
const fixture = (name: string) => JSON.parse(readFileSync(join(FIXTURES, name), "utf8"));
const NOW = 1793760000;

const apiWars: TornWar[] = fixture("warfareterritory.json").warfareterritory;
const rcd = () => structuredClone(apiWars.find((w) => w.territory === "RCD") as TornWar);

function known(api: TornWar, overrides: Partial<War> = {}): Record<string, War> {
  return { [String(api.id)]: { ...warRow(api, undefined, NOW - 120), ...overrides } };
}

test("ownership: owner, reacquired and irradiated against the stored rows", () => {
  const page = fixture("territoryownership.json").territoryOwnership.slice(0, 4);
  const stored: Record<string, Owner> = {};
  for (const item of page) stored[item.id] = ownerRow(item);
  page[0].owned_by = 999;
  page[1].acquired_at += 60;
  page[2].irradiated = true;
  const { changes } = ownershipChanges(stored, page, false);
  assert.deepEqual(changes.map((c) => [c.territory, c.kind]),
    [["JTB", "owner"], ["KTB", "reacquired"], ["LTB", "irradiated"]]);
  assert.equal(changes[0].previous_faction_id, 14386);
  assert.deepEqual(irradiationsFrom(changes, NOW), [["LTB", NOW]]);
});

test("ownership: the first read gives no changes", () => {
  const page = fixture("territoryownership.json").territoryOwnership;
  const { changes, rows } = ownershipChanges({}, page, true);
  assert.equal(changes.length, 0);
  assert.equal(Object.keys(rows).length, 20);
});

test("ownership: a list at 80 % removes nothing, at 90 % it does", () => {
  assert.equal(isComplete(3286, 4108), false);
  assert.equal(isComplete(3698, 4108), true);
});

test("wars: a new assault starts, but not on the first read", () => {
  assert.deepEqual(warChanges({}, [rcd()], 0, false, NOW).events, [{ war_id: 46843, kind: "start", result: "in_progress" }]);
  assert.deepEqual(warChanges({}, [rcd()], 0, true, NOW).events, []);
});

test("wars: an assault seen in progress ends with its result and read time", () => {
  const ended = rcd();
  ended.result = "success_assault";
  const { rows, events } = warChanges(known(rcd()), [ended], 0, false, NOW);
  assert.deepEqual(events, [{ war_id: 46843, kind: "end", result: "success_assault" }]);
  assert.equal(rows["46843"].ended_at, NOW);
});

test("wars: an assault already over when first seen is not kept", () => {
  const over = apiWars.filter((w) => w.result !== "in_progress");
  const { rows, events } = warChanges({}, over, 0, false, NOW);
  assert.deepEqual(rows, {});
  assert.deepEqual(events, []);
});

test("wars: vanishing inside the covered window is unknown, outside it is not", () => {
  const stored = known(rcd());
  const other = apiWars.filter((w) => w.id !== 46843);
  const rcdEvents = (coveredFrom: number) =>
    warChanges(stored, other, coveredFrom, false, NOW).events.filter((e) => e.war_id === 46843);
  assert.deepEqual(rcdEvents(rcd().start - 1), [{ war_id: 46843, kind: "end", result: "unknown" }]);
  assert.equal(warChanges(stored, other, rcd().start - 1, false, NOW).rows["46843"].result, "unknown");
  assert.deepEqual(rcdEvents(rcd().start + 1), []);
});

test("wars: an unknown assault that comes back in progress reopens", () => {
  const stored = known(rcd(), { result: "unknown", ended_at: NOW - 600 });
  const { rows, events } = warChanges(stored, [rcd()], 0, false, NOW);
  assert.deepEqual(events, [{ war_id: 46843, kind: "reopen", result: "in_progress" }]);
  assert.equal(rows["46843"].ended_at, null);
});

test("samples: one every 10 min, and only when something changed", () => {
  const war = warRow(rcd(), undefined, NOW);
  const first = takeSample(war, NOW);
  assert.deepEqual(first, [NOW, 29698, 3, 0, 0]);
  war.samples = [first!];
  assert.equal(takeSample(war, NOW + 300), null);
  assert.equal(takeSample(war, NOW + 600), null);
  war.aggressor.score += 1800;
  assert.deepEqual(takeSample(war, NOW + 600), [NOW + 600, 31498, 3, 0, 0]);
});

test("rackets: new and level, and removed only with a complete list", () => {
  const api = fixture("rackets.json").rackets;
  const stored = Object.fromEntries(api.map((r: any) => [r.territory, racketRow(r)]));
  const next = structuredClone(api);
  next[0].level = 2;
  next.push({ ...api[1], territory: "AAA" });
  const kinds = (list: any[]) => racketChanges(stored, list).changes.map((c) => [c.territory, c.kind]);
  assert.deepEqual(kinds(next), [["IFE", "level"], ["AAA", "new"]]);
  assert.deepEqual(kinds(api.slice(1)), [["IFE", "removed"]]);
  assert.deepEqual(kinds(api.slice(3)), []);
});

test("bombs: an irradiation in the window goes to the closest bomb", () => {
  const api = fixture("dirtybombs.json").dirtybombs;
  const det = 1792947668;
  const bombs = mergeBombs([], api, 0, det - 3600);
  const detonations = recentDetonations(bombs, det - 60);
  assert.deepEqual([...detonations.keys()], [89]);
  const links = matchIrradiations(detonations, [["RFG", det + 32], ["XYZ", det + 16 * 60], ["ABC", det - 60]]);
  assert.deepEqual(links, [[89, "RFG", det + 32], [89, "ABC", det - 60]]);
  const closer = [{ ...bombs[0], id: 90, detonated_at: det + 30 }, ...bombs];
  const linked = linkBombTerritories({ "89": [["RFG", det + 32]] }, [[90, "RFG", det + 32]], closer);
  assert.deepEqual(linked, { "90": [["RFG", det + 32]] });
});

test("bombs: an empty field keeps what was stored", () => {
  const [stored] = mergeBombs([], fixture("dirtybombs.json").dirtybombs, 0, NOW);
  const [merged] = mergeBombs([stored], [{ id: 89, detonated_at: null, faction: null }], 0, NOW + 3600);
  assert.deepEqual(merged, stored);
});

test("factions: the snapshot CSV with quotes and empty tags", () => {
  const factions = parseFactionCsv(readFileSync(join(FIXTURES, "snapshot.csv"), "utf8"));
  assert.equal(Object.keys(factions).length, 15);
  assert.deepEqual(factions["19"], {
    name: "39th Street Killers", tag: "39th", tag_image: "19-91655.png", respect: 19217831, rank: 1, members: 91,
  });
  assert.equal(factions["59"].tag, null);
});
