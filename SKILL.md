---
name: minecraft-debugging-skill
description: Diagnoses Minecraft Java Edition crashes, startup/loading failures, FPS stutter, tick lag, memory/GC pressure, and mod compatibility from logs, crash reports, Spark profiles, Loading Profiler output, or an instance/modpack folder. Use when the user reports a crash, freeze, hang, slow startup, low FPS, high MSPT, low TPS, GC pauses, Spark/JFR/dump output, or supplies an instance path.
---

# Minecraft debugging

Evidence-led diagnosis of Minecraft Java Edition clients and servers.
Reconstruct what happened from artifacts, separate measurement from
inference, and propose the smallest useful next test. Vanilla, Forge,
NeoForge, Fabric, Quilt, modpacks, launcher-managed instances.
OS- and launcher-independent.

Never recommend removing mods, changing JVM flags, adding RAM, or touching
graphics settings without naming the evidence and how to verify the outcome.

## Instance path — wait for it

No instance path, no diagnosis. NEVER scan the computer for modpacks or
instances: no filesystem-wide search, no `find /`, no home-directory crawl,
no launcher-library enumeration to "find something to work on".

1. **Path supplied → use exactly that path.** The only permitted expansion
   is the immediate parent when it holds `instance.cfg` / `mmc-pack.json`
   (instance root with game dir inside). Everything else stays out of scope.
2. **No path supplied → STOP and ask before doing anything else.** No file
   listing, no searching, no theorizing. The path question outranks the
   scope-check question below.

Ask once, concretely:

> I need your instance/modpack folder path to start — e.g. `/home/xealom/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances/Server Modpack/minecraft`. Prism Launcher: right-click instance → Folder; Modrinth App / CurseForge / FTB App: instance settings → installation folder; vanilla: `.minecraft/`. Paste the path here — instance root or the `minecraft/` / `.minecraft/` game directory inside it both work.

## Rules

1. **Inspect before theorizing.** Enumerate files first; never assume only
   `latest.log` matters.
2. **Read-only by default.** Never delete, edit, move, or overwrite evidence.
   Ask before live attach, heap dumps, heavy profiles, or flag changes.
3. **Prefer local evidence.** No uploads or public viewer links without
   explicit permission. Logs leak paths, users, servers, IPs, tokens.
4. **Fact vs inference.** Tag every key finding `Confirmed` / `Strongly
   supported` / `Plausible` / `Unverified`, tied to a path, line, metric, or
   measured comparison.
5. **No cargo-cult tuning.** The top stack frame, last log line, or hottest
   sample is not automatically the cause. No universal RAM amounts, flag
   dumps, or "remove optimization mods" without evidence plus rollback. Never
   remove a core/content mod as a first guess.
6. **One variable per test.** Label diagnostic experiments as such; lasting
   recommendations need a measured win and a rollback path.
7. **Session binding.** Never combine artifacts from different dates/sessions
   into one causal event. Label older evidence `historical`.

## Scope check (Phase A)

If no depth was requested, do a cheap file listing first, then ask one
question before expensive analysis:

> How deep: **Quick** (cause + next step), **Standard** (normal diagnosis),
> **Deep** (cross-checked), or **Forensic** (exhaustive + verification plan)?

- **Quick** — most recent crash/session + strongest immediately verifiable
  cause. Not a complete performance audit.
- **Standard** — inventory, log↔profiler correlation, ranked hypotheses +
  next validation step.
- **Deep** — plus configs, mod versions, profiler details, version-matched
  docs/source, alternative explanations.
- **Forensic** — multi-session timeline, dumps/traces where available,
  native/JVM compatibility, competing hypotheses with confidence.

Skip the question if depth was given, the case is urgent, or a small artifact
set already answers it. If the user wants an immediate answer or the runtime
supports no follow-up, proceed with **Standard**. Always state the scope used
and which important evidence is missing.

## Workflow

### Phase B — Inventory before interpreting

Open [1](references/1-artifacts.md) first. Inspect the supplied directory
with filesystem/shell tools — no new inventory scripts. Without terminal
access, use file search/list/read facilities and state the limitation.

Record per important artifact: path, modification time, apparent
session/date, type, whether it is complete, and which question it answers.
Priority: session logs, `debug/` disconnect reports, crash reports, JVM
fatal logs, Loading Profiler output, profiler captures, mod-generated
diagnostics, env metadata, then only implicated configs. Skip `assets/`,
`libraries/`, caches, screenshots, backups, world blobs by default.

Read the actual installed mod list from `mods/` filenames plus
manifests/loader metadata — never from the user's prose or a remembered
pack. Exact versions and loader first. A mod's presence alone is not
evidence. Do not dump every file into context; build the inventory, then
read high-value files in priority order.

### Phase C — Symptom and timeline

Establish the symptom first: startup delay, crash, low average FPS,
intermittent frametime spikes, world/chunk loading stutter, entity-heavy
scenes, memory pressure, GC pauses, server tick lag, network lag — or a
combination. Then separate sessions and phases: launch/bootstrap and mod
init → resource reload → menus/overlays → world load and initial chunk/LOD
generation → stable gameplay → transitions (teleport, dimension change,
shader settings, entity-heavy areas) → shutdown/crash.

Build the timeline from timestamps and stack traces. Correlate the last
log, crash report, profiler capture, Loading Profiler output, and config
snapshot only when their timestamps and session context support that
association. A log from one date and a profile from another are two
evidence items, not one event.

### Phase D — Which subsystem is actually limited

Open [2](references/2-crash.md) for crashes, [3](references/3-performance.md)
for slowness. Do not infer the bottleneck from total process CPU, one
profiler method, average FPS, heap percentage, or TPS alone. Distinguish:

- Tick thread: tick duration, MSPT distribution, TPS, entity/block-entity work.
- Render thread: CPU time in rendering, submission stalls, GUI/HUD work,
  chunk setup, entity and block-entity rendering.
- GPU workload: actual GPU utilization, GPU frame time, shader/shadow cost,
  resolution. Java CPU sampling does not measure GPU execution time.
- Chunk/world/LOD: generation, meshing, uploading, streaming, LOD
  construction, background worker contention.
- JVM/GC: heap over time, allocation rate, pause durations, collector
  activity, retained objects, thread contention.
- Startup/loading: mod init phases, resource reloads, mixin/transformer
  overhead, dependency/setup work.
- Network: packet/latency symptoms plus server-side evidence.

A client can stutter while server TPS stays healthy; healthy TPS never
proves a render-thread limit. Identify which thread/process the profiler
sampled and whether the window covers the symptom. Treat one extreme
maximum as an outlier until the distribution or timeline repeats it —
always report median, p95, max, duration, sampling interval, and capture
conditions. Never let a single max stand in for typical behavior.

### Phase E — Read each profiler per its semantics

Then read exactly one reference and follow it:

- Crash, startup, loader, mixin, linkage, registry, world/data, native,
  OOM, hang → [2](references/2-crash.md).
- FPS, frame time, startup timing, tick lag, memory, GC, JFR, thread
  dumps → [3](references/3-performance.md).

Spark: record side (client/server), command variant (`/sparkc` on
Forge/Fabric clients), capture type, mode, window, interval, and thread
selection before quoting any number. Merged/overlapping call paths
double-count parents and children — never sum merged percentages as if
they were independent costs. Inspect call trees and stack context, not the
mod summary alone. Note any open menu, F3, shader screen, inventory, or
overlay during sampling. Never claim a file was decoded when tooling could
not read it (`.sparkprofile` is binary).

Loading Profiler: use its measured per-mod/per-phase timings plus the
installed versions for bootstrap/load cost only. Name the measured phase;
do not infer startup cost from runtime Spark data. Check the profiler's
current output format and limitations in its official docs at analysis time.

JFR/VisualVM/JVM: match the capture to the question (CPU samples,
allocation hotspots, GC events, thread states/locks, heap data, native
failures) and state what it can and cannot prove. Request invasive or very
large dumps only for a clear diagnostic reason, with cost/privacy consent.

Logs/crash reports: find the first relevant exception and its full
`Caused by` chain — not the last line or the largest repeat count.
Separate fatal causes from unrelated warnings and later cascades. Group
repeats by count with one representative stack; note phase and consequence.

### Phase F — Verify config and version claims

Open [4](references/4-verification.md) before recommending any setting,
runtime, or version change. A key appearing in a config file does not prove
it is active, supported, or responsible. Confirm owner (MC, loader, mod,
shader pack, resource pack), that the installed version reads that key,
and that the file is the one the running instance uses. Check deprecated,
ignored, overridden, stale-version, or path-specific keys. Never call a
distance, thread count, heap size, or render setting "too high" from the
number alone — interpret it against that mod/version's units, defaults,
documented range, workload, hardware, and measured impact. Vanilla
render-distance intuition never applies to LOD-mod radii.

Shader settings: identify the active pack and version, then determine
which control belongs to Iris and which is implemented by the pack itself.
A similarly named key in an Iris config file does not control the pack's
shadow distance until proven. Java compatibility: verify exact MC, loader,
mod, launcher-selected Java executable, and the mod release's declared
runtime requirements. Out-of-tested-range is a compatibility risk, not
proof of causality. A JNI `UnsatisfiedLinkError` proves a native
binding/load mismatch — not, by itself, that the Java major version
caused it. State `verified` vs `inferred` for every runtime claim.

### Phase G — Fresh, targeted research

Prefer, in order: (1) installed artifact/config plus that exact version's
docs or source; (2) official project page, release notes, changelog, repo,
issue tracker for the exact version; (3) official
Minecraft/loader/Java/launcher docs; (4) reputable technical discussion
only as secondary evidence. Record URL, version/date, and the claim each
source supports. Verify the source matches the exact game version and
release. Never cite a homepage as proof of a specific behavior. A closed
issue is not a fix — read the resolution and affected versions.

### Phase H — Hypotheses

Per finding write: **Observation** (exact value, message, method,
timestamp, path), **Interpretation** (what it supports and does not),
**Confidence**, **Alternative** (at least one where ambiguous),
**Validation** (smallest distinguishing test/artifact), **Expected result**
(what moves confidence up or down). Causal language only with a direct
failure chain, reproducible isolation, or strong converging evidence —
otherwise "correlates with" / "consistent with" / "not yet established".
A hot method may be shared code, a framework callback, a wrapper, or a
child of another path; a mod name in a stack is not proof it is avoidable
or broken. Always weigh the actual workload: entity count, GUI state,
chunk count, shader pack, world, resource reload, sampled path.

### Phase I — One change at a time

Order by information value and risk: no-change checks → one-variable
isolation on a copy → targeted measurement → mod-group search with backup
→ config/version change with rollback. Per change state: exact file/UI
path, current value only if verified, proposed value or test action,
expected measurable effect, risks/trade-offs, rollback path, and the
metric to recapture. Never invent config paths or keys. Never edit
modpacks/configs or remove mods without explicit authorization. Benchmarks
hold workload, world, settings, JVM, and warm-up constant; report medians
and tails, not one lucky frame.

## Sub-agents

Only when the runtime offers them and parallel streams exist (crash line,
profile, JVM, compatibility). Inventory first, delegate one bounded
question with exact paths per worker, demand evidence-backed findings with
uncertainty. Suggested splits: session/log analyst, profiler analyst,
compatibility/config researcher, independent reviewer (challenges the
leading diagnosis, checks percentage arithmetic, hunts unsupported causal
claims, verifies rollback paths). The lead reconciles conflicts and
deduplicates — never paste unreviewed agent reports together. Without
sub-agents, work sequentially and say nothing implying they were used.

## Report

Final message shape — fixed sections, fixed order. Tune detail to depth,
but keep every section when relevant. Goal: skimmable in 60 seconds,
verifiable in 10 minutes. Short lines, no prose paragraphs carrying
numbers alone.

### 1. Bottom line

Primary symptom plus leading supported explanation with confidence.
Explicitly say what is not yet known. Max 3–4 sentences.

### 2. Evidence reviewed

Relevant artifacts with timestamps/sessions, profiler type and capture
conditions (side, window, interval, thread selection, GUI state). Name
important missing evidence. Flag anything `historical`.

### 3. Findings

Observations separated from interpretations, with paths:lines, method
names, values, and source links where used. Tables only where they improve
comparison — never an undifferentiated mod list, never log verbatim, never
folklore. Example shapes (use when numbers exist, 3–7 rows each):

Key metrics table: metric | value | why it matters — values measured or
`n/a (missing)`, never inferred. Plain GitHub-flavored pipe tables, no HTML.

Hotspots table (profiler data only): rank one row per mod/method with
overlap noted (merge mode double-counts); implicated config as `code`.
No profile → skip the table, name the capture that would answer it.

### 4. What the evidence does not prove

Key alternatives and unsupported assumptions ruled out or still open —
one line each with the test that would settle it.

### 5. Prioritized next steps

Low-risk, reversible, one change at a time, each tied to a measurable
target and rollback. Per step: change, rationale, expected observation,
success criterion, rollback and save risk. Verification and rollback are
REQUIRED for every step that changes files/settings.

### 6. Next capture

Only the specific artifact or experiment needed to settle the leading
uncertainty: exact command, duration, conditions (e.g. `/sparkc profiler`,
2–3 min, no GUI open), and what comparison decides the next step.

Rules for all of the above: redact secrets; no uploads/viewer links
without permission; small excerpts only; never fabricate trees,
percentages, links, or results; each number lives in exactly one table,
referenced — not repeated — elsewhere.

## References

- [1 — finding artifacts](references/1-artifacts.md): inventory first, where
  to look, search priority, safe reading, privacy. Open before anything else.
- [2 — crashes and compatibility](references/2-crash.md): signatures, chains,
  log triage, version checks, minimal tests, mixins, native, memory. Open for
  any crash/startup/hang/exception.
- [3 — performance and the JVM](references/3-performance.md): Spark, Loading
  Profiler, client vs server, GPU limits, GC, hangs, controlled experiments.
  Open for any FPS/tick/startup-timing/memory question.
- [4 — verification and sources](references/4-verification.md): setting
  ownership, LOD/shader/Java/native rules, research order, citation format.
  Open before any setting/runtime/version claim.
