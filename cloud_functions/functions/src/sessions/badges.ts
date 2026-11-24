// Level that opens the access
export const BASIC_LEVEL = 1;
const MAX_LEVEL = 3;

// Task ids per level, from the manifest
export type Levels = Record<number, string[]>;

// Undefined if malformed
export function levelsFrom(raw: unknown): Levels | undefined {
  if (typeof raw !== "object" || raw === null || Array.isArray(raw)) return undefined;
  const levels: Levels = {};
  for (const [key, tasks] of Object.entries(raw)) {
    const level = Number(key);
    if (!Number.isSafeInteger(level) || level < BASIC_LEVEL || level > MAX_LEVEL || `${level}` !== key) return undefined;
    if (!Array.isArray(tasks) || tasks.length === 0) return undefined;
    if (!tasks.every((task) => typeof task === "string" && /^\w{1,40}$/.test(task))) return undefined;
    levels[level] = tasks;
  }
  return levels[BASIC_LEVEL] === undefined ? undefined : levels;
}

// Lowest level that lists the task
export function levelOfTask(levels: Levels, task: string): number | undefined {
  for (const [level, tasks] of Object.entries(levels)) {
    if (tasks.includes(task)) return Number(level);
  }
  return undefined;
}

// What the checker said
export interface StoredResult {
  score: number;
  end: number;
  extra: number;
  mark: string;
  format: number;
  at: number;
}

// Level in range, else shut
export function levelFrom(raw: unknown): number {
  return typeof raw === "number" && Number.isFinite(raw) ? Math.min(Math.max(Math.trunc(raw), 0), MAX_LEVEL) : 0;
}

// Higher of Remote Config and list
export function effectiveLevel(remote: unknown, listed: unknown): number {
  return Math.max(levelFrom(remote), levelFrom(listed));
}

// Best result per task
export function withResult(
  results: Record<string, StoredResult> | undefined,
  task: string,
  result: StoredResult
): Record<string, StoredResult> {
  const kept = results?.[task];
  if (results !== undefined && kept !== undefined && kept.score >= result.score) return results;
  return { ...results, [task]: result };
}

// Undefined if malformed or reserved
export function tokenFrom(raw: unknown): string | undefined {
  return typeof raw === "string" && /^[\w-]{20,64}$/.test(raw) && !/^__.*__$/.test(raw) ? raw : undefined;
}

export interface StoredToken {
  uid: string;
  playerId: number;
  task: string;
  seed: number;
  issuedAt: number;
  expireAt: { toMillis(): number };
}

// Same session, player and task
export function tokenIsValid(
  saved: StoredToken | undefined,
  uid: string,
  playerId: number,
  task: string,
  now: number
): saved is StoredToken {
  return saved !== undefined && saved.uid === uid && saved.playerId === playerId &&
    saved.task === task && saved.expireAt.toMillis() > now;
}

// Basic level tasks without a result
export function missingTasks(levels: Levels, results: Record<string, StoredResult> | undefined): string[] {
  return levels[BASIC_LEVEL].filter((task) => results?.[task] === undefined);
}
