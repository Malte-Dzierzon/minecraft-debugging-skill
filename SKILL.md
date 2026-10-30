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

## Stage 0 — Path gate (all depths, mandatory)

No instance path, no diagnosis. NEVER scan the computer for modpacks or
instances: no filesystem-wide search, no `find /`, no home-directory crawl,
no launcher-library enumeration to "find something to work on".

1. **Path supplied → use exactly that path.** The only permitted expansion
   is the immediate parent when it holds `instance.cfg` / `mmc-pack.json`
   (instance root with game dir inside). Everything else stays out of scope.
2. **No path supplied → STOP and ask before doing anything else.** No file
   listing, no searching, no theorizing, no depth question yet. The path
   question outranks everything below.

Ask once, concretely:

> I need your instance/modpack folder path to start — e.g. `/home/xealom/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances/Server Modpack/minecraft`. Prism Launcher: right-click instance → Folder; Modrinth App / CurseForge / FTB App: instance settings → installation folder; vanilla: `.minecraft/`. Paste the path here — instance root or the `minecraft/` / `.minecraft/` game directory inside it both work.

## Stage 1 — Reconnaissance (cheap, read-only, no capture)

After a usable path arrives, validate it (exists, is a directory; classify
as game dir / instance root / exported pack / logs subdirectory / invalid)
and run a **small reconnaissance pass** inside the supplied scope only.
Its purpose is to let the user pick the right depth — it is not the
diagnosis. Never attach to a JVM, start a profile, install a tool, or read
every log in depth here. See [1](references/1-artifacts.md).

Report compactly, then stop:

- instance path and how it resolved;
- Minecraft version / loader (from launcher metadata, manifests, log
  headers — never jar names alone when identity is ambiguous);
- mod count plus broad categories: profiler/diagnostic, performance
  optimization, renderer/shader/chunk/LOD, other relevant (an optimization
  mod is not automatically a profiler and vice versa);
- Spark present/absent (+ version); Loading Profiler present/absent (+ version);
- existing evidence files present (not yet read in depth): `*.sparkprofile`,
  `*.jfr`, `*.hprof`, thread dumps, Loading Profiler outputs, recent
  logs/crash reports;
- external tools via `command -v` or equivalent only
  (`visualvm`, `jmc`, `jcmd`/`jstack`/`jmap`/`jps`, `asprof`, `perf`,
  `hotspot`) — report `found on PATH` / `not found on PATH` /
  `not checked`. A missing PATH entry means "not detected by this check",
  never "not installed" (desktop/Flatpak launchers may hide commands).

## Stage 2 — Depth selection

Ask exactly one question, unless depth was already given or the user asked
for an immediate diagnosis (then respect it, never re-ask):

> How deep should I investigate? **Quick**, **Standard**, **Deep**, or **Forensic**?

- **Quick → Pipeline A (minimal).** Triage from existing evidence only. No
  new live capture by default. One leading explanation + confidence + what
  is unproven + one next test. Explicitly not a full audit.
- **Standard → Pipeline A (full).** Normal diagnosis: focused inventory,
  pinned session, symptom routing, Spark first when applicable, at most one
  targeted capture + limited verification.
- **Deep → Pipeline B.** Multi-source sequential investigation with
  controlled comparison and an explicit consistency pass.
- **Forensic → Pipeline C** (or B sequentially when the runtime has no
  sub-agents — state which ran). Bounded parallel workstreams, evidence
  ledger, lead synthesis, targeted follow-ups, independent review.

Quick stops early when evidence suffices; Standard may add one measurement;
Deep answers each open question with one capture; Forensic follows the
sub-agent protocol below. Never run every profiler for every problem.

## Rules

1. **Inspect before theorizing.** Enumerate files first; never assume only
   `latest.log` matters.
2. **Read-only by default.** Never delete, edit, move, or overwrite
   evidence. Consent gates: Spark capture, JVM attach (`VisualVM`/`jcmd`),
   JFR/async-profiler recording → ask first unless explicitly requested;
   heap/core dumps and instance modification → explicit approval with
   disk/privacy/pause costs stated; any upload or public viewer link →
   separate explicit approval. A permission for one named capture never
   authorizes unrelated tooling.
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

## Stage 3–4 — Inventory, symptom routing

Open [1](references/1-artifacts.md) for the depth-appropriate inventory
(Quick: relevant excerpt only; Standard: focused; Deep/Forensic: complete +
session ledger). Pin one target session; separate historical artifacts.

Then classify the symptom **before** choosing tools — minimum matching
evidence path wins. Full matrix in [3](references/3-performance.md):

- **Crash / startup failure / incompatibility** → first exception + full
  `Caused by` chain, crash report + `latest.log`/`debug.log`, loader/mod
  versions, mixin target/phase, fatal log if native. Spark only if runtime
  evidence is relevant; Loading Profiler only for startup durations where
  the game reaches the report.
- **Low FPS / stutter** → client Spark (correct client command) + thread
  call trees + frame-time distribution over a repeatable window + GPU-side
  signal if the GPU hypothesis is material. Never infer GPU execution from
  Java samples; never use server MSPT/TPS for a client render diagnosis.
- **Server tick lag / TPS / MSPT** → server Spark + tick path (+ long-tick
  filter when supported). In single-player, separate logical-server and
  client/render threads despite one shared JVM.
- **Startup / loading time** → phase timestamps + Loading Profiler where
  installed, supported, and safe (duplicate instance, never a valued world)
  + cold/warm repeats. Never substitute Spark runtime data for startup cost.
- **Memory / GC / leak** → VisualVM graphs / JFR GC+allocation / repeated
  post-GC occupancy; dump/histogram only as escalation with approval.
  One high heap % is not a leak — require retained growth.
- **Hang / freeze** → 2–3 thread dumps seconds apart + lock ownership +
  state progression. `WAITING`/`PARKED` pools are not deadlocks; a CPU
  profile alone is not a deadlock diagnosis.
- **Network lag** → ping/packet symptoms + server-side tick/network +
  disconnect reports. Healthy TPS ≠ healthy network; poor FPS ≠ lag.

Tool choice follows the question, not the depth. Extra captures need a
stated unresolved question; stop when evidence suffices.

## Stage 5 — Evidence interpretation

Read exactly one reference and follow it:

- Crash, startup, loader, mixin, linkage, registry, world/data, native,
  OOM, hang → [2](references/2-crash.md).
- FPS, frame time, startup timing, tick lag, memory, GC, JFR, thread
  dumps → [3](references/3-performance.md) (tool selection, capture
  protocol, baseline record, experiment ledger, statistics discipline).

Spark ([3](references/3-performance.md)): record side, verified command
variant, capture type/mode/window/interval/thread selection, and whether
the symptom occurred before quoting any number. Inclusive/overlapping paths
double-count — never sum them. Sample share ≠ wall/CPU/GPU time. Default
interval first; thread filters only after real thread names; all-thread
only for contention questions. Keep captures short (≈60–120 s
representative workload) and local (`--save-to-file` where supported —
verify against installed help; never paste version-unverified syntax).

Loading Profiler is startup-only, intrusive, attribution-by-code-usage
(resource/mixin/bridged mods may count as vanilla), and must never load a
valued world. VisualVM: monitor overview first, sampling before
instrumentation, dumps only for matching hypotheses. JFR: `default.jfc`
first, `profile.jfc` only for a concrete detailed-data question.

Logs/crash reports: first relevant exception + full `Caused by` chain, not
the last line or largest repeat count. Group repeats with one stack,
phase, and consequence.

## Stage 6 — Verification

Open [4](references/4-verification.md) before recommending any setting,
runtime, or version change. Confirm owner/reader/file/status per key
(`verified` vs `inferred`); exact MC/loader/mod/Java + release requirements
from primary sources (record URL, version/date, claim supported); stale or
similarly-named-version docs excluded. A JNI `UnsatisfiedLinkError` is a
native binding/load mismatch until a supported-runtime repro or release
doc settles it. Run the consistency pass: valid denominators? one session?
another subsystem explains it? GPU claim from Java-only data? heap % called
a leak? class/mod name treated as guilt? Loading Profiler attribution
over-read? causal language earned?

## Stage 7 — Hypotheses, one change at a time

Per finding write: **Observation** (exact value, message, method,
timestamp, path), **Interpretation** (what it supports and does not),
**Confidence**, **Alternative** (at least one where ambiguous),
**Discriminator** (smallest distinguishing test/artifact), **Expected
result** (what moves confidence up or down). Causal language
("caused by", "root cause", "bottleneck", "incompatible") only with a
direct failure chain, reproducible isolation, authoritative exact-version
documentation, or multiple converging independent observations — otherwise
"correlates with" / "consistent with" / "not yet established".

Order by information value and risk: no-change checks → one-variable
isolation on a copy → targeted measurement → mod-group search with backup
→ config/version change with rollback. Per change state: exact file/UI
path, current value only if verified, proposed value or test action,
expected measurable effect, risks/trade-offs, rollback path, and the
metric to recapture. Never invent config paths or keys. Workload, world,
settings, JVM, warm-up constant; report medians and tails, never one lucky
frame; inconclusive deltas stay "inconclusive".

## Forensic sub-agent protocol (Pipeline C only)

Only when the runtime offers parallel workers. The lead completes
Stages 0–1, inventory, session lock, evidence ledger, and the target
question first, then delegates bounded questions — never "analyze
everything". Spawn only relevant roles (usually 3 investigators + 1
reviewer, never all five by default): session/log, Minecraft profiler,
JVM/system, compatibility/source researcher, independent reviewer.

Every worker receives: exact bounded question, artifact paths/IDs, target
session/window, relevant versions, prohibited assumptions/actions, and this
result schema: worker/role, question, artifacts reviewed, session/window,
confirmed observations (path/line/method/metric/source), interpretation,
confidence, alternative explanations, what the evidence does NOT establish,
recommended discriminating test, missing evidence/limitations, sources
(exact version/date/URL).

First wave runs independent analyses only. Lead synthesizes (one timeline,
session reconciliation, disagreement, rejected attribution,
evidence-vs-interpretation, top open question, one follow-up). At most two
targeted follow-up loops with a clear question + exit condition each.
Reviewer audits the draft (session mixing, percentage arithmetic, thread
identity, GPU-from-Java, heap-as-leak, name-as-guilt, Loading Profiler
limits, version claims, causal language, rollback/consent, privacy); the
lead resolves every challenge on record.

## Report

Fixed sections, fixed order. Tune detail to depth, keep every section when
relevant. Skimmable in 60 seconds, verifiable in 10 minutes. Short lines,
no prose paragraphs carrying numbers alone. Redact secrets; small excerpts
only; never fabricate trees, percentages, links, or results; each number
lives in exactly one table, referenced — not repeated — elsewhere.
Every proposed change carries file/UI location (verified only), current
value (read only), proposed change, reason + evidence, expected metric
movement, success criterion, risks/trade-offs, backup/rollback.

### 1. Bottom line

Primary symptom plus leading supported explanation with confidence.
Explicitly say what is not yet known and what is not proven. 3–4 sentences.

### 2. Scope and environment

Selected depth/pipeline, instance, MC/loader/Java, client/server, pack
context.

### 3. Tools and evidence reviewed

Detected/used/unavailable tools, artifacts + session windows, Spark
command/capture details, VisualVM/JFR settings, Loading Profiler
presence/absence. Name important missing evidence; flag `historical`.

### 4. Timeline

Only when chronology matters; separate historical sessions.

### 5. Findings

Observations separated from interpretations, with paths:lines, method
names, values, source links. Tables only where they improve comparison —
never an undifferentiated mod list, never log verbatim, never folklore.
Key metrics: metric | value | why it matters (measured or `n/a (missing)`,
never inferred). Hotspots (profiler data only): one row per mod/method,
overlap noted; no profile → skip, name the capture that would answer it.
Plain GitHub-flavored pipe tables, no HTML.

### 6. What the evidence does not prove

Alternatives and unsupported assumptions — one line each with the settling test.

### 7. Prioritized next steps

Low-risk, reversible, one change at a time, each tied to a measurable
target and rollback.

### 8. Next capture / exact experiment

Only the artifact or experiment settling the leading uncertainty: exact
command, duration, conditions, output path, success criterion.

### 9. Sources

Exact URLs with release/version dates for externally researched claims.

## References

- [1 — finding artifacts](references/1-artifacts.md): reconnaissance vs
  inventory, where to look, search priority, session pinning, safe reading,
  privacy. Open at Stage 1, again at Stage 3.
- [2 — crashes and compatibility](references/2-crash.md): signatures, chains,
  log triage, version checks, minimal tests, mixins, native, memory. Open for
  any crash/startup/hang/exception.
- [3 — performance and the JVM](references/3-performance.md): symptom→tool
  matrix, Spark semantics, Loading Profiler safety, VisualVM, JFR/JMC,
  async-profiler, perf/Hotspot, capture protocol, statistics. Open for any
  FPS/tick/startup-timing/memory question.
- [4 — verification and sources](references/4-verification.md): setting
  ownership, LOD/shader/Java/native rules, source hierarchy, citation format.
  Open before any setting/runtime/version claim (Stage 6).
