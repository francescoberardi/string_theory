---
title: 'Add keyset pagination and batch chunking to DailyDecayFutureCall'
type: 'refactor'
created: '2026-10-06'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `DailyDecayService.performDecayCalculation` (`string_theory_server/lib/src/future_calls/daily_decay_future_call.dart`) loads every active `StringJob` into memory with one unbounded query, then writes changed rows one by one with full-row `updateRow`. Memory grows with the table and the nightly cron issues one round trip per changed job. Full-row writes can also overwrite a concurrent `totalCourtHours` change made by session logging during the scan. Source: Epic 2 retro action item 2 (`epic-2-retro-item-2-add-batch-pagination-dailydecayfuture`); also the deferred item from spec 2-3.

**Approach:** Read active jobs in fixed-size pages using keyset pagination on `id` (`id > lastId`, ordered by `id`, `limit batchSize`). Per page, compute health with `DecayEngine` as today, then write all changed rows in one batch `update` restricted to the `currentHealthScore` column. Keep the per-job error boundary: a job whose calculation throws is logged and skipped, and if a page's batch write fails, the service logs it and retries that page row by row, so one bad row cannot drop the rest. The return value (count of updated jobs), the log line, and the `DailyDecayFutureCall` / `triggerDailyDecayNow` callers stay the same. Add an optional `batchSize` parameter (default 500) so tests can force several pages. Mark the sprint-status action item done.

</frozen-after-approval>

## Implementation Notes

- Decision: keyset, not offset. Offset pages shift when rows change between pages; `id` keyset uses the primary-key index and is stable. No new index or migration (an `isActive` partial index is not needed at this scale).
- Decision: batch writes restricted to `columns: (t) => [t.currentHealthScore]`, so the cron no longer overwrites a concurrent `totalCourtHours` change. The score itself can still be stale if a session is logged between the page read and the write (see Review Triage Log).
- Files: `string_theory_server/lib/src/future_calls/daily_decay_future_call.dart`, `string_theory_server/test/integration/daily_decay_future_call_test.dart` (new tests: several pages with a small `batchSize` update every active job exactly once and skip inactive ones; `batchSize` that divides the row count exactly; invalid `batchSize` rejected), `_bmad-output/implementation-artifacts/sprint-status.yaml` (item → done).
- TDD: the new tests failed to compile before the change (red: `batchSize` undefined), then passed (green). `dart analyze` clean; full server `dart test` passed (97 tests).
- Dropped the planned concurrent-`totalCourtHours` test: the race needs a write injected between the page read and the batch write, which the service has no seam for. The column restriction is visible in the code instead.
- The batch write uses `noReturn: true`; the row-by-row fallback (on batch failure) is not covered by a test, since there is no clean way to make the batch write fail on demand.
- The final log line now reports `updated/scanned` where `scanned` is the sum of page sizes, matching the old `activeJobs.length`.

## Review Triage Log

- Score computed from hours read with the page can overwrite a newer score written by a concurrent `logSession` (or land on a job a restring just retired): medium, real but older than this change. The old code had the same window, longer, and also overwrote `totalCourtHours`. A fix needs conditional per-row writes or row locks, which gives up the batch. Deferred.
- Row-by-row fallback and per-job calculation error path have no tests: low, real. `DecayEngine.calculateHealth` never throws and the batch write cannot be made to fail on demand without a new seam. Deferred.
- Pagination test kept all inactive rows after the active ones, and the "divides exactly" test checked only the count: low, patched (rows interleaved, each row reloaded and checked).
- Summary log folds failed jobs into the unchanged ones: low, rejected. Every failure is already logged at error level with its job id; a failure counter adds a record return type for rare operator use.
- Spec status and the Files bullet did not match the work: low, patched (status set to done, dropped test removed from the Files bullet).
- Loop spins forever if a row's `id` is null: false. Rows returned by `StringJob.db.find` always carry their primary key.
- No guard against overlapping cron and `triggerDailyDecayNow` runs: medium, real but older than this change (already in deferred work from spec 2-3). Deferred.
- Cron score changes are not pushed to connected clients over the bag stream: medium, real but older than this change. Deferred.
