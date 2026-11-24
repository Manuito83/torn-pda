import { test } from "node:test";
import * as assert from "node:assert/strict";
import { createHash } from "crypto";
import { mkdtempSync, writeFileSync } from "fs";
import { tmpdir } from "os";
import * as path from "path";
import { CheckerFiles, answerFrom, cachedChecker, loadChecker, runChecker } from "./checker";

const sha256 = (text: string) => createHash("sha256").update(text).digest("hex");

// Fake checker folder
function fakeChecker(source: string, manifest: Record<string, unknown> = {}): string {
  const dir = mkdtempSync(path.join(tmpdir(), "fake-checker-"));
  const data = "fake data";
  writeFileSync(path.join(dir, "checker.js"), source);
  writeFileSync(path.join(dir, "data.bin"), data);
  writeFileSync(path.join(dir, "manifest.json"), JSON.stringify({
    format: 1, header: { magic: "QXZ", version: 5 }, checker: "checker.js", checkerSha256: sha256(source),
    data: "data.bin", dataSha256: sha256(data), levels: { "1": ["a", "b", "c"] }, ...manifest,
  }));
  return dir;
}

const echo = `globalThis.sessionCheck = (data) => (task, recording, seed) => JSON.stringify({
  passed: true, ended: true, score: 90, steps: recording.length, end: recording.length, extra: 0,
  mark: task + ":" + seed + ":" + data.length, format: 1 });`;

const loaded = (dir: string) => loadChecker(dir) as CheckerFiles;

test("a missing or altered checker does not load", () => {
  assert.equal(typeof loadChecker(path.join(tmpdir(), "no-such-checker")), "string");
  assert.equal(loadChecker(fakeChecker(echo, { checkerSha256: sha256("other") })), "checker does not match the manifest");
  assert.equal(loadChecker(fakeChecker(echo, { dataSha256: sha256("other") })), "data does not match the manifest");
  assert.equal(loadChecker(fakeChecker(echo, { format: "1" })), "manifest without format");
  assert.equal(loadChecker(fakeChecker(echo, { header: { magic: "AB", version: 5 } })), "manifest without header");
  assert.equal(loadChecker(fakeChecker(echo, { header: undefined })), "manifest without header");
  assert.equal(loaded(fakeChecker(echo)).format, 1);
  assert.deepEqual(loaded(fakeChecker(echo)).header, { magic: "QXZ", version: 5 });
});

test("the manifest must list the tasks", () => {
  assert.deepEqual(loaded(fakeChecker(echo)).levels, { 1: ["a", "b", "c"] });
  assert.deepEqual(loaded(fakeChecker(echo, { levels: { "1": ["a"], "2": ["d"] } })).levels, { 1: ["a"], 2: ["d"] });
  const bad: unknown[] = [undefined, [], { "2": ["d"] }, { "1": [] }, { "1": [7] }, { "1": "a" }, { "9": ["a"] }];
  for (const levels of bad) {
    assert.equal(loadChecker(fakeChecker(echo, { levels })), "manifest without levels", JSON.stringify(levels));
  }
});

test("a good load is kept and a failed one retried", () => {
  const files = { checker: "c", data: "d", format: 1, header: { magic: "QXZ", version: 5 }, levels: { 1: ["a"] } };
  const answers: Array<CheckerFiles | string> = ["no", files];
  let calls = 0;
  const load = cachedChecker("dir", () => answers[calls++]);
  assert.equal(load(), "no");
  assert.equal(load(), files);
  assert.equal(load(), files);
  assert.equal(calls, 2);
});

test("the worker checks the recording", async () => {
  const answer = await runChecker(loaded(fakeChecker(echo)), "b", new Uint8Array(30), 4294967295);
  assert.deepEqual(answer, {
    checked: {
      passed: true, ended: true, score: 90, steps: 30, end: 30, extra: 0,
      mark: "b:4294967295:9", format: 1,
    },
  });
});

test("the checker's error comes back", async () => {
  const failing = `globalThis.sessionCheck = () => () => JSON.stringify({ error: "checker error" });`;
  assert.deepEqual(await runChecker(loaded(fakeChecker(failing)), "b", new Uint8Array(30), 1),
    { error: "checker error" });
});

test("a checker past its time is killed", async () => {
  const slow = `globalThis.sessionCheck = () => () => { for (;;) {} };`;
  const started = Date.now();
  assert.deepEqual(await runChecker(loaded(fakeChecker(slow)), "b", new Uint8Array(30), 1, 300), { error: "timeout" });
  assert.ok(Date.now() - started < 3000);
});

test("a checker past its memory is killed", async () => {
  const greedy = `globalThis.sessionCheck = () => () => { const a = []; for (;;) a.push(new Array(1e5).fill(1.5)); };`;
  const answer = await runChecker(loaded(fakeChecker(greedy)), "b", new Uint8Array(30), 1, 10_000);
  assert.ok("error" in answer && answer.error !== "timeout", JSON.stringify(answer));
});

test("a worker that never starts is unavailable", async () => {
  const answer = await runChecker(loaded(fakeChecker(echo)), "b", new Uint8Array(30), 1, 5_000, "/no/such/worker.js");
  assert.ok("unavailable" in answer, JSON.stringify(answer));
});

test("a checker that throws is an error", async () => {
  const broken = `globalThis.sessionCheck = () => () => { throw new Error("boom"); };`;
  const answer = await runChecker(loaded(fakeChecker(broken)), "b", new Uint8Array(30), 1);
  assert.ok("error" in answer, JSON.stringify(answer));
});

test("a malformed answer is not a result", () => {
  assert.deepEqual(answerFrom("nope"), { error: "unreadable answer" });
  assert.deepEqual(answerFrom(JSON.stringify({ passed: "yes", ended: true })), { error: "malformed answer" });
  assert.deepEqual(answerFrom(JSON.stringify({
    passed: true, ended: true, score: -1, steps: 1, end: 1, extra: 0, mark: "x", format: 1,
  })), { error: "malformed answer" });
});
