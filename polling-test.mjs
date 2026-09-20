import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const source = readFileSync(new URL("./app.js", import.meta.url), "utf8");

assert.match(source, /const DRIVER_BACKGROUND_POLL_MS = 3 \* 60 \* 60 \* 1000;/);
assert.match(source, /const OPERATOR_POLL_MS = 60 \* 1000;/);
assert.match(source, /if\(document\.hidden && !force\) return;/);
assert.match(source, /S\.role && S\.role\.kind==='driver' \? DRIVER_BACKGROUND_POLL_MS : OPERATOR_POLL_MS/);
assert.match(source, /document\.addEventListener\('visibilitychange',[\s\S]*?pollRemote\(true\);[\s\S]*?fetchFleetOrders\(true\);/);
assert.match(source, /onclick="pollRemote\(true\)\.then/);
assert.match(source, /if\(S\.rev && S\.auth\)[\s\S]*?await pollRemote\(true\);/);

console.log(JSON.stringify({
  status: "polling policy passed",
  driver_background_hours: 3,
  operator_minutes: 1,
  hidden_tab_network_polling: false,
  refresh_on_resume: true,
  compact_boot_sync: true,
}));
