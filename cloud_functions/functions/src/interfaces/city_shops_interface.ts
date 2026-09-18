export interface CityShopsApiResponse {
    cityshops?: CityShopApi[];
    error?: {
        code: number;
        error: string;
    };
}

export interface CityShopApi {
    id: number;
    name?: string;
    items?: {
        id: number;
        name?: string;
        stock?: {
            current?: number | null;
        };
    }[];
}

export interface CityShopsSample {
    // Torn server time (Date header), ms UTC
    time: number;
    stocks: Record<string, number | null>;
    names?: Record<string, { shop: string; item: string }>;
}

export interface CityShopWindow {
    start: number;
    end: number;
}

export interface CityShopState {
    stock: number;
    lastEmpty: number | null;
    lastRestock: number | null;
    baseMin: number | null;
    cycles: number[];
    n: number;
    // Never changed by the engine
    seedBaseMin: number | null;
    seedCycles: number;
    // Learned by the engine once stockPeriods reaches MIN_STOCK_PERIODS
    stockP10Min: number | null;
    stockMedianMin: number | null;
    fastSellFraction: number | null;
    // Minutes in stock of each complete period, capped like cycles
    stockPeriods: number[];
    // Seed version last copied in, null if never seeded
    seedVersion: number | null;
    window: CityShopWindow | null;
    // Window set at the last sellout, kept after the restock
    lastWindow: CityShopWindow | null;
    // Sellout the last restock belongs to
    lastEmptyRestock: number | null;
    neverStocked: boolean;
    lastSeen: number;
    // First sample the item was observed in, null while unseen
    firstSeen: number | null;
    // The sellout was first seen right after a sampling gap
    emptyAfterGap: boolean;
    // The current stock period started or went on across a sampling gap
    stockAfterGap: boolean;
    // Absent from the API sample for over GONE_AFTER_MS
    gone: boolean;
    shop: string;
    item: string;
}

export interface CityShopSeedItem {
    seedBaseMin: number | null;
    seedCycles: number;
    neverStocked: boolean;
    shop: string;
    item: string;
}

export interface CityShopsSeed {
    // Generation time, ms
    version: number;
    items: Record<string, CityShopSeedItem>;
}

export type CityShopMode = "heads_up" | "on_restock" | "no_data";

export type CityShopReason = "reliable" | "low_reliability" | "slow_item" | "learning" | "never_stocked";

export interface CityShopItem {
    shop: string;
    item: string;
    shopId: number;
    itemId: number;
    mode: CityShopMode;
    reason: CityShopReason;
    reliability: number | null;
    baseMin: number | null;
    cycles: number;
    stockP10Min: number | null;
    stockMedianMin: number | null;
    fastSellFraction: number | null;
    window: CityShopWindow | null;
    lastWindow: CityShopWindow | null;
    lastEmpty: number | null;
    lastRestock: number | null;
    lastEmptyRestock: number | null;
    stock: number;
    gone: boolean;
    updated: number;
}

export interface CityShopNotice {
    kind: "heads_up" | "on_restock";
    key: string;
    shop: string;
    item: string;
    window: CityShopWindow | null;
    // Written to cityShopActiveAlerts.<key>
    mark: number;
}

export interface CityShopsTickResult {
    state: Record<string, CityShopState>;
    // Only the items whose state changed beyond lastSeen
    items: Record<string, CityShopItem>;
    // Keys absent for over PURGE_AFTER_MS, already removed from state
    purge: string[];
}
