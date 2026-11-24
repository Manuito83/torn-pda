import { test } from "node:test";
import * as assert from "node:assert/strict";
import { nextStockEvents, stockEventFields, storedStockEvents, StockEvents } from "./events";

// jap-Xanax on 2026-11-26
const JAP_XANAX_RESTOCKS = [
  7184, 13825, 7809, 15009, 6646, 7271, 7833, 6021, 43807, 7192, 14397, 7799, 13810, 152406, 159599,
];
const T0359 = 1795665540;
const T0409 = 1795666140;

function stocked(lastRestock: number): StockEvents {
  return { lastEmpty: lastRestock - 7200, lastRestock, restockElapsedRaw: [7200], selloutElapsed: [600] };
}

test("a sellout from 1016 to 0 is recorded", () => {
  const events = nextStockEvents(stocked(T0359 - 600), 1016, T0359, 0, T0409);
  assert.equal(events?.lastEmpty, T0409);
  assert.deepEqual(events?.selloutElapsed, [600, 1200]);
});

test("a restock without a seen empty adds no interval but still times the sellout", () => {
  const restocked = nextStockEvents(stocked(T0359 - 7800), 0, T0359 - 600, 1016, T0359)!;
  assert.equal(restocked.lastRestock, T0359);
  assert.deepEqual(restocked.restockElapsedRaw, [7200]);
  assert.deepEqual(nextStockEvents(restocked, 1016, T0359, 0, T0409)?.selloutElapsed, [600, 600]);
});

test("a restock seen by the 3 min pass is not counted again at 10 min", () => {
  const empty = { ...stocked(T0359 - 7800), lastEmpty: T0359 - 7200 };
  const threeMin = nextStockEvents(empty, 0, T0359 - 180, 1016, T0359)!;
  assert.deepEqual(threeMin.restockElapsedRaw, [7200, 7200]);
  assert.equal(nextStockEvents(threeMin, 0, T0359 - 300, 400, T0409), null);
  assert.equal(nextStockEvents(threeMin, 0, T0359 - 300, 1016, T0359), null);
});

test("a sellout seen by the 3 min pass is not counted again at 10 min", () => {
  const threeMin = nextStockEvents(stocked(T0359 - 600), 1016, T0359 - 180, 0, T0359)!;
  assert.deepEqual(threeMin.selloutElapsed, [600, 600]);
  assert.equal(nextStockEvents(threeMin, 1016, T0359 - 300, 0, T0409), null);
});

test("intervals with missed restocks are kept out of restockElapsed", () => {
  const fields = stockEventFields(storedStockEvents({ restockElapsed: JAP_XANAX_RESTOCKS }));
  assert.deepEqual(fields.restockElapsed, [7184, 7809, 6646, 7271, 7833, 6021, 7192, 7799]);
  assert.deepEqual(fields.restockElapsedRaw, JAP_XANAX_RESTOCKS);
});

test("a longer cycle shows up once it fills most of the list", () => {
  const raw = [...Array(7).fill(7200), ...Array(8).fill(14400)];
  assert.equal(stockEventFields(storedStockEvents({ restockElapsedRaw: raw })).restockElapsed.length, 15);
});
