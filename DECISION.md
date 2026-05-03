# DECISION.md

This file records the design decisions behind significant changes to the
behavior-tracking system. Each entry explains *what* changed and, more
importantly, *why* — so future work can re-evaluate or extend the system
with the original tradeoffs in view.

Entries are listed newest-first.

---

## 2026-05-03 — Layout metadata, S3 rake tooling, summary review page, condition plumbing

This batch was split into four commits, ordered low-risk → high-risk so each
can be reverted independently.

### ⚠ Open verification — needs a human pass in the browser

These changes were verified only by `webpack --config webpack.prod.js` (clean
build). End-to-end UI flow was **not** exercised. Before treating this batch
as complete, walk through the survey with `rake run:frontend` + `rake run:api`
and confirm:

1. **SummaryPage layout + score**: Enter via `?uid=test`, finish all 12
   slider questions, click "下一頁". Confirm `/summary` shows total score
   in 12–84 range, lists all 12 questions with chosen value + min/max
   anchor labels, and that reloading `/summary` keeps the data
   (sessionStorage `survey_answers_v1` is the source of truth).
2. **Condition param round-trip**: Enter via `?uid=test&condition=ctrl`,
   finish the survey + summary + post-survey, confirm the moonbear
   redirect URL ends with `?uid=test&condition=ctrl`.
3. **Metadata events in payload**: With DevTools Network open, confirm
   `POST /api/behavior/{uid}/events` payloads contain `viewport` events
   on every page load and `element-rect` events for each slider after
   mount. Both should re-fire on window resize (~150ms debounce).
4. **Resize re-emits all 12 rects**: Resize the browser window on
   `/survey` and confirm 12 fresh `element-rect` events flush in the
   next batch (one per slider).

### Commit 1 — `feat(rake): add s3:list / s3:sync tasks`

**What changed**

- New `rake s3:list` and `rake s3:sync[dest]` tasks in the existing `:s3`
  namespace. Both shell out to the `aws` CLI; bucket name is read from
  `secrets.yml`'s `S3_BUCKET_NAME` via `SurveyTracker::Api.config` (the
  same source `S3Service` uses).
- README's "Inspecting uploaded S3 data" section replaced raw `aws s3`
  invocations with the rake equivalents.

**Why**

- Hard-coding the bucket name in README drifts from `secrets.yml` the
  moment the bucket is renamed; routing through Roda config keeps a
  single source of truth.
- Wrapping in rake also lets the rest of the team discover the commands
  via `rake -T s3` instead of grepping the README.

**Known tradeoffs**

- Still requires the `aws` CLI on `PATH` (we did not switch to the
  `aws-sdk-s3` gem for `ls` / `sync`). The CLI's output formatting is
  battle-tested for human consumption; reimplementing it on the SDK
  would be churn for no gain.

---

### Commit 2 — `feat(tracker): record viewport and slider rect metadata`

**What changed**

- New `tracker.recordMetadata(payload)` public method — wraps the
  internal `pushEvent` so callers can emit arbitrary metadata events
  with an auto-stamped `ts`.
- New event type `viewport`: emitted by `BehaviorTracker.vue` on mount
  (right after `tracker.start`) and on window resize (debounced 150ms).
  Carries `innerWidth`, `innerHeight`, `devicePixelRatio`, document
  `scrollWidth` / `scrollHeight`, `screen.width` / `height`, and
  `userAgent`.
- New event type `element-rect`: emitted by each `SliderBar.vue`
  instance on mount (`$nextTick`) and on resize. Carries page-relative
  `left/right/top/bottom/width/height` of the `<input type="range">`
  plus `thumbWidth` / `thumbHeight` constants (`THUMB_PX = 22`, kept in
  sync with the CSS `::-webkit-slider-thumb` rule via a comment).

**Why**

- Raw `(x, y)` events are only meaningful relative to a layout. Without
  viewport + element bounds, a 5-px hover offset on a 4K monitor is
  indistinguishable from a 5-px offset on a phone, which kills any
  cross-participant normalization.
- Recording bounds **on resize as well as mount** matters for
  participants who rotate a tablet or split-screen the window
  mid-survey — the rects do change, and a single mount-time snapshot
  would mis-locate every later pointer event.
- Thumb size is recorded so post-hoc analysis can decide whether the
  pointer was inside the draggable region versus the surrounding track.

**Known tradeoffs**

- `THUMB_PX` is a hardcoded constant duplicating the CSS value. Reading
  computed style of a `::-webkit-slider-thumb` pseudo-element isn't
  reliably exposed by the DOM, so the duplicate is the practical
  option. A comment in `SliderBar.vue` flags the sync requirement.
- `userAgent` is also captured in `session.init()`'s session metadata,
  so it appears twice (once in the session row, once in the event
  stream). The event-stream copy is convenient for analyses that only
  load the S3 blob.

---

### Commit 3 — `feat(summary): add review page between survey and post-survey`

**What changed**

- New route `/summary` → `SummaryPage.vue`. Wrapped in `<BehaviorTracker>`
  so dwell time + scroll behavior on this page are also recorded.
- SummaryPage reads `sessionStorage.survey_answers_v1`, sums the 12
  dietary answers as `totalScore` (range 12–84), and renders each
  question with: question text, chosen value (1–7), and both anchor
  labels (`1 = minLabel` / `7 = maxLabel`). Read-only.
- `SurveyPage.goNext()` now routes to `/summary` (was `/postsurvey`).
- Router guard added: `/summary` requires `survey_answers_v1` in
  sessionStorage; otherwise redirect back to `/survey`.

**Why**

- The post-survey reflection questions ask the participant to rate the
  likelihood of lying. Letting them review their actual answers first
  makes that reflection grounded rather than abstract.
- Using sum (not average, not subscale) keeps the score interpretable —
  every question is scored so that higher = healthier, so a single sum
  is the natural composite for this version of the instrument.
- Read-only (cannot edit answers) deliberately — allowing edits would
  diverge `sessionStorage` from the answers already in the captured
  event stream, complicating analysis.

**Known tradeoffs**

- The 12-question array is duplicated between `SurveyPage.vue` and
  `SummaryPage.vue`. We did not extract to a shared module in this
  commit to keep the change focused; if a third page ever needs the
  same list, it should be hoisted to `frontend_app/lib/`.
- `BehaviorTracker` is mounted/unmounted on every route change, so
  resuming `/summary` after a refresh restarts tracking and re-emits
  the viewport/element-rect snapshot. That's a feature for analysis
  (clear page-boundary markers) but means event volume per session
  scales with route count.

---

### Commit 4 — `feat(condition): plumb condition param through URL chain to moonbear`

**What changed**

- `session.init()` reads `?condition=` from the entry URL and persists
  it to `localStorage` under `survey_condition`, alongside the existing
  `uid` flow.
- New `session.getCondition()` getter; `session.clear()` now also wipes
  the condition key.
- Session-register POST metadata includes `condition` so the backend
  session row carries it (no schema change — metadata is JSON).
- `PostSurvey.submit()` appends `&condition=<value>` to the moonbear
  redirect when a condition is present.

**Why**

- Future work will switch survey content based on experimental
  condition (item 4 of the planning doc — SQS-based condition
  assignment). This commit is pure plumbing so the URL flow is in
  place before the assignment logic lands; it lets us start
  hand-distributing `?condition=` URLs immediately.
- Routing the value through `localStorage` (not just URL) means it
  survives the session even after the participant navigates without
  the param — same pattern as `uid`.

**Known tradeoffs**

- No validation of the condition value at any layer. If a typo lands
  in the URL (`?condition=cntrol`), it gets persisted and round-tripped
  to moonbear unchanged. Validation belongs with the assignment logic
  (commit not yet written), so adding it here would be premature.
- Default behavior when no `?condition=` is provided is to fall back to
  the current default content; we deliberately did **not** add a UID-
  style "請使用提供的連結" gate. Once condition-switching exists, that
  policy can be revisited.

---

## 2026-04-24 — Behavior tracker refactor (Pointer migration, page coords, naming standardization, expanded events)

This refactor was split into four commits to keep each change focused and
independently reviewable / revertible.

### Commit 1 — Rename DOM events to kebab-case and migrate mouse → pointer

**What changed**

- All DOM mouse event listeners switched to their Pointer Event equivalents:
  `mousemove → pointermove`, `mousedown → pointerdown`, `mouseup → pointerup`,
  `mouseover → pointerover`, `mouseout → pointerout`.
- All recorded `event.type` strings switched to kebab-case:
  - `mousemove → pointer-move`
  - `mousedown → pointer-down`
  - `mouseup   → pointer-up`
  - `mouseover → pointer-over`
  - `mouseout  → pointer-out`
  - `keydown   → key-down`
  - `slider    → slider-change`
- Each pointer event additionally records `pointerType` (`mouse` / `touch` /
  `pen`) so downstream analysis can filter by input device.
- Backend `VALID_EVENT_TYPES`, `BehaviorEventType` enum, route spec, and
  migration comment updated in lockstep.

**Why**

- **Pointer Events unify mouse / touch / pen** into a single API. Recording
  `pointerType` preserves the device distinction without forking handlers.
- **Kebab-case is the convention we want for *all* event-type strings** going
  forward (including the new event types added in Commit 3). Doing the rename
  in the same commit as the pointer migration avoids a round-trip on the
  backend `VALID_EVENT_TYPES` enum.
- **One atomic frontend + backend commit** prevents a window where the
  frontend sends `pointer-move` but the backend still rejects everything that
  isn't `mousemove`.

**Known tradeoffs**

- On touch devices, a single tap fires
  `pointer-over → pointer-down → pointer-up → pointer-out` in rapid
  succession. Hover-style analysis (`pointer-out.duration`) on touch will
  approach zero — filter by `pointerType !== 'touch'` if hover dwell time is
  the metric.
- `pointer-over` / `pointer-out` remain *delegated* to elements with a
  `data-track` attribute — recording every hover over every DOM node would
  swamp the queue.

---

### Commit 2 — Track absolute page coordinates instead of viewport coordinates

**What changed**

- All recorded `x` / `y` switched from `clientX` / `clientY` (viewport-relative)
  to `pageX` / `pageY` (document-relative, includes scroll offset).
- `highlight` event derives page coords by adding `window.scrollX/Y` to the
  selection's `getBoundingClientRect()` result.
- `key-down` event derives page coords from the focused element's bounding
  rect plus scroll offset (Commit 3 extends this to `key-up`).

**Why**

- The survey pages scroll. With viewport coords, the *same* on-page DOM target
  reports different `(x, y)` depending on scroll position, which makes
  post-hoc replay and heatmap analysis harder than it needs to be.
- Page coords are scroll-independent: a click on the "下一頁" button always
  reports the same `(x, y)` regardless of how the participant scrolled to it.
- Native Pointer Events expose `pageX/pageY` directly — no extra computation
  for the common case.

**Known tradeoffs**

- If a future analysis cares about "what was visible when the participant
  clicked," it needs to combine `pageY` with the recorded `scroll` event's
  `scrollY` to derive viewport position. We accept this because replay /
  heatmap is the more common need.

---

### Commit 3 — Add new event types and generic key tracking

**What changed**

- `key-down` no longer requires the target to match `ACTIVATABLE_SELECTOR`
  (button / link / checkbox / etc.). Every keypress is recorded.
- New event type `key-up` (mirror of `key-down`).
- Both `key-down` and `key-up` exclude `event.repeat = true` to suppress
  hold-to-repeat noise.
- New events recording window / page lifecycle:
  - `focus` and `blur` (window-level only)
  - `page-show` / `page-hide` (covers bfcache restore on mobile back-gesture)
  - `visibility-change` (recorded *as well as* the existing pause behavior)
- Lifecycle events (`focus`, `blur`, `page-show`, `page-hide`,
  `visibility-change`) record `x: null, y: null` — they have no meaningful
  pointer coordinates.
- `key-down` / `key-up` record `x: null, y: null` when no element has
  meaningful focus (i.e. `document.activeElement` is `<body>`).
- Backend `VALID_EVENT_TYPES` and `BehaviorEventType` enum extended.

**Why**

- **Generic key tracking** captures Tab navigation, arrow-key slider
  adjustment, and modifier-key combinations — interactions that are invisible
  to the previous activatable-only filter but informative for behavior
  analysis.
- **`e.repeat` filter** — without it, holding an arrow key would flood the
  queue with hundreds of events per second.
- **`focus` / `blur` at window level** distinguishes "participant is thinking
  with the survey on screen" from "participant alt-tabbed away." Element-level
  focus would log every Tab between buttons, which is too noisy for the
  behavioral signal we want.
- **`page-show` / `page-hide`** captures the iOS / Android back-gesture
  bfcache transitions that `visibilitychange` alone misses.
- **Recording `visibility-change` as an event** (not just using it to pause)
  gives the analysis a precise timestamp for when the tab was hidden / shown,
  rather than having to infer it from gaps in the event stream.

**Known tradeoffs**

- Volume goes up — most notably when participants type. Survey pages have no
  free-text inputs, so privacy isn't a concern here, but if a future page
  adds a `<textarea>`, we should consider redacting `key` / `code` for that
  context.

---

### Commit 4 — Standardize `data-track` to `{prefix}-{role}` convention

**What changed**

- Every `data-track` attribute follows the pattern `{prefix}-{role}`:
  - `q1` (section wrapper) → `q1-element`
  - `label-q1` → `q1-label`
  - `slider-q1` → `q1-slider`
  - `confirm-q1` → `q1-confirm`
  - `pq1` → `pq1-element`, `confirm-pq1` → `pq1-confirm`
  - `practice-q1` → `practice-q1-element`,
    `confirm-practice` → `practice-q1-confirm`
- Page-chrome elements adopt a `page-` prefix:
  - `background → page-background`, `header → page-header`,
    `intro → page-intro`
- Action buttons get descriptive names tied to their flow:
  - `next-button → survey-next`, `next-to-survey → practice-next`,
    `postsurvey-submit-button → postsurvey-submit`
- `SliderBar.vue` gained a `trackPrefix` prop. The component renders
  `data-track="${trackPrefix}-slider"` and forwards the same value as the
  selector to `tracker.recordSlider`. Each consuming page passes its own
  prefix (`q1`, `pq1`, `practice-q1`, …).

**Why**

- The previous naming was a mix of three styles
  (`q1`, `label-q1`, `slider-q1`, `confirm-q1`) which made it impossible to
  group "all interactions on question 1" with a simple prefix match. With
  `{prefix}-{role}`, `startswith("q1-")` returns every element related to
  question 1.
- **`SliderBar.trackPrefix` prop** — the same component is reused across
  Survey, PostSurvey, and Practice pages. Hard-coding `slider-q${idx+1}` made
  the survey and post-survey sliders both emit `slider-q1`, with no way to
  tell them apart in the data. Driving the prefix from the parent fixes
  this without forking the component.
- **`page-` prefix for chrome** — keeps non-question elements out of the
  per-question namespace so prefix grouping remains clean.

**Known tradeoffs**

- This is a breaking change for any analysis script that hard-codes the
  previous `data-track` strings. All historical data uses the old names —
  analysis code reading both old and new sessions needs a translation table.

---

## How to add a new entry

1. Add a new section at the top of the file (newest-first).
2. Use the date in `YYYY-MM-DD` format.
3. For each commit (or logical change), record:
   - **What changed** — concrete, file-level summary.
   - **Why** — the reasoning, especially anything not obvious from the diff.
   - **Known tradeoffs** — anything we deliberately accepted as a cost.
4. Keep entries focused on *decisions*, not implementation walkthroughs —
   the diff already shows the *what*; this file is for the *why*.
