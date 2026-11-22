import * as admin from "firebase-admin";
import { aDayInMilliseconds } from "./time";
import { pinRef } from "./feedback_pin_hash";

const SESSION_MS = aDayInMilliseconds / 2;

const sessionRef = (uid: string) => admin.firestore().collection("feedback_mod_sessions").doc(uid);

// Cut by any later PIN change
export async function modSessionUntil(uid: string, playerId: number): Promise<number | undefined> {
  const session = await sessionRef(uid).get();
  const until: number = session.get("until")?.toMillis() ?? 0;
  if (session.get("playerId") !== playerId || until <= Date.now()) return undefined;
  const validAfter = (await pinRef(playerId).get()).get("tokensValidAfter")?.toMillis() ?? 0;
  return (session.get("issuedAt")?.toMillis() ?? 0) > validAfter ? until : undefined;
}

export async function openModSession(uid: string, playerId: number) {
  const issuedAt = Date.now();
  const until = issuedAt + SESSION_MS;
  await sessionRef(uid).set({
    playerId,
    until: admin.firestore.Timestamp.fromMillis(until),
    issuedAt: admin.firestore.Timestamp.fromMillis(issuedAt),
  });
  return until;
}
