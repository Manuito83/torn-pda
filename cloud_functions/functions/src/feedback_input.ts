import { HttpsError } from "firebase-functions/v2/https";
import type { Author } from "./feedback_author";

const FORBIDDEN_CHARS = /[\p{Cc}\p{Zl}\p{Zp}\p{Bidi_Control}]/u;
const DOC_ID = /^[A-Za-z0-9_-]{1,64}$/;

export function invalid(what: string): never {
  throw new HttpsError("invalid-argument", `Invalid ${what}`);
}

// Player only goes to the log
export function deny(reason: string, player?: Author): never {
  throw new HttpsError("permission-denied", reason, { reason, player });
}

export function notFound(): never {
  throw new HttpsError("not-found", "Not found");
}

// Trimmed text, undefined if not allowed
export function cleanText(value: unknown, min: number, max: number, multiline: boolean): string | undefined {
  if (typeof value !== "string") return undefined;
  const text = value.replace(/\r\n?/g, "\n").trim();
  if (text.length < min || text.length > max) return undefined;
  return FORBIDDEN_CHARS.test(multiline ? text.replace(/[\n\t]/g, "") : text) ? undefined : text;
}

export function docId(value: unknown, what: string): string {
  return typeof value === "string" && DOC_ID.test(value) ? value : invalid(what);
}
