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
→ config/version change with rollback. Benchmarks hold workload, world,
settings, JVM, and warm-up constant; report medians and tails, not one lucky frame.

Report per ## Report below — no other shape.

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

## Report

Final message shape — fixed sections, fixed order. Goal: skimmable in 60
seconds, verifiable in 10 minutes. Short lines, short sentences, no prose
paragraphs.

### Verdict

Max 3 sentences: problem kind (crash / hang / FPS / tick / startup), largest
measured contributor, stability blocker if any. Name exactly one primary
hypothesis, and what would weaken it.

### Key metrics

Table first whenever numbers were captured — never bury Spark/JVM/TPS/MSPT
numbers in prose. Values are measured or `n/a (missing)`, never inferred.
Plain GitHub-flavored pipe tables only (runtimes like OhMyPi/CloudCode agents
render them formatted), no HTML.

| Metric | Value | Why it matters |
|---|---|---|
| TPS (1m / 5m / 15m) | 20.0 / 19.0 / 19.7 | ≥19 = tick-healthy, fault lies elsewhere |
| MSPT med / p95 / max | 3.1 / 7.3 / 1910 ms | max≫p95 = single hitches, not load |
| Heap used / max | 5.6 / 6.5 GB (85%) | >80% = GC pressure plausible |
| CPU process | ~32–37% | one saturated thread = CPU-side limit |
| Java | 25.0.1 (needs 21) | unsupported runtime = crash risk |

### Hotspots

Hottest measured contributors as a table when profiler data exists — ranked,
overlap noted (merge mode double-counts parents+children). One row per
mod/method, implicated config as `code`. No profile → skip the table, say
which capture would answer it.

| # | Source | Share | Hot method / setting | Meaning |
|---|---|---|---|---|
| 1 | neoforge | 38% | `GuiLayerManager.render()` 19% | GUI overlays dominate the frame |
| 2 | iris | 21% | `renderShadows()` 10% | shadow pass, `maxShadowRenderDistance=10` |
| 3 | sodium | 16% | `setupTerrain()` 6% | chunk rebuild cost |
| 4 | entity_model_features | 11% | `EMFModelPartVanilla.render()` 11% | custom entity models |

### Evidence

Bullets only, grouped: profile → crash → config → logs. Each bullet: source
path (or viewer link), one number or quoted line, what it proves. Group
repeats by count (`994× …`), never paste stacks or log walls. Every number
here MUST also appear in Key metrics or Hotspots — no orphan data.

### Confidence + scope

Table, one row per claim: `Confirmed` / `Strongly supported` / `Plausible` /
`Unresolved`, tied to path:line / metric / node. End with a `Missing:` line
(which capture flips each Plausible/Unresolved) and a `Did not:` line (game
not run, nothing changed — if true).

| Claim | Confidence | Basis |
|---|---|---|
| Render-bound, not TPS-bound | Strongly supported | MSPT max 1910 ms at TPS 20 |
| F3/GUI share inflated | Plausible | profile had GUI open 2.6% |
| Leak | Unresolved | no repeated heap samples |

### Action plan

Numbered table, cheapest information per risk first. Verify and Rollback
columns are REQUIRED: every step states the exact metric that moves plus its
target, and how to undo the change.

| # | Change | Why | Verify (metric → target) | Rollback |
|---|---|---|---|---|
| 1 | Java 25 → 21 (`instance.cfg`) | DH native crash | next start: no `UnsatisfiedLinkError` | revert `JavaPath` |
| 2 | DH LOD radius 256 → 128 | shadow/terrain load | `renderShadows()` < 5% | restore `.toml` |
| 3 | EMF+ETF features off | ~20% CPU combined | both < 2% in Spark | re-enable mods |

### Next capture

Only if needed: exact command + exact duration + exact condition (e.g.
`/spark profiler`, 2–3 min, no GUI open), then what comparison decides the
next step. One variable per capture, never batched changes.

### Rules for all of the above

- Tables are real GitHub-flavored Markdown, 3–7 rows each; prose never
  carries numbers alone.
- Redact secrets in paths/quotes (tokens, IPs, usernames). No uploads or
  public viewer links without permission.
- Small excerpts only; never fabricate trees, percentages, links, results.
- Same data once: a number lives in exactly one table, referenced — not
  repeated — elsewhere.
