import { OwnershipChange, RacketChange, WarEvent } from "./compare";
import { scheduledEnd } from "./exports";
import { AlertMessage, TOPIC_REGEX } from "./fcm";
import { MapState, War } from "./types";

const ENDING_WITHIN = 3600;
const CONQUEST_WINDOW = 30 * 60;
const POINTS_PER_SLOT = 50000;

export interface TickFacts {
  warsRead: boolean;
  warEvents: WarEvent[];
  ownership: OwnershipChange[];
  rackets: RacketChange[];
}

type TopicKind = "war" | "ending" | "owner" | "racket";

function topics(kind: TopicKind, code: string, factions: number[]): string[] {
  const all = [...factions.filter((id) => id > 0).map((id) => `tmap.f.${id}.${kind}`), `tmap.t.${code}.${kind}`];
  return [...new Set(all)].filter((t) => TOPIC_REGEX.test(t));
}

function label(state: MapState, id: number, warName?: string | null): string {
  if (id === 0) return "nobody";
  const f = state.factions[String(id)];
  const name = f?.name ?? warName ?? `Faction ${id}`;
  return f?.tag ? `[${f.tag}] ${name}` : name;
}

function sideLabel(state: MapState, war: War, key: "aggressor" | "defender"): string {
  return label(state, war[key].id, war[key].name);
}

function points(n: number): string {
  return n.toLocaleString("en-US");
}

export function duration(seconds: number): string {
  const minutes = Math.max(0, Math.round(seconds / 60));
  const d = Math.floor(minutes / 1440);
  const h = Math.floor((minutes % 1440) / 60);
  const m = minutes % 60;
  if (d) return `${d} d ${h} h`;
  if (h) return `${h} h ${m} min`;
  return `${m} min`;
}

// Wall slots shared by both sides
export function pace(war: War): number {
  const slots = war.target ? Math.floor(war.target / POINTS_PER_SLOT) : Infinity;
  const attackers = Math.min(war.aggressor.wall, slots);
  const defenders = Math.min(war.defender.wall, slots - attackers);
  return (attackers - defenders) * 60;
}

export function endingDue(war: War, now: number): "score" | "deadline" | null {
  if (war.result !== "in_progress" || war.ending_sent || !war.target) return null;
  const remaining = war.target - war.aggressor.score;
  const end = scheduledEnd(war);
  if (remaining <= 0 || end <= now) return null;
  const p = pace(war);
  if (p > 0) {
    const projected = war.updated_at + (remaining / p) * 60;
    if (projected <= end && projected - now < ENDING_WITHIN) return "score";
  }
  if (end - now < ENDING_WITHIN && war.aggressor.score > war.target / 2) return "deadline";
  return null;
}

function warMessage(war: War, id: number, key: string, kind: TopicKind, dataKind: string, title: string,
  body: string): AlertMessage {
  return {
    key, kind: dataKind, title, body, territory: war.territory, factionId: String(war.defender.id), warId: String(id),
    topics: topics(kind, war.territory, [war.aggressor.id, war.defender.id]),
  };
}

function warEventMessage(state: MapState, e: WarEvent): AlertMessage | null {
  const war = state.wars[String(e.war_id)];
  if (!war) return null;
  const code = war.territory;
  if (e.kind === "start") {
    const held = war.defender.id ? `, held by ${sideLabel(state, war, "defender")}` : "";
    return warMessage(war, e.war_id, `war:${e.war_id}:start`, "war", "assault_started", `Assault on ${code}`,
      `${sideLabel(state, war, "aggressor")} is attacking ${code}${held}`);
  }
  if (e.kind !== "end") return null;
  const titles: Record<string, string> = {
    success_assault: `${code} conquered by ${sideLabel(state, war, "aggressor")}`,
    fail_assault: `${code} defended`,
    end_with_peace_treaty: `Peace treaty on ${code}`,
  };
  const target = war.target ?? 0;
  const lasted = war.ended_at !== null ? ` after ${duration(war.ended_at - war.start)}` : "";
  return warMessage(war, e.war_id, `war:${e.war_id}:end`, "war", "assault_ended",
    titles[e.result] ?? `Assault on ${code} ended`,
    `Final score ${points(war.aggressor.score)} / ${points(target)}${lasted}`);
}

function endingMessage(war: War, id: number, due: "score" | "deadline"): AlertMessage {
  const progress = `${points(war.aggressor.score)} / ${points(war.target ?? 0)}`;
  const body = due === "score"
    ? `Attackers at ${progress} (+${pace(war)}/min)`
    : `72 h deadline in about 1 h, attackers at ${progress}`;
  return warMessage(war, id, `war:${id}:ending`, "ending", "assault_ending",
    `${war.territory}: assault ends in about 1 h`, body);
}

// Recent success on that code
function conquestWar(state: MapState, code: string, faction: number, now: number): string | null {
  for (const [id, w] of Object.entries(state.wars)) {
    if (w.territory === code && w.result === "success_assault" && w.aggressor.id === faction &&
      w.ended_at !== null && now - w.ended_at <= CONQUEST_WINDOW) return id;
  }
  return null;
}

function ownerMessage(state: MapState, c: OwnershipChange, now: number): AlertMessage | null {
  if (c.kind !== "owner") return null;
  const code = c.territory;
  const before = c.previous_faction_id ?? 0;
  const after = c.faction_id;
  const warId = after ? conquestWar(state, code, after, now) : null;
  let title = `${code} changed hands`;
  if (warId) title = `${code} conquered`;
  else if (!after) title = `${code} abandoned by ${label(state, before)}`;
  else if (!before) title = `${code} claimed by ${label(state, after)}`;
  return {
    key: `owner:${code}:${now}`, kind: "owner_changed", title,
    body: `${label(state, before)} → ${label(state, after)}`, territory: code,
    factionId: String(after || before), warId: warId ?? "", topics: topics("owner", code, [before, after]),
  };
}

function racketMessage(state: MapState, c: RacketChange, now: number): AlertMessage | null {
  const code = c.territory;
  const base = { key: `racket:${code}:${c.kind}:${now}`, territory: code, warId: "" };
  if (c.kind === "new" || c.kind === "level") {
    const reward = state.rackets[code]?.description;
    const title = c.kind === "new" ? `New racket in ${code}` : `${code} racket is now level ${c.level}`;
    return {
      ...base, kind: `racket_${c.kind}`, title, body: reward ? `${c.name}: ${reward}` : c.name,
      factionId: String(c.faction_id), topics: topics("racket", code, [c.faction_id]),
    };
  }
  if (c.kind !== "removed") return null;
  const owner = c.previous_faction_id ?? 0;
  return {
    ...base, kind: "racket_removed", title: `${code} lost its racket`, body: `${c.name} is gone`,
    factionId: String(owner), topics: topics("racket", code, [owner]),
  };
}

// Messages and wars with ending sent
export function buildAlerts(state: MapState, facts: TickFacts, now: number) {
  const messages: AlertMessage[] = [];
  const add = (m: AlertMessage | null) => {
    if (m && m.title && m.body && m.topics.length) messages.push(m);
  };
  facts.warEvents.forEach((e) => add(warEventMessage(state, e)));
  const endings: string[] = [];
  for (const [id, war] of Object.entries(facts.warsRead ? state.wars : {})) {
    const due = endingDue(war, now);
    if (!due) continue;
    endings.push(id);
    add(endingMessage(war, Number(id), due));
  }
  facts.ownership.forEach((c) => add(ownerMessage(state, c, now)));
  facts.rackets.forEach((c) => add(racketMessage(state, c, now)));
  return { messages, endings };
}
