import { test } from "node:test";
import * as assert from "node:assert/strict";
import { readFileSync } from "fs";
import { join } from "path";
import * as admin from "firebase-admin";
import { Store } from "./store";
import { TickDeps, runTick } from "./tick";
import { TornClient } from "./torn";
import { Control, SavedState } from "./types";

const FIXTURES = join(__dirname, "../../src/territory_map/fixtures");
const fixture = (name: string) => JSON.parse(readFileSync(join(FIXTURES, name), "utf8"));
// 00:05 UTC, before the daily reads
const NOW = 1793836800 + 300;
const WARS = fixture("warfareterritory.json").warfareterritory;

const shadow: Control = {
  enabled: true, publish_prefix: "shadow/", send_alerts: false, ownership_every_ticks: 2, paused_until: 0,
  off_reason: "", sample: false, close_missing: false,
};

function fakeTorn(wars: unknown[]): typeof fetch {
  const bodies: Record<string, unknown> = {
    "faction/warfareterritory": { warfareterritory: wars },
    "faction/territoryownership": fixture("territoryownership.json"),
    "faction/rackets": fixture("rackets.json"),
    "faction/dirtybombs": fixture("dirtybombs.json"),
  };
  return (async (url: string) => {
    const path = new URL(url).pathname.replace("/v2/", "");
    return new Response(JSON.stringify(bodies[path] ?? { error: { code: 9, error: "API disabled" } }));
  }) as unknown as typeof fetch;
}

function setup() {
  let saved: string | null = null;
  const t = {
    puts: [] as string[], sends: [] as admin.messaging.Message[][], failWrite: false, failKey: "",
    // R2 latency, moves the clock
    putMs: 0, ms: 0,
  };
  const store = (control: Control): Store => ({
    async read() {
      return { control, saved: saved ? JSON.parse(saved) as SavedState : null };
    },
    async writeState(state, now) {
      if (t.failWrite) throw new Error("write failed");
      saved = JSON.stringify({ saved_at: now, state });
    },
    async writeControl() {},
  });
  const clock = (now: number) => () => now * 1000 + t.ms;
  const tick = (now: number, wars: unknown[], control: Control = shadow) => (t.ms = 0, runTick({
    store: store(control),
    makeTorn: (state, at, deadlineMs) => new TornClient("key", "", state, at, deadlineMs, clock(now),
      fakeTorn(wars)),
    r2: {
      put: async (key: string) => {
        t.ms += t.putMs;
        if (key === t.failKey) throw new Error("R2 down");
        t.puts.push(key);
      },
      get: async () => null,
      headPublic: async () => 404,
    },
    send: async (messages) => {
      t.sends.push(messages);
      return { successCount: messages.length, failureCount: 0, responses: [] };
    },
    clockMs: clock(now),
  } as TickDeps));
  return { t, tick, saved: () => saved };
}

test("tick: the first saves without publishing, the second publishes under shadow/", async () => {
  const s = setup();
  await s.tick(NOW, WARS);
  assert.ok(s.saved());
  assert.deepEqual(s.t.puts, []);
  await s.tick(NOW + 120, WARS);
  assert.deepEqual(s.t.puts, ["shadow/state.json.gz", "shadow/heartbeat.json", "shadow/changes/2026-11-04.json.gz",
    "shadow/changes/2026-11-05.json.gz", "shadow/wars/46843.json.gz", "shadow/wars/46842.json.gz",
    "shadow/wars/46841.json.gz", "shadow/wars/46840.json.gz"]);
  assert.deepEqual(s.t.sends, []);
});

test("tick: a failed war file upload is written again on the next tick", async () => {
  const s = setup();
  await s.tick(NOW, WARS);
  s.t.failKey = "shadow/wars/46843.json.gz";
  await s.tick(NOW + 120, WARS);
  s.t.failKey = "";
  s.t.puts.length = 0;
  await s.tick(NOW + 240, WARS);
  assert.ok(s.t.puts.includes("shadow/wars/46843.json.gz"));
  assert.ok(!s.t.puts.includes("shadow/wars/46842.json.gz"));
});

test("tick: with a slow R2, uploads stop at 45 s and go up next tick", async () => {
  const s = setup();
  await s.tick(NOW, WARS);
  s.t.putMs = 20000;
  await s.tick(NOW + 120, WARS);
  assert.deepEqual(s.t.puts, ["shadow/state.json.gz", "shadow/heartbeat.json", "shadow/changes/2026-11-04.json.gz"]);
  s.t.putMs = 0;
  s.t.puts.length = 0;
  await s.tick(NOW + 240, WARS);
  assert.ok(["shadow/changes/2026-11-05.json.gz", "shadow/wars/46843.json.gz", "shadow/wars/46840.json.gz"]
    .every((key) => s.t.puts.includes(key)));
});

test("tick: a new assault is sent once alerts are on", async () => {
  const s = setup();
  await s.tick(NOW, WARS);
  const fresh = { ...WARS[0], id: 50000, territory: "XYZ" };
  await s.tick(NOW + 120, [fresh, ...WARS], { ...shadow, send_alerts: true });
  assert.equal(s.t.sends.length, 1);
  assert.deepEqual(s.t.sends[0].map((m) => (m as { topic: string }).topic),
    ["tmap.f.51387.war", "tmap.f.8315.war", "tmap.t.XYZ.war"]);
});

test("tick: a failed state write publishes and sends nothing", async () => {
  const s = setup();
  await s.tick(NOW, WARS);
  s.t.failWrite = true;
  const fresh = { ...WARS[0], id: 50000, territory: "XYZ" };
  await s.tick(NOW + 120, [fresh, ...WARS], { ...shadow, send_alerts: true });
  assert.deepEqual(s.t.puts, []);
  assert.deepEqual(s.t.sends, []);
});
