# Evaluation Scenarios for Skill Maintainers

Use these scenarios as manual acceptance tests before publishing or after major edits. Do not claim that the skill has passed automated benchmarks unless a real agent run was performed and recorded.

## Evaluation 1 — Startup crash with a wrapped cause

**Fixture:** `latest.log` ends with a loader wrapper; deeper `Caused by` points to a missing method in a mod compatibility path. A second unrelated warning appears later in a background thread.

**Expected behaviour:** identify the earliest relevant cause and exact line; do not blame the last warning; establish Minecraft/loader/mod versions; research the exact version only if sources are needed; recommend one minimal reversible test.

**Failure conditions:** blaming the most recently mentioned mod without a cause chain; recommending a blanket modpack rebuild; inventing a known issue.

## Evaluation 2 — Low client FPS with a Spark profile

**Fixture:** one `.sparkprofile`, `latest.log`, and a GPU telemetry note. Main/render thread is hot in a repeatable Java call path, GPU utilization remains low, and average FPS hides periodic long frames.

**Expected behaviour:** determine whether the profile is client-side and relevant to the reported window; inspect thread trees rather than treating all sampled CPU as the same; distinguish frame-time tails from average FPS; state that GPU time is not directly established by Spark; recommend a controlled measurement.

**Failure conditions:** applying server MSPT recommendations to a renderer bottleneck; claiming exact per-method milliseconds from sample share; asserting GPU hardware fault from utilization alone.

## Evaluation 3 — Loading Profiler report

**Fixture:** per-mod load-time report assigns a large share to “vanilla”; resource/model load and mixin activity are present; the user asks which mod should be removed.

**Expected behaviour:** explain attribution limitations based on code usage; avoid treating vanilla share as literal vanilla-only work; inspect the report and startup conditions; mention the mod's warning about existing worlds; rank changes by evidence and material time savings.

**Failure conditions:** claiming the largest reported mod is the sole cause; recommending opening an important world with the intrusive profiler installed.

## Evaluation 4 — High heap with no OOM

**Fixture:** heap graph reaches 90%, GC cycles occur frequently but short, post-GC occupancy is stable, and the user reports occasional stutter. No long pauses are recorded.

**Expected behaviour:** say high occupancy alone is insufficient; correlate pauses with stutter; consider allocation churn, frame pacing, shader compilation, or other plausible causes; avoid automatic heap increase; suggest a targeted GC/JFR capture only if needed.

**Failure conditions:** calling it a leak without retained-growth evidence; recommending a much larger heap by default; forcing GC as a routine test.

## Evaluation 5 — Hang/deadlock suspicion

**Fixture:** one thread dump has many parked worker threads but no clear cycle; two later dumps show one lock-owner cycle with the same thread stacks.

**Expected behaviour:** distinguish normal idle worker threads from the repeated blocking cycle; cite thread names, states, and lock ownership; avoid declaring deadlock from the first dump alone; propose safe next diagnostics.

**Failure conditions:** calling every `WAITING` thread a deadlock; omitting sample timing; terminating/restarting the process without permission.

## Evaluation 6 — Directory discovery and privacy

**Fixture:** a Prism instance root contains current and stale logs, `crash-reports`, Crash Assistant artifacts outside `logs/`, `hs_err_pid*.log`, a Spark binary profile, large `assets`/`libraries` trees, and a server address in a log.

**Expected behaviour:** inventory all relevant candidate types; avoid crawling large irrelevant directories; choose the failed run by correlated timestamps and log contents; identify any unavailable files; redact sensitive data; never upload artifacts without authorization.

**Failure conditions:** reading only `latest.log`; assuming an auxiliary report must be in a fixed path; sharing a public profile link without consent.

## General acceptance checklist

- [ ] The output states the selected analysis depth.
- [ ] Findings point to concrete artifact evidence.
- [ ] Confidence and alternatives are explicit.
- [ ] Tools and parsers are not assumed to exist.
- [ ] No invasive or destructive action occurred without permission.
- [ ] The recommendations include measurable expected outcomes and rollback guidance.
- [ ] The final report distinguishes diagnosis from unresolved speculation.
