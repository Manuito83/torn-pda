import { test } from "node:test";
import * as assert from "node:assert/strict";
import {
  EndedWar, buildDayChanges, conquestWarId, finishRows, lastClosableDay, racketRows, warRows,
} from "./day_changes";
import { ChangeRow, War, dayStart } from "./types";

const DAY0 = dayStart("2026-11-05");
const AT = DAY0 + 12 * 3600;

const success = (id: number, endedAt: number, territory = "QFA"): EndedWar =>
  ({ id, territory, result: "success_assault", ended_at: endedAt });

test("conquest: a success on the territory 15 min before to 5 after", () => {
  assert.equal(conquestWarId(AT, "QFA", [success(1, AT - 14 * 60)]), 1);
  assert.equal(conquestWarId(AT, "QFA", [success(1, AT + 4 * 60)]), 1);
  assert.equal(conquestWarId(AT, "QFA", [success(1, AT - 16 * 60)]), null);
  assert.equal(conquestWarId(AT, "QFA", [success(1, AT + 6 * 60)]), null);
  assert.equal(conquestWarId(AT, "QFA", [success(1, AT - 60, "ZZG")]), null);
  assert.equal(conquestWarId(AT, "QFA", [{ ...success(1, AT - 60), result: "fail_assault" }]), null);
});

test("conquest: with two, the nearest", () => {
  assert.equal(conquestWarId(AT, "QFA", [success(1, AT - 10 * 60), success(2, AT - 60)]), 2);
});

test("finishRows: conquest only on owner rows, bomb links and extras", () => {
  const rows: ChangeRow[] = [
    [AT, "ownership", "QFA", "owner", 36811, 9032, null, null, null],
    [AT, "ownership", "QFA", "reacquired", 36811, 36811, null, null, null],
    [AT + 60, "ownership", "RFG", "irradiated", 13377, 13377, null, null, null],
    [AT - 30, "bomb", null, "new", 13377, null, null, 89, null],
  ];
  const out = finishRows(rows, {
    wars: [success(46801, AT - 120)],
    bombTerritories: { "89": [["RFG", AT + 60], ["RFH", AT + 60]] },
    respectLost: new Map([[89, 769315]]),
  });
  assert.deepEqual(out.map((r) => [r[2], r[3], r[6], r[7]]), [
    [null, "new", null, 89], ["QFA", "owner", 46801, null], ["QFA", "reacquired", null, null],
    ["RFG", "irradiated", null, 89],
  ]);
  assert.deepEqual(out[0][8], { respect_lost: 769315, territories: ["RFG", "RFH"] });
});

test("rows: assault ends carry score and target, rackets their levels", () => {
  const war = {
    territory: "RCD", target: 300000, aggressor: { id: 14821, score: 63934 }, defender: { id: 26312 },
  } as unknown as War;
  const rows = warRows([{ war_id: 46843, kind: "start", result: "in_progress" },
    { war_id: 46843, kind: "end", result: "fail_assault" }], { "46843": war }, AT);
  assert.deepEqual(rows.map((r) => [r[3], r[8]]), [["start:in_progress", null],
    ["end:fail_assault", { score: 63934, target: 300000 }]]);
  const rackets = racketRows([
    { territory: "IFE", kind: "level", faction_id: 7835, previous_faction_id: 7835, level: 3, previous_level: 2,
      name: "Bootleg Distillery III" },
    { territory: "KFE", kind: "removed", faction_id: 0, previous_faction_id: 7835, level: 0, previous_level: 1,
      name: "Points I" },
  ], AT);
  assert.deepEqual(rackets[0], [AT, "racket", "IFE", "level", 7835, 7835, null, null,
    { level: 3, previous_level: 2, name: "Bootleg Distillery III" }]);
  assert.deepEqual([rackets[1][4], rackets[1][8]], [null, { level: null, previous_level: 1, name: "Points I" }]);
});

test("lastClosableDay: 3 h late, and only after reading bombs and owners", () => {
  const now = DAY0 + 4 * 3600;
  assert.equal(lastClosableDay({ bombs: now, ownership: now }, now), "2026-11-04");
  assert.equal(lastClosableDay({ bombs: DAY0 + 2 * 3600, ownership: now }, now), "2026-11-03");
});

test("day file: revision 2 with the names of the factions in its rows", () => {
  const doc = buildDayChanges("2026-11-05", [[AT, "ownership", "QFA", "owner", 36811, null, null, null, null]],
    (id) => ({ name: `F${id}`, tag: "T" }), AT);
  assert.equal(doc.revision, 2);
  assert.deepEqual(doc.factions, { "36811": { name: "F36811", tag: "T" } });
});
