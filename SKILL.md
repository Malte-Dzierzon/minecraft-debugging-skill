---
name: minecraft-debugging-skill
description: Diagnoses Minecraft Java Edition crashes, startup failures, FPS stutter, tick lag, and JVM/GC issues from logs or an instance folder. Use when the user mentions a crash, freeze, hang, slow startup, low FPS, high MSPT, low TPS, Spark profile, JFR, or supplies a modpack/instance path.
---

# Minecraft debugging

Evidence-led diagnosis of Minecraft Java clients and servers. Reconstruct
what happened from artifacts, separate symptom from cause, and propose the
smallest safe, testable next steps. Vanilla, Forge, NeoForge, Fabric, Quilt,
modpacks, launcher-managed instances. OS- and launcher-independent.

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


## Use when the user reports

- Crash, freeze, hang, black screen, startup failure, failed world load, or
  mod-loading error.
- Slow startup or resource reloads, low FPS, stutter, GC pauses, memory
  growth, server lag, low TPS, high MSPT.
- Hands over logs, crash reports, Spark profiles, Loading Profiler output,
  JFR, thread or heap dumps — or an instance/modpack folder.

## Rules

1. **Inspect before theorizing.** Enumerate files first; never assume only
   `latest.log` matters.
2. **Read-only by default.** Never delete, edit, move, or overwrite evidence.
   Ask before live attach, heap dumps, heavy profiles, or flag changes.
3. **Prefer local evidence.** No uploads or public viewer links without
   explicit permission. Logs leak paths, users, servers, IPs, tokens.
4. **Fact vs inference.** Tag every key finding `Confirmed` / `Strongly
   supported` / `Plausible` / `Unresolved`, tied to a path, line, metric, or
   measured comparison.
5. **No cargo-cult tuning.** The top stack frame, last log line, or hottest
   sample is not automatically the cause. No universal RAM amounts, flag
   dumps, or "remove optimization mods" without evidence plus rollback.

## Scope check

If no depth was requested, do a cheap file listing first, then ask one
question before expensive analysis:

> How deep: **Quick** (cause + next step), **Standard** (normal diagnosis),
> **Deep** (cross-checked), or **Forensic** (exhaustive + verification plan)?

- **Quick** — listing, latest relevant log + one crash/error artifact.
- **Standard** — session logs, crash reports, env metadata, ranked diagnosis.
- **Deep** — plus history, config/mod search, profiler data, second evidence.
- **Forensic** — full timeline, competing hypotheses, limits, benchmark plan.

Skip the question if depth was given, the case is urgent, or a small artifact
set already answers it. State the scope used.

## Workflow

### 1. Inventory

List candidate files without dumping contents — paths, sizes, modification
times. Check the supplied path plus a plausible parent (instance root with
`instance.cfg` / `mmc-pack.json`). Priority: session logs, `debug/`
disconnect reports, crash reports, JVM fatal logs, Loading Profiler output,
profiler captures, mod-generated diagnostics, env metadata, then only
implicated configs. Skip `assets/`, `libraries/`, caches, screenshots,
backups, world blobs by default. Details: [1](references/1-artifacts.md).

A crash can predate `latest.log` finalization, and `latest.log` may belong
to a later clean run. Correlate timestamps and session banners.

### 2. Environment

Record only what's present — never guess: MC version, client / integrated
server / dedicated server, loader + build, actual Java executable and flags
(not the terminal default), mod list, renderer/shader/optimization mods,
world and reproduction steps, session timestamps.

### 3. Timeline, then branch

Build a compact timeline: startup → mod phases → resource reload → world
load → first relevant warning → first exception/OOM/deadlock → cascade and
exit. First causally relevant failure wins, not the last scary line. Group
repeats by count instead of pasting them.

Then read exactly one reference and proceed:

- Crash, startup, loader, mixin, linkage, registry, world/data, native,
  OOM, hang → [2](references/2-crash.md).
- FPS, frame time, startup timing, tick lag, memory, GC, JFR, thread
  dumps → [3](references/3-performance.md).

External research (mod trackers, release notes, loader docs) needs exact
MC/loader/build match and a date. Community posts guide, never confirm.

### 4. Hypotheses

Per leading hypothesis write: **Claim** (mechanism), **Evidence for**
(path:lines, metric, node), **Against / alternatives**, **Confidence**,
**Test** (smallest differentiating check), **Expected result** (what moves
if right, what weakens it). "Mod X in stack" is a clue, not proof — the
thrower may be vanilla fed a bad value upstream.

### 5. Recommend and report

Order by information value and risk: no-change checks → one-variable
isolation on a copy → targeted measurement → mod-group search with backup
→ config/version change with rollback. Per action: change, rationale,
expected observation, success criterion, rollback and save risk. Benchmarks
hold workload, world, settings, JVM, and warm-up constant; report medians
and tails, not one lucky frame.

Report shape: **Verdict** → **Evidence** (paths, lines, metrics, why they
matter) → **Confidence + scope** (inspected vs missing) → **Action plan**
(ranked, reversible) → **Next capture** (exact artifact + safe method, only
if needed). Small excerpts only; never fabricate trees, percentages, links,
or results.

## Sub-agents

Only when the runtime offers them and parallel streams exist (crash line,
profile, JVM, compatibility). Inventory first, delegate one bounded question
with exact paths per worker, demand evidence-backed findings with
uncertainty. Re-open every cited line yourself; consensus is not proof.
Quick: none. Standard: at most one check. Deep/Forensic: two or three
non-overlapping roles.

## References

- [1 — finding artifacts](references/1-artifacts.md): where to look, search
  priority, safe reading, privacy.
- [2 — crashes and compatibility](references/2-crash.md): signatures, chains,
  version checks, minimal tests, mixins, native, memory.
- [3 — performance and the JVM](references/3-performance.md): Spark, Loading
  Profiler, client vs server, GC, hangs, controlled experiments.
