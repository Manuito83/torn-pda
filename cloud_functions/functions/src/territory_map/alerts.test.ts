import { test } from "node:test";
import * as assert from "node:assert/strict";
import { TickFacts, buildAlerts, duration, endingDue, pace } from "./alerts";
import { MapState, War, emptyState } from "./types";

const NOW = 1794000000;
const H = 3600;
const noFacts: TickFacts = { warsRead: true, warEvents: [], ownership: [], rackets: [] };

function war(overrides: Partial<War> = {}, aggressorWall = 3, defenderWall = 1): War {
  return {
    territory: "RCD", start: NOW - 30 * H, scheduled_end: NOW + 42 * H, target: 550000,
    aggressor: { id: 51387, name: "7DS*: Envy", score: 545000, chain: 0, wall: aggressorWall },
    defender: { id: 8315, name: "7DS*: Gluttony", score: 0, chain: 0, wall: defenderWall },
    result: "in_progress", ended_at: null, updated_at: NOW, ending_sent: false, samples: [], ...overrides,
  };
}

function mapState(wars: Record<string, War>): MapState {
  const state = emptyState();
  state.wars = wars;
  state.factions = {
    "51387": { name: "7DS*: Envy", tag: "7DS", tag_image: null, respect: null, rank: null, members: null },
    "8315": { name: "7DS*: Gluttony", tag: "GLU", tag_image: null, respect: null, rank: null, members: null },
  };
  return state;
}

test("ending: once when the score reaches the target within 1 h", () => {
  const w = war();
  assert.equal(endingDue(w, NOW), "score");
  const { messages, endings } = buildAlerts(mapState({ "46843": w }), noFacts, NOW);
  assert.deepEqual(endings, ["46843"]);
  assert.deepEqual(messages.map((m) => [m.title, m.body]),
    [["RCD: assault ends in about 1 h", "Attackers at 545,000 / 550,000 (+120/min)"]]);
  assert.deepEqual(messages[0].topics, ["tmap.f.51387.ending", "tmap.f.8315.ending", "tmap.t.RCD.ending"]);
  assert.equal(endingDue({ ...w, ending_sent: true }, NOW), null);
});

test("ending: 72 h deadline only above half the target", () => {
  const late = war({ scheduled_end: NOW + 50 * 60 }, 1, 1);
  late.aggressor.score = 310000;
  assert.equal(endingDue(late, NOW), "deadline");
  const msg = buildAlerts(mapState({ "1": late }), noFacts, NOW).messages[0];
  assert.equal(msg.body, "72 h deadline in about 1 h, attackers at 310,000 / 550,000");
  late.aggressor.score = 200000;
  assert.equal(endingDue(late, NOW), null);
});

test("ending: a fake wall at the deadline alerts nobody", () => {
  const fake = war({ scheduled_end: NOW + 30 * 60, target: 1000000 }, 0, 20);
  fake.aggressor.score = 0;
  assert.equal(endingDue(fake, NOW), null);
});

test("pace: attackers and defenders share target / 50,000 slots", () => {
  assert.equal(pace(war({}, 4, 3)), 60);
  assert.equal(pace(war({ target: 100000 }, 3, 1)), 120);
});

test("war: start and end texts with tags and duration", () => {
  const w = war({ result: "success_assault", ended_at: NOW, start: NOW - 26 * H - 5 * 60 });
  w.aggressor.score = 550000;
  const facts: TickFacts = { ...noFacts, warEvents: [
    { war_id: 46843, kind: "start", result: "in_progress" },
    { war_id: 46843, kind: "end", result: "success_assault" },
  ] };
  const messages = buildAlerts(mapState({ "46843": w }), facts, NOW).messages;
  assert.deepEqual(messages.map((m) => [m.key, m.kind, m.title, m.body]), [
    ["war:46843:start", "assault_started", "Assault on RCD", "[7DS] 7DS*: Envy is attacking RCD, held by [GLU] 7DS*: Gluttony"],
    ["war:46843:end", "assault_ended", "RCD conquered by [7DS] 7DS*: Envy", "Final score 550,000 / 550,000 after 1 d 2 h"],
  ]);
  assert.deepEqual([messages[0].factionId, messages[0].warId], ["8315", "46843"]);
  assert.equal(duration(5 * H + 12 * 60), "5 h 12 min");
});

test("owner: a conquest carries its war, an abandon skips faction 0", () => {
  const ended = war({ result: "success_assault", ended_at: NOW - 240 });
  const facts: TickFacts = { ...noFacts, ownership: [
    { territory: "RCD", kind: "owner", faction_id: 51387, previous_faction_id: 8315, irradiated: 0 },
    { territory: "QFA", kind: "owner", faction_id: 0, previous_faction_id: 8315, irradiated: 0 },
    { territory: "QFB", kind: "reacquired", faction_id: 8315, previous_faction_id: 8315, irradiated: 0 },
  ] };
  const messages = buildAlerts(mapState({ "46843": ended }), facts, NOW).messages;
  assert.deepEqual(messages.map((m) => [m.title, m.body, m.warId]), [
    ["RCD conquered", "[GLU] 7DS*: Gluttony → [7DS] 7DS*: Envy", "46843"],
    ["QFA abandoned by [GLU] 7DS*: Gluttony", "[GLU] 7DS*: Gluttony → nobody", ""],
  ]);
  assert.deepEqual(messages[1].topics, ["tmap.f.8315.owner", "tmap.t.QFA.owner"]);
});

test("racket: new, level and removed texts to the owner and the territory", () => {
  const state = mapState({});
  state.rackets.IFE = { faction_id: 7835, name: "Bootleg Distillery I", level: 1,
    description: "10x Bottle of Moonshine daily", reward: null, changed_at: 0 };
  const base = { faction_id: 7835, previous_faction_id: null as number | null, previous_level: null as number | null,
    name: "Bootleg Distillery I" };
  const facts: TickFacts = { ...noFacts, rackets: [
    { ...base, territory: "IFE", kind: "new", level: 1 },
    { ...base, territory: "IFE", kind: "level", level: 3, previous_level: 1 },
    { ...base, territory: "DJC", kind: "removed", faction_id: 0, previous_faction_id: 29865, level: 0 },
    { ...base, territory: "WZD", kind: "owner", level: 5 },
  ] };
  const messages = buildAlerts(state, facts, NOW).messages;
  assert.deepEqual(messages.map((m) => [m.title, m.body, m.topics.join(" ")]), [
    ["New racket in IFE", "Bootleg Distillery I: 10x Bottle of Moonshine daily", "tmap.f.7835.racket tmap.t.IFE.racket"],
    ["IFE racket is now level 3", "Bootleg Distillery I: 10x Bottle of Moonshine daily",
      "tmap.f.7835.racket tmap.t.IFE.racket"],
    ["DJC lost its racket", "Bootleg Distillery I is gone", "tmap.f.29865.racket tmap.t.DJC.racket"],
  ]);
});
