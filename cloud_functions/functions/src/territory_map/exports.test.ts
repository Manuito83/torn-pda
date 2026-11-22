import { test } from "node:test";
import * as assert from "node:assert/strict";
import { STATE_CACHE, buildState, digest, warIdle, warRate } from "./exports";
import { MapState, War, emptyState } from "./types";

const NOW = 1794000000;
const H = 3600;

function war(overrides: Partial<War> = {}): War {
  return {
    territory: "RCD", start: NOW - 10 * H, scheduled_end: NOW + 62 * H, target: 300000,
    aggressor: { id: 14821, name: "Envy", score: 1600, chain: 0, wall: 3 },
    defender: { id: 26312, name: "Gluttony", score: 0, chain: 0, wall: 0 },
    result: "in_progress", ended_at: null, updated_at: NOW, ending_sent: false, samples: [], ...overrides,
  };
}

function mapState(): MapState {
  const state = emptyState();
  state.read_at = { wars: NOW, ownership: NOW - 100 };
  state.ownership = { RCD: [26312, 1790000000, 0], BAA: [0, 0, 1] };
  state.wars = {
    "46843": war(),
    "46801": war({ territory: "QFA", result: "success_assault", ended_at: NOW - 71 * H }),
    "46700": war({ territory: "ZZG", result: "fail_assault", ended_at: NOW - 73 * H }),
  };
  state.factions = { "26312": { name: "Gluttony", tag: "GLU", tag_image: null, respect: 1, rank: 2, members: 3 } };
  state.rackets = {
    IFE: { faction_id: 7835, name: "Bootleg Distillery I", level: 1, description: "10x Bottle of Moonshine daily",
      reward: { type: "Item", quantity: 10, id: 984 }, changed_at: 1793624223 },
    KFE: { faction_id: 7835, name: "Points I", level: 1, description: "2000x Points daily",
      reward: { type: "Points", quantity: 2000 }, changed_at: 1 },
    NHE: { faction_id: 7835, name: "Money", level: 1, description: "$80,000,000 daily",
      reward: { type: "Money", quantity: 80000000 }, changed_at: 1 },
    VRE: { faction_id: 7835, name: "No price", level: 1, description: "400x Thing daily",
      reward: { type: "Item", quantity: 400, id: 256 }, changed_at: 1 },
  };
  state.prices = {
    "Item:984": { name: "Bottle of Moonshine", price: 5500, day: "2026-11-07" },
    "Points:0": { name: "Points", price: 32966, day: "2026-11-07" },
  };
  state.bombs = [{ id: 89, detonated_at: NOW - 2 * H, faction_id: 13377, respect_lost: 769315, first_seen_at: NOW }];
  state.bomb_territories = { "89": [["RFG", NOW - 2 * H + 30]] };
  return state;
}

test("rate: against the latest sample at least 5 min older, 0 without one", () => {
  const samples: War["samples"] = [[NOW - 600, 1000, 3, 0, 0], [NOW - 200, 1500, 3, 0, 0]];
  assert.deepEqual(warRate(war({ samples })), { aggressor: 60, defender: 0 });
  assert.deepEqual(warRate(war({ samples: [[NOW - 200, 1500, 3, 0, 0]] })), { aggressor: 0, defender: 0 });
});

test("idle: from the last run without attackers and the last score change", () => {
  const start = NOW - 10 * H;
  const samples: War["samples"] = [[start + 600, 0, 0, 2, 0], [start + 1200, 600, 1, 0, 0], [start + 1800, 600, 0, 0, 0]];
  const w = war({ start, samples, updated_at: start + 2400 });
  w.aggressor = { ...w.aggressor, score: 600, wall: 0 };
  assert.deepEqual(warIdle(w), { no_attackers_since: start + 1800, score_changed_at: start + 1200 });
  assert.deepEqual(warIdle(war({ samples: [] })).no_attackers_since, null);
});

test("state: the keys parseMapState needs, with revision 2 extras", () => {
  const doc = buildState(mapState(), NOW);
  assert.equal(doc.format, 1);
  assert.equal(doc.revision, 2);
  assert.deepEqual(doc.read_at, { ownership: NOW - 100, wars: NOW });
  assert.deepEqual(doc.ownership, { BAA: [0, 0, 1], RCD: [26312, 1790000000, 0] });
  assert.deepEqual(doc.wars.map((w) => w.id), [46843]);
  assert.deepEqual(Object.keys(doc.wars[0]).sort(), ["aggressor", "defender", "id", "idle", "rate", "scheduled_end",
    "score_at", "start", "target", "territory"]);
  assert.deepEqual(doc.wars[0].aggressor, { id: 14821, score: 1600, chain: 0, wall: 3 });
  assert.deepEqual(doc.bombs, [{ id: 89, detonated_at: NOW - 2 * H, faction_id: 13377, respect_lost: 769315,
    territories: ["RFG"] }]);
});

test("state: recent wars within 72 h and 10 min, newest first", () => {
  const doc = buildState(mapState(), NOW);
  assert.deepEqual(doc.recent_wars, [{ id: 46801, territory: "QFA", start: NOW - 10 * H, ended_at: NOW - 71 * H,
    result: "success_assault", aggressor: 14821, defender: 26312, score: 1600, target: 300000 }]);
});

test("state: reward items priced, money at 1, unpriced null", () => {
  const rackets = buildState(mapState(), NOW).rackets;
  assert.deepEqual(rackets.IFE.reward_item, { type: "item", id: 984, name: "Bottle of Moonshine", quantity: 10,
    price: 5500, priced_at: "2026-11-07" });
  assert.equal(rackets.KFE.reward_item?.price, 32966);
  assert.deepEqual(rackets.NHE.reward_item, { type: "money", id: 0, name: "Money", quantity: 80000000, price: 1,
    priced_at: null });
  assert.equal(rackets.VRE.reward_item, null);
  assert.equal(rackets.IFE.reward, "10x Bottle of Moonshine daily");
});

test("state: a faction without snapshot row takes the war's name", () => {
  const factions = buildState(mapState(), NOW).factions;
  assert.deepEqual(Object.keys(factions), ["7835", "14821", "26312"]);
  assert.deepEqual(factions["14821"], { name: "Envy", tag: null, tag_image: null, respect: null, rank: null,
    members: null });
  assert.equal((factions["26312"] as { tag: string }).tag, "GLU");
});

test("digest: generated_at does not count, content does", () => {
  const state = mapState();
  const a = digest(buildState(state, NOW), STATE_CACHE);
  assert.equal(digest(buildState(state, NOW + 120), STATE_CACHE), a);
  state.ownership.BAA = [5, 0, 1];
  assert.notEqual(digest(buildState(state, NOW + 120), STATE_CACHE), a);
});
