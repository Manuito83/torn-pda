import { createHash } from "crypto";
import { readFileSync } from "fs";
import * as path from "path";
import { Worker } from "worker_threads";
import { Levels, levelsFrom } from "./badges";
import { Header } from "./take";

// Built locally, never in git
export const CHECKER_DIR = path.join(__dirname, "..", "..", "checker");
const CHECK_TIMEOUT_MS = 15_000;
const WORKER = path.join(__dirname, "checker_worker.js");
const HEAP_MB = 256;

export interface CheckerFiles {
  checker: string;
  data: string;
  format: number;
  header: Header;
  levels: Levels;
}

export interface Checked {
  passed: boolean;
  ended: boolean;
  score: number;
  steps: number;
  end: number | null;
  extra: number;
  mark: string;
  format: number;
}

// unavailable: the worker never started
export type CheckerAnswer = { checked: Checked } | { error: string } | { unavailable: string };

const sha256 = (file: string) => createHash("sha256").update(readFileSync(file)).digest("hex");

// Error text if missing or altered
export function loadChecker(dir: string): CheckerFiles | string {
  try {
    const manifest = JSON.parse(readFileSync(path.join(dir, "manifest.json"), "utf8"));
    const checker = path.join(dir, path.basename(String(manifest.checker)));
    const data = path.join(dir, path.basename(String(manifest.data)));
    if (!Number.isSafeInteger(manifest.format)) return "manifest without format";
    const { magic, version } = manifest.header ?? {};
    if (typeof magic !== "string" || magic.length !== 3 || !Number.isSafeInteger(version)) {
      return "manifest without header";
    }
    const levels = levelsFrom(manifest.levels);
    if (levels === undefined) return "manifest without levels";
    if (sha256(checker) !== manifest.checkerSha256) return "checker does not match the manifest";
    if (sha256(data) !== manifest.dataSha256) return "data does not match the manifest";
    return { checker, data, format: manifest.format, header: { magic, version }, levels };
  } catch (e) {
    return `${e}`;
  }
}

// Cached once loaded
export function cachedChecker(dir: string, load = loadChecker): () => CheckerFiles | string {
  let kept: CheckerFiles | undefined;
  return () => {
    if (kept !== undefined) return kept;
    const loaded = load(dir);
    if (typeof loaded !== "string") kept = loaded;
    return loaded;
  };
}

const isWhole = (value: unknown) => Number.isSafeInteger(value) && (value as number) >= 0;

// Only a well formed answer counts
export function answerFrom(text: unknown): CheckerAnswer {
  let raw: any;
  try {
    raw = JSON.parse(String(text));
  } catch {
    return { error: "unreadable answer" };
  }
  if (typeof raw?.error === "string") return { error: raw.error };
  const { passed, ended, score, steps, end, extra, mark, format } = raw ?? {};
  if (typeof passed !== "boolean" || typeof ended !== "boolean" || typeof mark !== "string") {
    return { error: "malformed answer" };
  }
  if (!isWhole(score) || !isWhole(steps) || !isWhole(extra) || !isWhole(format)) {
    return { error: "malformed answer" };
  }
  if (end !== null && !isWhole(end)) return { error: "malformed answer" };
  return { checked: { passed, ended, score, steps, end, extra, mark, format } };
}

// One take per worker, killed late
export function runChecker(
  files: CheckerFiles,
  task: string,
  recording: Uint8Array,
  seed: number,
  timeoutMs = CHECK_TIMEOUT_MS,
  workerFile = WORKER
): Promise<CheckerAnswer> {
  return new Promise((resolve) => {
    let worker: Worker;
    try {
      worker = new Worker(workerFile, {
        workerData: { checker: files.checker, data: files.data, task, recording, seed },
        resourceLimits: { maxOldGenerationSizeMb: HEAP_MB },
        env: {},
      });
    } catch (e) {
      resolve({ unavailable: `worker not created: ${e}` });
      return;
    }
    let done = false;
    let started = false;
    const finish = (answer: CheckerAnswer) => {
      if (done) return;
      done = true;
      clearTimeout(timer);
      worker.terminate();
      resolve(answer);
    };
    const failed = (text: string) => finish(started ? { error: text } : { unavailable: text });
    const timer = setTimeout(() => finish({ error: "timeout" }), timeoutMs);
    worker.on("message", (text) => {
      if (typeof text === "object" && text?.started === true) started = true;
      else finish(answerFrom(text));
    });
    worker.once("error", (e) => failed(`worker: ${e}`));
    worker.once("exit", (code) => failed(`worker exit ${code}`));
  });
}
