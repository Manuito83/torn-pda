import { readFileSync } from "fs";
import { parentPort, workerData } from "worker_threads";

parentPort?.postMessage({ started: true });
const { checker, data, task, recording, seed } = workerData;
require(checker);
const run = (globalThis as any).sessionCheck(new Uint8Array(readFileSync(data)));
parentPort?.postMessage(run(task, recording, seed));
