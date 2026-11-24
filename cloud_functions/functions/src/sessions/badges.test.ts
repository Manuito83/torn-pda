import { test } from "node:test";
import * as assert from "node:assert/strict";
import {
  StoredResult, effectiveLevel, levelFrom, levelOfTask, missingTasks, tokenFrom, tokenIsValid, withResult,
} from "./badges";

const result = (score: number, at: number): StoredResult =>
  ({ score, end: 9000, extra: 0, mark: "00ff00ff00ff00ff", format: 1, at });

const levels = { 1: ["a", "b", "c"], 2: ["d"] };

test("level stays in range or shuts", () => {
  assert.equal(levelFrom(2), 2);
  assert.equal(levelFrom(2.9), 2);
  assert.equal(levelFrom(9), 3);
  assert.equal(levelFrom(-1), 0);
  assert.equal(levelFrom("2"), 0);
  assert.equal(levelFrom(NaN), 0);
  assert.equal(levelFrom(undefined), 0);
});

test("the higher level wins", () => {
  assert.equal(effectiveLevel(0, undefined), 0);
  assert.equal(effectiveLevel(0, 1), 1);
  assert.equal(effectiveLevel(2, 1), 2);
  assert.equal(effectiveLevel(NaN, 1), 1);
});

test("a task belongs to the level that lists it", () => {
  assert.equal(levelOfTask(levels, "a"), 1);
  assert.equal(levelOfTask(levels, "d"), 2);
  assert.equal(levelOfTask(levels, "z"), undefined);
});

test("only a better score replaces the result", () => {
  const first = withResult(undefined, "a", result(80, 1000));
  assert.equal(withResult(first, "a", result(70, 2000)), first);
  assert.equal(withResult(first, "a", result(80, 2000)), first);
  assert.equal(withResult(first, "a", result(90, 2000)).a.at, 2000);
  assert.deepEqual(Object.keys(withResult(first, "b", result(50, 2000))), ["a", "b"]);
});

test("a token is a plain id of the right length", () => {
  assert.equal(tokenFrom("abcdefghij0123456789_-xy"), "abcdefghij0123456789_-xy");
  assert.equal(tokenFrom("short"), undefined);
  assert.equal(tokenFrom("a/bcdefghij0123456789xyz"), undefined);
  assert.equal(tokenFrom("__abcdefghij0123456789__"), undefined);
  assert.equal(tokenFrom(12345), undefined);
});

test("a token works for its own task", () => {
  const saved = {
    uid: "u1", playerId: 111, task: "a", seed: 7, issuedAt: 0, expireAt: { toMillis: () => 5000 },
  };
  assert.equal(tokenIsValid(saved, "u1", 111, "a", 4000), true);
  assert.equal(tokenIsValid(saved, "u2", 111, "a", 4000), false);
  assert.equal(tokenIsValid(saved, "u1", 222, "a", 4000), false);
  assert.equal(tokenIsValid(saved, "u1", 111, "b", 4000), false);
  assert.equal(tokenIsValid(saved, "u1", 111, "a", 5000), false);
  assert.equal(tokenIsValid(undefined, "u1", 111, "a", 4000), false);
});

test("missing tasks are listed", () => {
  assert.deepEqual(missingTasks(levels, undefined), ["a", "b", "c"]);
  const two = withResult(withResult(undefined, "a", result(80, 1)), "b", result(60, 2));
  assert.deepEqual(missingTasks(levels, two), ["c"]);
});
