export interface FactionModel {
    ID: number;
    name: string;
    tag: string;
    tag_image: string;
    leader: number;
    "co-leader": number;
    respect: number;
    age: number;
    capacity: number;
    best_chain: number;
    ranked_wars: Peace;
    territory_wars: Peace;
    raid_wars: Peace;
    peace: Peace;
    rank: Rank;
    members: { [key: string]: Member };
    attacks: { [key: string]: Attack };
}

export interface Attack {
    code: string;
    timestamp_started: number;
    timestamp_ended: number;
    attacker_id: number | string;
    attacker_name: string;
    attacker_faction: number | string;
    attacker_factionname: string;
    defender_id: number;
    defender_name: string;
    defender_faction: number;
    defender_factionname: string;
    result: Result;
    stealthed: number;
    respect: number;
    chain: number;
    raid: number;
    ranked_war: number;
    respect_gain: number;
    respect_loss: number;
    modifiers: Modifiers;
}

export interface Modifiers {
    fair_fight: number;
    war: number;
    retaliation: number;
    group_attack: number;
    overseas: number;
    chain_bonus: number;
}

export enum Result {
    Arrested = "Arrested",
    Assist = "Assist",
    Attacked = "Attacked",
    Escape = "Escape",
    Hospitalized = "Hospitalized",
    Lost = "Lost",
    Mugged = "Mugged",
    Special = "Special",
    Stalemate = "Stalemate",
}

export interface Member {
    name: string;
    level: number;
    days_in_faction: number;
    last_action: LastAction;
    status: StatusClass;
    position: string;
}

export interface LastAction {
    status: StatusEnum;
    timestamp: number;
    relative: string;
}

export enum StatusEnum {
    Idle = "Idle",
    Offline = "Offline",
    Online = "Online",
}

export interface StatusClass {
    description: string;
    details: string;
    state: State;
    color: Color;
    until: number;
}

export enum Color {
    Blue = "blue",
    Green = "green",
    Red = "red",
}

export enum State {
    Abroad = "Abroad",
    Hospital = "Hospital",
    Okay = "Okay",
    Traveling = "Traveling",
}

// tslint:disable-next-line
export interface Peace {
}

export interface Rank {
    level: number;
    name: string;
    division: number;
    position: number;
    wins: number;
}
