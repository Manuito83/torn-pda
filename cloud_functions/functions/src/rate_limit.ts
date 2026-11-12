import * as admin from "firebase-admin";
import { aDayInMilliseconds } from "./time";

const EXPIRE_AFTER_WINDOW_MS = aDayInMilliseconds;

function expireAt(windowStart: number, windowMs: number) {
    return admin.firestore.Timestamp.fromMillis(windowStart + windowMs + EXPIRE_AFTER_WINDOW_MS);
}

// Window start, undefined when full
export async function takeRateLimitSlot(id: string, limit: number, windowMs: number): Promise<number | undefined> {
    const db = admin.firestore();
    const ref = db.collection("rate_limits").doc(id);
    return db.runTransaction(async (transaction) => {
        const now = Date.now();
        const data = (await transaction.get(ref)).data();
        if (data === undefined || now - data.windowStart >= windowMs) {
            transaction.set(ref, { windowStart: now, count: 1, expireAt: expireAt(now, windowMs) });
            return now;
        }
        if (data.count >= limit) {
            return undefined;
        }
        transaction.update(ref, { count: data.count + 1, expireAt: expireAt(data.windowStart, windowMs) });
        return data.windowStart;
    });
}

export async function returnRateLimitSlot(id: string, windowStart: number, windowMs: number): Promise<void> {
    const db = admin.firestore();
    const ref = db.collection("rate_limits").doc(id);
    await db.runTransaction(async (transaction) => {
        const data = (await transaction.get(ref)).data();
        if (data !== undefined && data.windowStart === windowStart && data.count > 0) {
            transaction.update(ref, { count: data.count - 1, expireAt: expireAt(data.windowStart, windowMs) });
        }
    });
}
