import { test } from "node:test";
import * as assert from "node:assert/strict";
import { planWarFiles } from "./publish";
import { MapState, War, emptyState } from "./types";
import { buildWarFile, isClosed, nextTry, queueReports, reportFrom, reportMissed } from "./war_files";

const NOW = 1794000000;
const H = 3600;

function ended(overrides: Partial<War> = {}): War {
  return {
    territory: "RCD", start: NOW - 50 * H, scheduled_end: NOW + 22 * H, target: 300000,
    aggressor: { id: 14821, name: "Envy", score: 63934, chain: 0, wall: 0 },
    defender: { id: 26312, name: "Gluttony", score: 0, chain: 0, wall: 2 },
    result: "end_with_peace_treaty", ended_at: NOW - H, updated_at: NOW, ending_sent: false,
    samples: [[NOW - 3 * H, 0, 3, 0, 0], [NOW - 2 * H, 1800, 3, 0, 0]], ...overrides,
  };
}

function withWar(war: War): MapState {
  const state = emptyState();
  state.wars["46843"] = war;
  return state;
}

test("report retries: 1, 2, 5, 10, 30 min, 1, 3 and 12 h, then none", () => {
  const waits = [1, 2, 3, 4, 5, 6, 7, 8, 9].map((n) => nextTry(n, NOW));
  assert.deepEqual(waits.map((t) => (t === null ? null : t - NOW)),
    [60, 120, 300, 600, 1800, 3600, 3 * H, 12 * H, null]);
  const reports = emptyState().reports;
  queueReports(reports, [46843], NOW);
  let r = reports["46843"];
  for (let i = 0; i < 9; i++) r = reportMissed(r, NOW);
  assert.equal(r.next_try_at, null);
});

test("seen ending again restarts a pending report, never a fetched one", () => {
  const reports = emptyState().reports;
  queueReports(reports, [1, 2], NOW);
  reports["1"] = reportMissed(reports["1"], NOW);
  reports["2"] = reportFrom({ ended_at: NOW, winner: 7, factions: [] }, NOW, 1);
  queueReports(reports, [1, 2], NOW + 60);
  assert.deepEqual([reports["1"].attempts, reports["1"].next_try_at], [0, NOW + 60]);
  assert.equal(reports["2"].fetched_at, NOW);
});

test("war file: no report while pending, sides and a null winner after a truce", () => {
  const state = withWar(ended());
  queueReports(state.reports, [46843], NOW);
  const pending = buildWarFile(state, "46843", NOW);
  assert.equal(pending.report, null);
  assert.deepEqual(pending.samples, [[NOW - 3 * H, 0, 3, 0], [NOW - 2 * H, 1800, 3, 0]]);
  assert.equal(pending.war.ended_at, NOW - H);
  state.reports["46843"] = reportFrom({
    ended_at: NOW - H, winner: 0,
    factions: [{ id: 14821, is_aggressor: true, score: 243221, joins: 3, clears: 0 },
      { id: 26312, is_aggressor: false, score: 2446864, joins: 23, clears: 0 }],
  }, NOW, 1);
  assert.deepEqual(buildWarFile(state, "46843", NOW).report, {
    winner: null, ended_at: NOW - H, aggressor: { score: 243221, joins: 3, clears: 0 },
    defender: { score: 2446864, joins: 23, clears: 0 },
  });
});

test("war file: open while in progress", () => {
  const state = withWar(ended({ result: "in_progress", ended_at: null }));
  const doc = buildWarFile(state, "46843", NOW);
  assert.deepEqual([doc.war.result, doc.war.ended_at, doc.report], ["in_progress", null, null]);
  assert.equal(isClosed(state.wars["46843"], undefined, NOW), false);
});

test("war file closes with the report, without retries left, or 24 h after the end", () => {
  const war = ended();
  const reports = emptyState().reports;
  queueReports(reports, [46843], NOW);
  assert.equal(isClosed(war, reports["46843"], NOW), false);
  assert.equal(isClosed(war, { ...reports["46843"], next_try_at: null }, NOW), true);
  assert.equal(isClosed(war, reportFrom({ factions: [] }, NOW, 1), NOW), true);
  assert.equal(isClosed(ended({ ended_at: NOW - 25 * H }), reports["46843"], NOW), true);
});

test("a closed war file counts as closed only once it is up", () => {
  const state = withWar(ended());
  state.reports["46843"] = reportFrom({ ended_at: NOW - H, winner: 14821, factions: [] }, NOW, 1);
  const [upload] = planWarFiles(state, "", NOW);
  assert.equal(upload.key, "wars/46843.json.gz");
  assert.equal(state.published[upload.key].closed, undefined);
  assert.equal(planWarFiles(state, "", NOW + 60).length, 1);
  upload.done?.();
  assert.equal(state.published[upload.key].closed, true);
  assert.deepEqual(planWarFiles(state, "", NOW + 120), []);
});

test("a report without a body counts as a miss", () => {
  assert.throws(() => reportFrom(undefined as never, NOW, 1), TypeError);
});
