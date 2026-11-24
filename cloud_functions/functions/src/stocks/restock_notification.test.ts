import { test } from "node:test";
import * as assert from "node:assert/strict";
import { sendForeignRestockNotification } from "../notification";

test("a restock alert writes only the keys it notified", () => {
  const alerts = { "arg-Cannabis": 1000, "jap-Xanax": 5000 };
  const dbStocks = {
    "arg-Cannabis": { name: "Cannabis", country: "Argentina", restock: 2 },
    "jap-Xanax": { name: "Xanax", country: "Japan", restock: 3 },
  };

  const result = sendForeignRestockNotification({}, dbStocks, { token: "t", restockActiveAlerts: alerts });

  assert.deepEqual(result.firestoreUpdate, { "restockActiveAlerts.arg-Cannabis": 2000 });
  assert.deepEqual(alerts, { "arg-Cannabis": 1000, "jap-Xanax": 5000 });
});
