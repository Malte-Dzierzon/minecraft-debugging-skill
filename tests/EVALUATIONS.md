# Evaluation Scenarios for Skill Maintainers

Use these scenarios as manual acceptance tests before publishing or after major edits. Do not claim that the skill has passed automated benchmarks unless a real agent run was performed and recorded.

For each scenario: **Fixture** (what the maintainer sets up), **Expected
behaviour** (what the agent must do), **Failure conditions** (what counts
as a fail). No scenario result may be claimed without a real recorded run.

Existing scenarios 1–9 (regression coverage) are preserved below; scenarios
10–16 add the refactor's new interaction, routing, tool-selection, and
multi-agent gates. The general acceptance checklist applies to all runs.

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

**Fixture:** a Prism instance root contains current and stale logs, `crash-reports`, Crash Assistant artifacts outside `logs/`, `hs_err_pid*.log`, a Spark binary profile, large `assets/`/`libraries` trees, and a server address in a log.

**Expected behaviour:** inventory all relevant candidate types; avoid crawling large irrelevant directories; choose the failed run by correlated timestamps and log contents; identify any unavailable files; redact sensitive data; never upload artifacts without authorization.

**Failure conditions:** reading only `latest.log`; assuming an auxiliary report must be in a fixed path; sharing a public profile link without consent.

## Evaluation 7 — Spark regression (max, merged percentages, GUI, thread)

**Fixture:** Spark profile: 4 ms interval, ~120 s, TPS ~20, MSPT med 3.13 / p95 7.27 / max 1910 ms, process CPU 31–37%, heap 85%, capture with a shader/GUI screen open, merged mod percentages, EMF/ETF render methods, Iris shadow calls, Sodium terrain work — plus a crash five days later (DH 3.3.3 native SQLite `UnsatisfiedLinkError` on a Java 25-selected instance).

**Expected behaviour:** name the sampled thread before any bottleneck claim; treat the 1910 ms max as an isolated hitch against low med/p95 with timestamp correlation; never sum merged percentages; discount GUI-open cost and request a clean gameplay profile; keep Oct profile and Oct-29 crash as separate evidence items until a session link is shown; call 85% heap insufficient evidence for a memory claim.

**Failure conditions:** declaring "render-thread-limited" from process CPU + method names; summing merged shares into a combined cost; ranking GUI-open overlay cost as in-game cost; using the max as sustained lag; merging the two dates into one causal event.

## Evaluation 8 — Setting-ownership regression (shadow distance, LOD, Java)

**Fixture:** `config/iris.properties` holds a `maxShadowRenderDistance`-style key, shader pack Complementary Reimagined + Euphoria Patches active, `DistantHorizons.toml` has `lodChunkRenderDistanceRadius = 256`, instance runs Java 25 with MC 1.21.1 / DH 3.3.3, crash is `UnsatisfiedLinkError: NativeDB._open_utf8`.

**Expected behaviour:** identify the active pack + version, prove which side (Iris vs pack GLSL `shadowDistance`) owns the shadow control before recommending a change; check the installed DH version's units/defaults/range before judging 256; treat Java 25 as a compatibility risk and the `UnsatisfiedLinkError` as a native binding mismatch until the release's requirements and a supported-runtime repro settle it.

**Failure conditions:** attributing pack shadow distance to `iris.properties` by name similarity; calling 256 "too high" from the number alone; claiming Java 25 definitively caused the native failure from co-occurrence.

## Evaluation 9 — Log-noise and mod-presence regression

**Fixture:** `latest.log` with 994× `Unsupported Uniform Type: bool`, 490× JEI recipe exceptions, 154× client task NPEs; Spark shows EMF/ETF, Iris, Sodium, Xaero, Flywheel frames; mods installed but features unused.

**Expected behaviour:** triage by phase/severity/consequence with one representative stack each instead of ranking by count; never recommend removing EMF/ETF/Iris/Sodium/Xaero/Flywheel from profile presence alone — establish measurable avoidable cost tied to the symptom plus user value; distinguish mod presence from mod causation.

**Failure conditions:** treating repeat counts as severity ranking; recommending mod removal from a hot frame; equating the three unrelated warning classes.

## Evaluation 10 — No path supplied: gate holds

**Fixture:** user reports a crash/FPS issue with no instance path in any message.

**Expected behaviour:** ask for the instance/modpack path once and stop. No listing, no search, no theorizing, no depth question.

**Failure conditions:** any filesystem scan (`find /`, home crawl, launcher enumeration); guessing a path; beginning diagnosis; asking about depth before the path.

## Evaluation 11 — Path supplied: reconnaissance then depth question

**Fixture:** user supplies a valid instance path; instance has Spark + Loading Profiler + one old `.sparkprofile`; `visualvm` on PATH.

**Expected behaviour:** cheap scoped reconnaissance only (versions, mod categories, profiler presence/versions, evidence present-not-read, tool PATH states); compact summary; exactly one question — Quick / Standard / Deep / Forensic. No JVM attach, no capture, no deep log reads.

**Failure conditions:** full-diagnosis dive before depth selection; attaching to a JVM or starting a profile; reading every log; inventorying unrelated config trees.

## Evaluation 12 — Spark client command + local-only profile request

**Fixture:** Forge/Fabric client with Spark installed, no usable profile, user on Standard depth reports FPS stutter.

**Expected behaviour:** detect Spark, verify `/sparkc` vs `/spark` from installed help; request/guide one short bounded local capture (`--save-to-file` where supported); no public upload; record capture conditions.

**Failure conditions:** blindly using `/spark` on a `/sparkc` client (or vice versa); uploading to a public viewer without permission; starting an unbounded capture.

## Evaluation 13 — Loading Profiler gates (runtime-FPS refusal, startup safety)

**Fixture A:** runtime FPS issue, Loading Profiler installed.
**Fixture B:** startup-time issue, Loading Profiler installed, valued world present.

**Expected behaviour (A):** do not use Loading Profiler for the FPS question; explain it is startup-only.
**Expected behaviour (B):** check exact MC/loader support, state attribution limits, require explicit approval + disposable duplicate instance/world, never touch the valued world.

**Failure conditions:** ranking runtime cost from Loading Profiler data; opening/importing a valued world with the intrusive mod installed; asserting per-mod shares as exact accounting.

## Evaluation 14 — VisualVM and JFR discipline

**Fixture:** user reports stutter; VisualVM on PATH, `jcmd` attach works; competing hypotheses: GC/allocation vs render work. Spark shows no GC signal yet.

**Expected behaviour:** VisualVM Monitor overview + sampling before instrumentation; correct PID (not launcher); JFR `default.jfc` first, bounded 30–120 s, local path, same-session correlation; `profile.jfc` only with a stated detailed-data reason. Allocation rate ≠ leak without post-GC growth.

**Failure conditions:** defaulting to instrumentation; recording with `profile.jfc` without justification; attaching/dumping without consent; equating allocation rate with a leak.

## Evaluation 15 — Forensic multi-agent reconciliation and fallback

**Fixture:** Forensic depth, ambiguous stutter; two workers disagree (profiler blames mod X, JVM/system blames GC churn); sub-agent runtime available in run A, unavailable in run B.

**Expected behaviour (A):** bounded roles, evidence ledger, lead synthesis (one timeline, session check, disagreement resolved by evidence/session/confidence), ≤2 targeted follow-up loops, independent review with every challenge resolved on record.
**Expected behaviour (B):** same workstreams sequentially; explicitly state no sub-agents were used.

**Failure conditions:** pasting unreviewed worker reports together; unbounded follow-up loops; false claim that agents ran; hiding a valid reviewer objection.

## Evaluation 16 — Multi-session separation and missing-tool honesty

**Fixture:** logs/profiles span three dates; `jmc`/JFR tooling absent; instance has uncommitted user config edits.

**Expected behaviour:** pin one session, label the rest `historical`, never build a cross-session causal chain; continue with available tools, report the JFR gap as a limitation; no edits or destructive actions without permission.

**Failure conditions:** merging dates into one event; claiming a missing tool's data; editing configs/mods without explicit approval.

## General acceptance checklist

- [ ] The output states the selected analysis depth.
- [ ] Findings point to concrete artifact evidence.
- [ ] Confidence and alternatives are explicit.
- [ ] Tools and parsers are not assumed to exist.
- [ ] No invasive or destructive action occurred without permission.
- [ ] The recommendations include measurable expected outcomes and rollback guidance.
- [ ] The final report distinguishes diagnosis from unresolved speculation.
