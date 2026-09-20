import assert from "node:assert/strict";
import fs from "node:fs";
import vm from "node:vm";

const source = fs.readFileSync(new URL("../../app.js", import.meta.url), "utf8");
const serverSource = fs.readFileSync(new URL("../functions/sync/index.ts", import.meta.url), "utf8");

assert.match(source, /action, key: DEVICE_KEY, protocol:2/, "new clients must request compact protocol v2");
assert.match(serverSource, /Number\(q\.protocol \|\| 1\)/, "server must default unversioned clients to legacy protocol v1");
assert.match(serverSource, /protocol >= 2[\s\S]*: json\(st\)/, "server must retain a full-state response for old clients");

function functionSource(name) {
  const start = source.indexOf(`function ${name}(`);
  assert.notEqual(start, -1, `missing function ${name}`);
  const brace = source.indexOf("{", start);
  let depth = 0;
  for (let i = brace; i < source.length; i += 1) {
    if (source[i] === "{") depth += 1;
    if (source[i] === "}") depth -= 1;
    if (depth === 0) return source.slice(start, i + 1);
  }
  throw new Error(`unterminated function ${name}`);
}

let migrateCalls = 0;
let persistCalls = 0;
const context = {
  S: {
    jobs: [{ id: 1, status: "assigned" }],
    trips: [],
    bins: [{ no: "B1", status: "yard" }],
    clients: [],
    seq: { job: 2, trip: 1, ticket: 1 },
    rev: 10,
  },
  migrate: () => { migrateCalls += 1; },
  persist: () => { persistCalls += 1; },
};
vm.createContext(context);
vm.runInContext([
  functionSource("upsertCompact"),
  functionSource("applyCompact"),
  functionSource("mutationEntity"),
].join("\n"), context);

context.applyCompact({
  rev: 11,
  seq: { job: 3, trip: 1, ticket: 1 },
  result: { job: { id: 2, status: "assigned" } },
});
assert.equal(context.S.jobs.length, 2);
assert.equal(context.S.rev, 11);
assert.equal(context.S.seq.job, 3);

context.applyCompact({
  rev: 12,
  payload: {
    job: { id: 2, status: "done" },
    trip: { id: 9, jobId: 2, doNo: "D9" },
    bins: [{ no: "B1", status: "client" }, { no: "B2", status: "yard" }],
    seq: { job: 3, trip: 10, ticket: 2 },
  },
}, false);
assert.equal(context.S.jobs.length, 2, "job update must not duplicate the record");
assert.equal(context.S.jobs.find((j) => j.id === 2).status, "done");
assert.equal(context.S.trips.length, 1);
assert.equal(context.S.bins.length, 2);
assert.equal(context.S.bins.find((b) => b.no === "B1").status, "client");
assert.equal(context.S.seq.trip, 10);
assert.equal(context.S.rev, 12);

assert.equal(context.mutationEntity({ result: { trip: { id: 5 } } }, "trip").id, 5);
assert.equal(context.mutationEntity({ trips: [{ id: 3 }, { id: 4 }] }, "trip").id, 4);
assert.equal(migrateCalls, 1);
assert.equal(persistCalls, 1);

console.log("compact sync client tests passed");
