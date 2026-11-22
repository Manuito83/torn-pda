import { test } from "node:test";
import * as assert from "node:assert/strict";
import { gunzipSync } from "zlib";
import { encodeGzip } from "./exports";
import { pruneLog } from "./day_changes";
import { DatedWar, HistoryDoc, addDay, emptyHistory, historyCache, keepForHistory } from "./history";
import { closeDays, publishTerritories } from "./publish";
import { R2Files } from "./r2";
import { ChangeRow, MapState, War, dayStart, emptyState } from "./types";

const DAY = "2026-11-05";
const AT = dayStart(DAY) + 12 * 3600;
const names = (id: number) => ({ name: `F${id}`, tag: null as string | null });

function dated(id: number, day: string, ended: number | null = AT): DatedWar {
  return { row: [id, "QFA", AT - 86400, ended, "success_assault", 36811, 9032, 300000, 300000, 1], day };
}

test("history: day rows by kind, wars ended by then and every faction cited", () => {
  const rows: ChangeRow[] = [
    [AT, "ownership", "QFA", "owner", 36811, 9032, 46801, null, null],
    [AT, "racket", "IFE", "level", 7835, 7835, null, null, { level: 3, previous_level: 2, name: "Distillery III" }],
    [AT, "bomb", null, "new", 13377, null, null, 89, { respect_lost: 769315, territories: ["RFG"] }],
    [AT, "war", "QFA", "end:success_assault", 36811, 9032, 46801, null, { score: 1, target: 1 }],
  ];
  const wars = [dated(46801, DAY), dated(46900, "2026-11-06"), dated(40000, "2025-12-30")];
  const doc = addDay(emptyHistory(2026, 1793875200), DAY, rows, wars, names, AT);
  assert.deepEqual(doc.owners, [[AT, "QFA", "owner", 36811, 9032, 46801]]);
  assert.deepEqual(doc.rackets, [[AT, "IFE", "level", 7835, 3, 2, "Distillery III"]]);
  assert.deepEqual(doc.bombs, [[89, AT, 13377, 769315, ["RFG"]]]);
  assert.deepEqual(doc.wars.map((w) => w[0]), [46801]);
  assert.deepEqual(Object.keys(doc.factions), ["7835", "9032", "13377", "36811"]);
  assert.equal(doc.through, DAY);
  assert.equal(doc.complete_from, 1793875200);
});

test("history: a war seen again updates its row", () => {
  const first = addDay(emptyHistory(2026, 0), DAY, [], [dated(46801, DAY)], names, AT);
  const late: DatedWar = { ...dated(46801, DAY), row: [...dated(46801, DAY).row] };
  late.row[9] = 0;
  const again = addDay(first, "2026-11-06", [], [late], names, AT);
  assert.equal(again.wars.length, 1);
  assert.equal(again.wars[0][9], 0);
});

test("history: the current year revalidates, a closed year is immutable", () => {
  assert.equal(historyCache("2026-11-05"), "public, max-age=3600");
  assert.equal(historyCache("2026-12-31"), "public, max-age=31536000, immutable");
});

// Bucket in memory
function bucket(files: Record<string, Buffer> = {}) {
  const puts: string[] = [];
  const gets: string[] = [];
  const r2: R2Files = {
    async get(key) {
      gets.push(key);
      return files[key] ?? null;
    },
    async put(key, body) {
      files[key] = body;
      puts.push(key);
    },
    async headPublic() {
      return 404;
    },
  };
  return { files, puts, gets, r2 };
}

function stateSince(since: number, now: number): MapState {
  const state = emptyState();
  state.log.since = since;
  state.read_at = { bombs: now, ownership: now };
  state.log.days["2026-11-05"] = [[AT, "ownership", "QFA", "owner", 36811, 9032, null, null, null]];
  return state;
}

const read = (b: Buffer): HistoryDoc => JSON.parse(gunzipSync(b).toString());

test("close: in shadow the year starts at the first full day", async () => {
  const now = dayStart("2026-11-07") + 4 * 3600;
  const { files, puts, r2 } = bucket();
  const state = stateSince(dayStart("2026-11-04") + 3600, now);
  await closeDays(state, "shadow/", now, r2);
  assert.deepEqual(puts, ["shadow/changes/2026-11-05.json.gz", "shadow/changes/2026-11-06.json.gz",
    "shadow/history/2026.json.gz"]);
  const doc = read(files["shadow/history/2026.json.gz"]);
  assert.deepEqual([doc.through, doc.complete_from, doc.owners.length], ["2026-11-06", dayStart("2026-11-05"), 1]);
  assert.equal(state.log.closed["shadow/"], "2026-11-06");
});

test("close: live without the uploaded year writes nothing", async () => {
  const now = dayStart("2026-11-07") + 4 * 3600;
  const { puts, r2 } = bucket();
  await closeDays(stateSince(dayStart("2026-11-01"), now), "", now, r2);
  assert.deepEqual(puts, []);
});

test("close: live continues after the uploaded year, once", async () => {
  const now = dayStart("2026-11-07") + 4 * 3600;
  const seeded = { ...emptyHistory(2026, 1793875200), through: "2026-11-05" };
  const { files, puts, r2 } = bucket({ "history/2026.json.gz": encodeGzip(seeded) });
  const state = stateSince(dayStart("2026-11-01"), now);
  await closeDays(state, "", now, r2);
  assert.deepEqual(puts, ["changes/2026-11-06.json.gz", "history/2026.json.gz"]);
  assert.equal(read(files["history/2026.json.gz"]).through, "2026-11-06");
  // state write lost: the file decides
  state.log.closed[""] = "2026-11-05";
  await closeDays(state, "", now + 120, r2);
  assert.equal(puts.length, 2);
  assert.equal(state.log.closed[""], "2026-11-06");
});

test("late close: open days and their ended wars stay until closed", () => {
  const now = dayStart("2026-11-20");
  const log = emptyState().log;
  log.since = dayStart("2026-10-01");
  log.closed[""] = "2026-10-20";
  for (const day of ["2026-10-15", "2026-10-25", "2026-11-10"]) log.days[day] = [];
  assert.deepEqual(pruneLog(log, "", now), ["2026-10-25"]);
  assert.deepEqual(Object.keys(log.days), ["2026-11-10"]);
  assert.deepEqual(log.dropped, ["2026-10-25"]);
  const war = { result: "fail_assault", ended_at: dayStart("2026-11-10") + 3600 } as War;
  assert.equal(keepForHistory(log, "", war, now), true);
  log.closed[""] = "2026-11-10";
  assert.equal(keepForHistory(log, "", war, now), false);
});

test("close: a day dropped before closing stops the year there", async () => {
  const now = dayStart("2026-11-07") + 4 * 3600;
  const seeded = { ...emptyHistory(2026, 1793875200), through: "2026-11-04" };
  const { puts, r2 } = bucket({ "history/2026.json.gz": encodeGzip(seeded) });
  const state = stateSince(dayStart("2026-11-01"), now);
  state.log.dropped = ["2026-11-05"];
  await closeDays(state, "", now, r2);
  assert.deepEqual(puts, []);
});

test("close: a year file older than what was closed stops it", async () => {
  const now = dayStart("2026-11-07") + 4 * 3600;
  const seeded = { ...emptyHistory(2026, 1793875200), through: "2026-11-03" };
  const { puts, r2 } = bucket({ "history/2026.json.gz": encodeGzip(seeded) });
  const state = stateSince(dayStart("2026-11-01"), now);
  state.log.closed[""] = "2026-11-04";
  await closeDays(state, "", now, r2);
  assert.deepEqual(puts, []);
  assert.equal(state.log.closed[""], "2026-11-04");
});

test("close: a day missing from the diary and older than 7 days waits for close_missing", async () => {
  const now = dayStart("2026-11-20") + 4 * 3600;
  const seeded = { ...emptyHistory(2026, 1793875200), through: "2026-11-04" };
  const { files, puts, r2 } = bucket({ "history/2026.json.gz": encodeGzip(seeded) });
  const state = stateSince(dayStart("2026-11-01"), now);
  delete state.log.days["2026-11-05"];
  state.log.dropped = ["2026-11-06"];
  await closeDays(state, "", now, r2);
  assert.deepEqual(puts, []);
  await closeDays(state, "", now, r2, () => true, true);
  assert.deepEqual(puts, ["changes/2026-11-05.json.gz", "changes/2026-11-06.json.gz", "history/2026.json.gz"]);
  assert.equal(read(files["history/2026.json.gz"]).through, "2026-11-06");
  assert.deepEqual(state.log.dropped, []);
});

test("close and shapes: out of time, nothing is read from R2", async () => {
  const now = dayStart("2026-11-07") + 4 * 3600;
  const { gets, r2 } = bucket();
  const state = stateSince(dayStart("2026-11-04") + 3600, now);
  state.geometry = { version: 1, offset: 4250, seen: [], changed: {}, missing: [], done: true };
  await closeDays(state, "shadow/", now, r2, () => false);
  await publishTerritories(state, "", now, r2, () => false);
  assert.deepEqual(gets, []);
  assert.equal(state.geometry?.done, true);
});

test("close: across the new year, from the first day still open", async () => {
  const now = dayStart("2027-01-03") + 4 * 3600;
  const { files, puts, r2 } = bucket();
  const state = stateSince(dayStart("2026-12-30"), now);
  await closeDays(state, "shadow/", now, r2);
  await closeDays(state, "shadow/", now + 120, r2);
  assert.deepEqual(puts, ["shadow/changes/2026-12-30.json.gz", "shadow/changes/2026-12-31.json.gz",
    "shadow/history/2026.json.gz", "shadow/changes/2027-01-01.json.gz", "shadow/changes/2027-01-02.json.gz",
    "shadow/history/2027.json.gz"]);
  assert.equal(read(files["shadow/history/2027.json.gz"]).complete_from, dayStart("2027-01-01"));
});

test("close: live with no day noted moves past a finished year", async () => {
  const now = dayStart("2027-01-03") + 4 * 3600;
  const seeded = { ...emptyHistory(2026, 1793875200), through: "2026-12-31" };
  const { puts, r2 } = bucket({ "history/2026.json.gz": encodeGzip(seeded) });
  await closeDays(stateSince(dayStart("2026-12-01"), now), "", now, r2);
  assert.deepEqual(puts, ["changes/2027-01-01.json.gz", "changes/2027-01-02.json.gz", "history/2027.json.gz"]);
});
