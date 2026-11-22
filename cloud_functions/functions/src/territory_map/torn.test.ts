import { test } from "node:test";
import * as assert from "node:assert/strict";
import { TornClient, attemptTimeout } from "./torn";
import { emptyState } from "./types";

test("outOfTime: true only after the deadline", () => {
  let clock = 1000;
  const torn = new TornClient("k", "", emptyState(), 0, 2000, () => clock);
  assert.equal(torn.outOfTime(), false);
  clock = 2001;
  assert.equal(torn.outOfTime(), true);
});

test("attemptTimeout: full timeout while there is room", () => {
  assert.equal(attemptTimeout(40000, 0), 20000);
});

test("attemptTimeout: a call at the budget edge ends before the tail", () => {
  assert.equal(attemptTimeout(40000, 39900), 15100);
});

test("attemptTimeout: never zero", () => {
  assert.equal(attemptTimeout(40000, 90000), 1);
});
