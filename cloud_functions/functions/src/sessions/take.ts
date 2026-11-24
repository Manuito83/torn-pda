import { CheckerAnswer } from "./checker";
import { BASIC_LEVEL } from "./badges";

// Taken from the manifest
export interface Header {
  magic: string;
  version: number;
}

const STEPS_PER_SECOND = 120;
const HEADER_BYTES = 20;
const MAX_BYTES = 64 * 1024;
const MAX_BASE64 = Math.ceil(MAX_BYTES / 3) * 4;
const MAX_STEPS = 20 * 60 * STEPS_PER_SECOND;
const MAX_CHANGES = 16000;

// Server clock against recorded time
const CLOCK_SLACK_SECONDS = 3;

export interface Take {
  bytes: Uint8Array;
  seed: number;
  steps: number;
  format: number;
}

// Undefined unless a recording header
export function readTake(raw: unknown, header: Header): Take | undefined {
  if (typeof raw !== "string" || raw.length > MAX_BASE64 || raw.length % 4 !== 0) return undefined;
  if (!/^[A-Za-z0-9+/]*={0,2}$/.test(raw)) return undefined;
  const bytes = Buffer.from(raw, "base64");
  if (bytes.length < HEADER_BYTES || bytes.length > MAX_BYTES) return undefined;
  if (bytes.toString("latin1", 0, 3) !== header.magic || bytes[3] !== header.version) return undefined;
  if (bytes.readUInt16LE(4) !== STEPS_PER_SECOND) return undefined;
  const steps = bytes.readUInt32LE(10);
  const changes = bytes.readUInt32LE(14);
  if (steps === 0 || steps > MAX_STEPS || changes > MAX_CHANGES || changes > steps) return undefined;
  return { bytes: new Uint8Array(bytes), seed: bytes.readUInt32LE(6), steps, format: bytes.readUInt16LE(18) };
}

// Reason to refuse before checking
export function takeRejection(take: Take, seed: number, issuedAt: number, now: number): string | undefined {
  if (take.seed !== seed) return "seed";
  if ((now - issuedAt) / 1000 < take.steps / STEPS_PER_SECOND - CLOCK_SLACK_SECONDS) return "clock";
  return undefined;
}

// Reason to refuse the checker's answer
export function answerRejection(answer: CheckerAnswer, take: Take, level: number): string | undefined {
  if (!("checked" in answer)) return "checker";
  const checked = answer.checked;
  if (!checked.ended || !checked.passed) return "failed";
  if (checked.end !== take.steps) return "steps";
  if (checked.format !== take.format) return "format";
  if (checked.extra > 0 && level > BASIC_LEVEL) return "extra";
  return undefined;
}
