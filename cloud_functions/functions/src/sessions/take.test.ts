import { test } from "node:test";
import * as assert from "node:assert/strict";
import { Take, readTake, takeRejection, answerRejection } from "./take";
import { Checked } from "./checker";

const header = { magic: "QXZ", version: 5 };

// Header plus filler bytes, as base64
function recording({ seed = 7, steps = 1200, changes = 0, format = 1, filler = 0, version = header.version } = {}): string {
  const bytes = Buffer.alloc(20 + filler);
  bytes.write(header.magic, 0, "latin1");
  bytes[3] = version;
  bytes.writeUInt16LE(120, 4);
  bytes.writeUInt32LE(seed, 6);
  bytes.writeUInt32LE(steps, 10);
  bytes.writeUInt32LE(changes, 14);
  bytes.writeUInt16LE(format, 18);
  return bytes.toString("base64");
}

const read = (raw: unknown) => readTake(raw, header);
const take: Take = { bytes: new Uint8Array(20), seed: 7, steps: 1200, format: 1 };
const checked: Checked = {
  passed: true, ended: true, score: 80, steps: 1200, end: 1200, extra: 0, mark: "0011223344556677", format: 1,
};

test("header gives seed, steps and format", () => {
  const got = read(recording({ seed: 4294967295, steps: 9000, changes: 40, format: 2, filler: 100 }));
  assert.deepEqual(
    got && { seed: got.seed, steps: got.steps, format: got.format, length: got.bytes.length },
    { seed: 4294967295, steps: 9000, format: 2, length: 120 }
  );
});

test("malformed recordings are refused", () => {
  assert.equal(read(recording({ steps: 4_000_000_000 })), undefined);
  assert.equal(read(recording({ steps: 0 })), undefined);
  assert.equal(read(recording({ steps: 10, changes: 11 })), undefined);
  assert.equal(read(recording({ version: 4 })), undefined);
  assert.equal(readTake(recording(), { magic: "ABC", version: 5 }), undefined);
  assert.equal(read(Buffer.alloc(19).toString("base64")), undefined);
  assert.equal(read(Buffer.alloc(64 * 1024, 7).toString("base64")), undefined);
  assert.equal(read(recording({ filler: 64 * 1024 })), undefined);
  assert.equal(read("not base64!"), undefined);
  assert.equal(read(12345), undefined);
});

test("another seed is refused", () => {
  assert.equal(takeRejection(take, 8, 0, 60_000), "seed");
  assert.equal(takeRejection(take, 7, 0, 60_000), undefined);
});

test("a take longer than the clock is refused", () => {
  // 1200 steps are 10 s recorded
  assert.equal(takeRejection(take, 7, 0, 6_000), "clock");
  assert.equal(takeRejection(take, 7, 0, 7_000), undefined);
});

test("only a passed answer at the end counts", () => {
  assert.equal(answerRejection({ checked }, take, 1), undefined);
  assert.equal(answerRejection({ checked: { ...checked, passed: false } }, take, 1), "failed");
  assert.equal(answerRejection({ checked: { ...checked, ended: false, end: null } }, take, 1), "failed");
  assert.equal(answerRejection({ checked: { ...checked, end: 900 } }, take, 1), "steps");
  assert.equal(answerRejection({ checked: { ...checked, format: 2 } }, take, 1), "format");
  assert.equal(answerRejection({ unavailable: "worker exit 1" }, take, 1), "checker");
  assert.equal(answerRejection({ error: "checker error" }, take, 1), "checker");
  assert.equal(answerRejection({ error: "timeout" }, take, 1), "checker");
});

test("extra above the basic level is refused", () => {
  const withExtra = { checked: { ...checked, extra: 300 } };
  assert.equal(answerRejection(withExtra, take, 1), undefined);
  assert.equal(answerRejection(withExtra, take, 2), "extra");
});
