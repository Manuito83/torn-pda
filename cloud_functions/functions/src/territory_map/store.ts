import * as admin from "firebase-admin";
import { gunzipSync, gzipSync } from "zlib";
import { Control, MapState, SavedState, emptyState } from "./types";

const COLLECTION = "territory_map";
const STATE_VERSION = 1;

export interface Store {
  read(): Promise<{ control: Control | null; saved: SavedState | null }>;
  writeState(state: MapState, now: number, tickMs: number): Promise<void>;
  writeControl(patch: Partial<Control>): Promise<void>;
}

export function controlFrom(data: admin.firestore.DocumentData | undefined): Control | null {
  if (!data) return null;
  return {
    enabled: data.enabled === true,
    publish_prefix: typeof data.publish_prefix === "string" ? data.publish_prefix : "shadow/",
    send_alerts: data.send_alerts === true,
    ownership_every_ticks: Number.isInteger(data.ownership_every_ticks) && data.ownership_every_ticks > 0
      ? data.ownership_every_ticks : 2,
    paused_until: typeof data.paused_until === "number" ? data.paused_until : 0,
    off_reason: typeof data.off_reason === "string" ? data.off_reason : "",
    sample: data.sample === true,
    close_missing: data.close_missing === true,
  };
}

export function firestoreStore(db: admin.firestore.Firestore): Store {
  const control = db.collection(COLLECTION).doc("control");
  const state = db.collection(COLLECTION).doc("state");
  return {
    async read() {
      const [c, s] = await db.getAll(control, state);
      const data = s.data();
      let saved: SavedState | null = null;
      if (data) {
        if (data.v !== STATE_VERSION) throw new Error(`state version ${data.v}`);
        // keys added later start empty
        const state = { ...emptyState(), ...JSON.parse(gunzipSync(data.blob).toString()) };
        saved = { saved_at: data.saved_at, state };
      }
      return { control: controlFrom(c.data()), saved };
    },
    async writeState(map, now, tickMs) {
      const blob = gzipSync(Buffer.from(JSON.stringify(map)));
      await state.set({ v: STATE_VERSION, saved_at: now, tick_ms: tickMs, blob });
    },
    async writeControl(patch) {
      await control.set(patch, { merge: true });
    },
  };
}
