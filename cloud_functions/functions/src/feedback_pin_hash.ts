import * as admin from "firebase-admin";
import { createHmac, randomBytes, scrypt } from "crypto";
import { promisify } from "util";

export const pinRef = (playerId: number) => admin.firestore().collection("feedback_pins").doc(`${playerId}`);

// Rotate by appending a new secret name
export const PIN_SECRET_NAMES = ["FEEDBACK_PIN_SECRET"];
export const PIN_VERSION = PIN_SECRET_NAMES.length;
// Hashes saved without v
export const FIRST_PIN_VERSION = 1;
const scryptAsync = promisify(scrypt) as (pin: Buffer, salt: Buffer, length: number) => Promise<Buffer>;

export function keyedWith(key: string, text: string) {
  if (key.length < 32) throw new Error("Secret missing");
  return createHmac("sha256", key).update(text).digest();
}

// Leaked hashes are useless without the secret
export const hashPinWith = (key: string, pin: string, salt: Buffer, length: number) =>
  scryptAsync(keyedWith(key, pin), salt, length);

// Key of the current secret version
export async function pinRecord(key: string, pin: string) {
  const salt = randomBytes(16);
  return {
    hash: (await hashPinWith(key, pin, salt, 32)).toString("base64"),
    salt: salt.toString("base64"),
    v: PIN_VERSION,
    failures: 0,
    lockedUntil: null as null,
  };
}
