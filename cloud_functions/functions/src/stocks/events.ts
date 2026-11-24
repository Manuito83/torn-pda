import { median } from "./median";

export interface StockEvents {
  lastEmpty: number;
  lastRestock: number;
  restockElapsedRaw: number[];
  selloutElapsed: number[];
}

const MAX_INTERVALS = 15;
const MISSED_CYCLE_FACTOR = 1.5;

export function storedStockEvents(doc: Record<string, any>): StockEvents {
  return {
    lastEmpty: doc.lastEmpty || 0,
    lastRestock: doc.lastRestock || 0,
    restockElapsedRaw: doc.restockElapsedRaw || doc.restockElapsed || [],
    selloutElapsed: doc.selloutElapsed || [],
  };
}

// Null when there is no new event
export function nextStockEvents(
  events: StockEvents,
  previousQuantity: number | undefined,
  previousReadAt: number | undefined,
  quantity: number,
  timestamp: number
): StockEvents | null {
  if (previousQuantity === undefined || previousQuantity === null || !previousReadAt) return null;
  const soldOut = quantity === 0 && previousQuantity > 0;
  const restocked = quantity > 0 && previousQuantity === 0;
  if (!soldOut && !restocked) return null;
  if (timestamp <= Math.max(events.lastEmpty, events.lastRestock)) return null;

  const isEmpty = events.lastEmpty > events.lastRestock;
  if (restocked) {
    // Already recorded by the other pass
    if (events.lastRestock > previousReadAt) return null;
    return {
      ...events,
      lastRestock: timestamp,
      restockElapsedRaw: isEmpty
        ? [...events.restockElapsedRaw, timestamp - events.lastEmpty].slice(-MAX_INTERVALS)
        : events.restockElapsedRaw,
    };
  }

  if (events.lastEmpty > previousReadAt) return null;
  return {
    ...events,
    lastEmpty: timestamp,
    selloutElapsed: events.lastRestock && !isEmpty
      ? [...events.selloutElapsed, timestamp - events.lastRestock].slice(-MAX_INTERVALS)
      : events.selloutElapsed,
  };
}

// Drops intervals that span restocks nobody saw
function withoutMissedCycles(intervals: number[]): number[] {
  if (intervals.length < 3) return intervals;
  const limit = median([...intervals].sort((a, b) => a - b)) * MISSED_CYCLE_FACTOR;
  return intervals.filter((interval) => interval <= limit);
}

export function stockEventFields(events: StockEvents) {
  return {
    lastEmpty: events.lastEmpty,
    lastRestock: events.lastRestock,
    restockElapsedRaw: events.restockElapsedRaw,
    restockElapsed: withoutMissedCycles(events.restockElapsedRaw),
    selloutElapsed: events.selloutElapsed,
  };
}
