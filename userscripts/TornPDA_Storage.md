# Torn PDA native per-script storage (`PDA_storage`)

A durable key/value store backed by the app (SQLite), **not** the page's `localStorage`. Use it for anything sizeable or that must survive a browser cache clear (caches, datasets, history).

## Why use it instead of `localStorage` / `GM_setValue`

- `localStorage` is ~5 MB **shared** across Torn and every userscript, and the engine can evict it under pressure.
- `PDA_storage` gives each script its own space (10 MB by default, the user can raise it), on disk, and it is never touched by clearing the browser cache.

## Notes

- The whole API is **async**. There is no synchronous read like `GM_getValue`.
- Each script works in its own namespace automatically, so the API only ever sees that script's own keys (this keeps scripts from colliding; it is not a security sandbox against other scripts you install).
- Values are anything JSON serialisable (objects, arrays, numbers, strings, booleans).
- Reads/writes cross the app bridge, so for hot paths **load once** (`loadAll`/`getMany`) and work in memory, and **batch writes** with `setMany` instead of many single `set()` calls.
- `set`/`setMany` reject with an `Error` (`err.code === "QuotaExceeded"`) when the limit is reached; the app also shows the user a toast. Wrap writes in `try/catch` if you want to handle it.

`PDA_storage` is injected into your script automatically.

## API

| Method | Description |
| --- | --- |
| `await PDA_storage.get(key, def)` | Stored value for `key`, or `def` (default `undefined`) when missing. |
| `await PDA_storage.getMany(["a", "b"])` | `{ key: value, ... }` for the given keys (missing keys map to `null`). |
| `await PDA_storage.loadAll()` | `{ key: value, ... }` for every key in this script's namespace. Best for a single load on start. |
| `await PDA_storage.list()` | Array with all keys in this script's namespace. |
| `await PDA_storage.set(key, value)` | Stores `value` under `key`. Rejects with `QuotaExceeded` if over the limit. |
| `await PDA_storage.setMany({ a: 1, b: 2 })` | Stores several pairs in one round-trip. Rejects as a whole if over the limit. |
| `await PDA_storage.delete(key)` | Removes `key` from this script's namespace. |
| `await PDA_storage.usage()` | `{ used, quota }` in bytes for this script. |

## Example

```js
// Load once on start, then work in memory
const cache = await PDA_storage.loadAll();

// ... use and mutate `cache` ...

// Persist in one batched write
try {
  await PDA_storage.setMany(cache);
} catch (err) {
  if (err.code === "QuotaExceeded") {
    // storage full: the user was already notified, degrade gracefully
  }
}
```

## Test script

Install this as a userscript in Torn PDA to exercise the whole API. It logs each check to the console (`[PDA_storage test]`) and shows a summary alert. It cleans up its test keys but leaves a small sample behind so you can see it in DevTools → Storage → "Torn PDA Script Storage" and the green badge on the script. Set `RUN_QUOTA_TEST` to `true` to also force the quota limit (writes up to the script's cap, then deletes).

```js
// ==UserScript==
// @name         PDA_storage Test
// @namespace    torn-pda
// @version      1.0.0
// @description  Tests the whole PDA_storage API and reports the result
// @author       Torn PDA
// @match        *://*.torn.com/*
// @run-at       document-end
// ==/UserScript==

(async () => {
  if (window.top !== window.self) return;
  const TAG = "[PDA_storage test]";
  const RUN_QUOTA_TEST = false;
  const results = [];
  const check = (name, cond) => {
    results.push(cond);
    console.log(`${TAG} ${cond ? "PASS" : "FAIL"} - ${name}`);
  };

  if (typeof PDA_storage === "undefined") {
    console.error(`${TAG} PDA_storage is not available here`);
    return;
  }

  try {
    // Clean slate
    for (const k of await PDA_storage.list()) await PDA_storage.delete(k);

    await PDA_storage.set("greeting", "hello");
    check("set/get string", (await PDA_storage.get("greeting")) === "hello");

    check("get missing returns default", (await PDA_storage.get("nope", 42)) === 42);

    const obj = { a: 1, b: [1, 2, 3], c: { nested: true } };
    await PDA_storage.set("obj", obj);
    check("object round-trip", JSON.stringify(await PDA_storage.get("obj")) === JSON.stringify(obj));

    await PDA_storage.setMany({ x: 10, y: 20, z: 30 });
    const many = await PDA_storage.getMany(["x", "y", "z"]);
    check("setMany/getMany", many.x === 10 && many.y === 20 && many.z === 30);

    check("getMany missing -> null", (await PDA_storage.getMany(["ghost"])).ghost === null);

    const keys = (await PDA_storage.list()).sort();
    check("list keys", JSON.stringify(keys) === JSON.stringify(["greeting", "obj", "x", "y", "z"]));

    const all = await PDA_storage.loadAll();
    check("loadAll", all.greeting === "hello" && all.x === 10);

    await PDA_storage.delete("greeting");
    check("delete", (await PDA_storage.get("greeting", null)) === null);

    const usage = await PDA_storage.usage();
    check("usage has used/quota", typeof usage.used === "number" && usage.quota > 0);
    console.log(`${TAG} usage: ${usage.used} / ${usage.quota} bytes`);

    if (RUN_QUOTA_TEST) {
      const chunk = "x".repeat(1024 * 1024); // 1 MB
      let caught = false;
      try {
        for (let i = 0; i < 100; i++) await PDA_storage.set("big_" + i, chunk);
      } catch (err) {
        caught = err.code === "QuotaExceeded";
        console.log(`${TAG} quota rejected as expected: ${err.code}, used ${err.used}/${err.quota}`);
      }
      check("quota throws QuotaExceeded", caught);
      for (const k of await PDA_storage.list()) if (k.startsWith("big_")) await PDA_storage.delete(k);
    }

    // Clean up the test keys, then leave a small sample behind so you can see it in
    // DevTools > Storage > "Torn PDA Script Storage" (and the green badge on this script)
    for (const k of await PDA_storage.list()) await PDA_storage.delete(k);
    await PDA_storage.setMany({
      demo_note: "PDA_storage demo data - safe to delete",
      demo_items: [1, 2, 3, 4, 5],
      demo_when: new Date().toISOString(),
    });

    const passed = results.filter(Boolean).length;
    const usageAfter = await PDA_storage.usage();
    console.log(`${TAG} DONE - ${passed}/${results.length} passed. Left ${usageAfter.used} B of demo data.`);
    alert(`${TAG} ${passed}/${results.length} checks passed. Left demo data in storage (see DevTools > Storage).`);
  } catch (e) {
    console.error(`${TAG} unexpected error`, e);
  }
})();
```
