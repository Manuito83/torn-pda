import { logger } from "firebase-functions/v2";
import { MapState, utcDay } from "./types";

const API_BASE = "https://api.torn.com/v2";
const COMMENT = "PDA-Map";
export const KEY_ERRORS = new Set([1, 2, 10, 13, 16, 18]);
const RETRY_ERRORS = new Set([0, 17]);
export const MAX_CALLS_PER_TICK = 15;
export const MAX_CALLS_PER_DAY = 6000;
const TIMEOUT_MS = 20000;
const RETRY_MS = 2000;
// room left to save the tick
const TAIL_MS = 15000;

export function attemptTimeout(deadlineMs: number, nowMs: number): number {
  return Math.max(1, Math.min(TIMEOUT_MS, deadlineMs + TAIL_MS - nowMs));
}

export class TornError extends Error {
  constructor(readonly code: number, message: string) {
    super(`Torn ${code}: ${message}`);
  }
}

export function pauseFor(code: number): number {
  if (KEY_ERRORS.has(code) || code === 8) return 15 * 60;
  if (code === 5) return 60;
  if (code === 14) return 3600;
  return 0;
}

class Retryable extends Error {}

export class TornClient {
  tickCalls = 0;

  constructor(
    private readonly key: string,
    private readonly param: string,
    private readonly state: MapState,
    private readonly now: number,
    private readonly deadlineMs: number,
    private readonly clockMs: () => number = Date.now,
    private readonly fetcher: typeof fetch = fetch,
  ) {}

  url(path: string, params: Record<string, string | number>): string {
    const query = new URLSearchParams({ ...stringify(params), comment: COMMENT }).toString();
    return `${API_BASE}/${path}?${query}${this.param ? `&${this.param}` : ""}`;
  }

  outOfTime(): boolean {
    return this.clockMs() > this.deadlineMs;
  }

  // Counts every attempt against both limits
  private take(path: string) {
    if (this.state.pause_until > this.now) throw new Error(`paused until ${this.state.pause_until}`);
    if (this.outOfTime()) throw new Error(`out of time before ${path}`);
    const day = utcDay(this.now);
    if (this.state.calls.day !== day) this.state.calls = { day, n: 0 };
    if (this.tickCalls >= MAX_CALLS_PER_TICK || this.state.calls.n >= MAX_CALLS_PER_DAY) {
      if (this.state.calls.n >= MAX_CALLS_PER_DAY) logger.error(`territoryMapTick: daily limit of ${MAX_CALLS_PER_DAY} calls`);
      throw new Error(`call limit before ${path}`);
    }
    this.tickCalls++;
    this.state.calls.n++;
  }

  async get(path: string, params: Record<string, string | number> = {}, csv = false): Promise<any> {
    const url = this.url(path, params);
    for (let attempt = 0; ; attempt++) {
      if (attempt) await new Promise((resolve) => setTimeout(resolve, RETRY_MS));
      this.take(path);
      try {
        return await this.fetchOnce(url, path, csv);
      } catch (error) {
        if (!(error instanceof Retryable) || attempt >= 1) throw error;
      }
    }
  }

  private async fetchOnce(url: string, path: string, csv: boolean): Promise<any> {
    let response: Response;
    try {
      response = await this.fetcher(url, {
        headers: { Authorization: `ApiKey ${this.key}`, "User-Agent": "PDA-Map/1.0" },
        signal: AbortSignal.timeout(attemptTimeout(this.deadlineMs, this.clockMs())),
      });
    } catch (error) {
      throw new Retryable(`network on ${path}: ${error}`);
    }
    if (response.status >= 500 || response.status === 429) throw new Retryable(`HTTP ${response.status} on ${path}`);
    if (!response.ok) throw new Error(`HTTP ${response.status} on ${path}`);
    const text = await response.text();
    if (csv && !text.trimStart().startsWith("{")) return text;
    let data: any;
    try {
      data = JSON.parse(text);
    } catch {
      throw new Retryable(`no JSON on ${path}`);
    }
    const err = data?.error;
    if (!err) return data;
    const code = Number(err.code);
    if (RETRY_ERRORS.has(code)) throw new Retryable(`Torn ${code} on ${path}`);
    const pause = pauseFor(code);
    if (pause) this.state.pause_until = Math.max(this.state.pause_until, this.now + pause);
    throw new TornError(code, String(err.error));
  }
}

function stringify(params: Record<string, string | number>): Record<string, string> {
  return Object.fromEntries(Object.entries(params).map(([k, v]) => [k, String(v)]));
}
