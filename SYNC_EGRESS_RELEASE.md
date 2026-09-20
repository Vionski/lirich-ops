# Driver sync egress release

## Problem fixed

The legacy sync function returned the complete `app_state` JSON after every mutation. Every other open device detected the revision and also downloaded that complete state. The current state is approximately 2 MB, so a single job or trip update could transfer several copies of the full database.

This release returns only the changed job, trip, bin or client to protocol-v2 clients. Existing phones that have not refreshed yet continue receiving the legacy full-state response. Other updated devices request compact per-revision changes and fall back to the full state only when they are too far behind, a bulk replacement occurred, or the change log is unavailable.

## Files

- `app.js`: compact mutation merge and delta polling with old-server fallback
- `sw.js`: cache version `v76`
- `supabase/functions/sync/index.ts`: compact responses, delta endpoint, error-checked state writes and 30-day delta retention
- `supabase/migrations/20260920000100_app_state_delta_sync.sql`: private delta table
- `supabase/migrations/20260920000200_security_and_policy_hardening.sql`: security-invoker views and non-overlapping staff write policies
- `supabase/tests/compact_sync_client.mjs`: compatibility checks for compact and legacy responses

## Expected effect

- Mutation response: approximately 2 MB before; normally a few KB after
- Other-device update: approximately 2 MB before; normally a few KB after
- Initial app boot: unchanged, because it still downloads one complete state
- Bulk client/bin replacement: deliberately falls back to a complete refresh

The exact saving depends on record size and the number of open devices, but routine synchronisation transfer should fall by well over 90%.

## Staging release order

1. Back up the staging database.
2. Apply `20260920000100_app_state_delta_sync.sql`.
3. Apply `20260920000200_security_and_policy_hardening.sql`.
4. Deploy the updated `sync` Edge Function.
5. Publish `app.js` and `sw.js` together.
6. Open one operator and two driver sessions.
7. Add a test job, accept it, save a draft trip, complete it and update its weight.
8. Confirm each session receives the same job/trip/bin status without a full-state response.
9. Confirm the `collections` and `jobs` normalized rows remain correct.
10. Run the portal tenant-isolation and booking regression suites.

## Production gate

Compatibility exists in both directions: the new function detects old clients and returns the legacy response, while the new browser understands both response types. The complete transfer saving requires the migration, function and browser release.

Before production:

- Capture the current Edge Function source and GitHub Pages build.
- Take a database backup.
- Complete the staging workflow above.
- Test on one office device and one designated driver phone.
- Observe function errors and egress for at least one working cycle.

## Rollback

1. Restore the previous `sync` Edge Function.
2. Restore the previous `app.js` and increment the service-worker cache name again.
3. Leave `app_state_changes` in place; it is additive and inaccessible to browser roles.
4. If required later, drop the delta table only after all compact-sync clients have been retired.

## Deferred security work

The hard-coded shared driver key remains a release blocker for broader onboarding. Replacing it safely requires individual driver/device enrolment and short-lived server-issued tokens. Removing it without that replacement would lock out the existing phones. This work should be staged as a separate authentication release after the egress fix.
