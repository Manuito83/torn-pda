export interface FactionAttacks {
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