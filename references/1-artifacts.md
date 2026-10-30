# 1 — finding artifacts

- [reconnaissance vs inventory](#reconnaissance-vs-inventory)
- [where to look](#where-to-look)
- [what to look for](#what-to-look-for)
- [profiler and tool discovery](#profiler-and-tool-discovery)
- [building the inventory](#building-the-inventory)
- [pinning the right run](#pinning-the-right-run)
- [reading safely](#reading-safely)
- [privacy](#privacy)

## Reconnaissance vs inventory

Two distinct passes. Never merge them.

**Pass 1 — reconnaissance (Stage 1, before depth selection).** Cheap,
read-only, inside the supplied scope only. Goal: just enough to let the
user pick Quick / Standard / Deep / Forensic. Inspect at most:

1. Minecraft version + loader/version from launcher metadata, manifests,
   or log headers.
2. Mod count + broad categories (profiler/diagnostic, performance
   optimization, renderer/shader/chunk/LOD, other relevant).
3. Profiler/diagnostic mods present: Spark, Loading Profiler, other
   clearly identified profiling mods — with versions.
4. Existing evidence files present (names + timestamps, not full reads):
   `*.sparkprofile`, `*.jfr`, `*.hprof`, thread dumps, Loading Profiler
   outputs, recent logs/crash reports.
5. External tools via `command -v` or equivalent only
   (`visualvm`, `jmc`, `jcmd`/`jstack`/`jmap`/`jps`, `asprof`, `perf`,
   `hotspot`). No filesystem crawl, no install, no launch.
6. OS/architecture context only when directly available and relevant.

Forbidden in reconnaissance: reading every log in depth, attaching to a
JVM, opening VisualVM, starting Spark/JFR/dumps, installing anything,
launching Minecraft, guessing paths, or crawling outside the supplied
directory. Report, then ask the single depth question.

**Pass 2 — inventory (Stage 3, after depth selection).** Depth-appropriate:
Quick reads only the relevant excerpt; Standard does a focused inventory;
Deep/Forensic do the complete relevant inventory plus a session ledger
(artifact → session/date mapping, historical items marked).

## Where to look

Start from the exact supplied path. It may be the instance root, the game
directory (`minecraft/` or `.minecraft/`), a logs folder, or an exported
pack. If `instance.cfg` or `mmc-pack.json` sits in the parent, that parent
is the instance root — include its metadata. Layout varies by launcher and
user choice; never assume a fixed structure. Without a supplied path, ask
for it first — never go looking for instances on your own. The only
permitted parent expansion is that single launcher-metadata parent; no
other out-of-scope traversal.

## What to look for

Search in priority order, stopping when the evidence suffices for the
chosen depth. Recurse into nonstandard mod-generated directories
(`profile/`, `diagnostics/`, `reports/`, `config/*/`) by name, timestamp,
and content — never assume a fixed path.

1. Session logs: `logs/latest.log`, `logs/debug.log`, rotated `*.log.gz`,
   launcher/game output logs.
2. Disconnect reports: `debug/disconnect-*.txt` — client packet/kick
   analysis, often richer than the log tail.
3. Crash reports: `crash-reports/crash-*.txt` (client and server variants).
4. JVM fatal logs: `hs_err_pid*.log`, `replay_pid*.log`.
5. Startup timing: `logs/profiler/loading-*.txt` (Loading Profiler output —
   confirm exact filename/path per installed version).
6. Profiler captures: `*.sparkprofile`, `*.jfr`, `*.hprof`, thread dumps, GC
   logs, VisualVM snapshots, timing reports.
7. Mod-generated diagnostics: Crash Assistant output under
   `logs/crash_assistant/` or `local/crash_assistant/`, plus any directory or
   file matching `*crash*`, `*report*`, `*profile*`, `*diagnos*`, `*dump*`.
8. Mod list: `mods/` JAR filenames plus pack manifest
   (`modrinth.index.json`, `manifest.json`, lockfiles) and loader metadata
   (`instance.cfg`, `mmc-pack.json`) for exact versions.
9. Env/config metadata: loader banner inside the log, launcher instance
   config, resource/shader-pack identity and version (only when relevant to
   the symptom), JVM command line where recorded.
10. Configs: only the ones implicated by evidence, never the whole `config/`
    tree.

Notes:

- `mods/*.jar.disabled` files are signal: someone already suspected that mod.
  Ask why before drawing conclusions.
- Don't paste hundreds of `mods/*.jar` entries into the report — a count plus
  versions suffices unless a specific mod is implicated.
- A mod JAR filename may not match its internal version; prefer
  `META-INF/mods.toml`, `neoforge.mods.toml`, `fabric.mod.json`, or
  loader-reported metadata when versions matter.
- A performance optimization mod is not automatically a profiler, and a
  profiler is not automatically an optimization. Never classify by the word
  "performance" in a title — verify what the mod does.
- Names are hints, not a schema. Artifacts may be renamed, compressed,
  exported, or saved outside the instance.

## Profiler and tool discovery

Distinguish three classes and report each with a confidence state:

- **Minecraft-aware profilers:** Spark (`/spark` vs `/sparkc` depends on
  installed version/platform — check help), Loading Profiler
  (startup-only, intrusive). State exact mod version + MC/loader pair.
- **JVM tools:** VisualVM, JMC/JFR (`jcmd`, `jstack`), async-profiler.
  State `found on PATH` / `not found on PATH` / `not checked`.
- **OS tools:** Linux `perf`, KDAB Hotspot. Same three states; note
  permission/kernel constraints when relevant.

A missing PATH entry is "not detected by this check", never "not
installed". Missing optional tools never block diagnosis — record the
limitation and continue with available evidence.

## Building the inventory

Do not create inventory scripts or helper-script projects. Use the
filesystem and shell tools at hand (or file search/list/read facilities
without terminal access, stating the limitation). Record per important
artifact:

- path, modification time, apparent session/date, type;
- whether it is complete or truncated/rotated;
- which question it answers (timeline anchor, crash chain, profile window,
  config claim, version proof).

One row per artifact is enough. Prefer the session that reproduces the
problem; label everything else `historical`. When several sessions exist,
never silently combine them. Forensic runs additionally keep a shared
evidence ledger with stable labels/paths per artifact.

## Pinning the right run

`latest.log` may belong to a later successful start, and a crash can occur
before it is finalized. Correlate file modification times, in-log session
banners, and the user's described action. Prefer one consistent event
sequence over a single timestamp. Metrics from one date and a crash from
another are two evidence items — they never form one causal event without a
demonstrated session link.

## Reading safely

List candidates first, then read targeted line-numbered windows. A triage
search is an aid, not proof — many healthy logs contain the word `error`,
and some failures use none of these tokens:

```bash
rg -n -i "(exception|error|fatal|failed|caused by|outofmemory|mixin|incompatible|deadlock)" logs crash-reports debug
```

Skip by default: `assets/`, `libraries/`, `natives/`, caches, shader caches,
`screenshots/`, `backups/`, `saves/` region data, world blobs. Revisit an
excluded tree only on specific suspicion. State unreadable or skipped files
explicitly — never treat skipped data as inspected.

## Privacy

Logs, dumps, and profiles can hold usernames, absolute paths, server
addresses, IPs, tokens, world names, and mod lists. Redact secrets in
excerpts. No uploads or public viewer links without explicit permission. Heap
dumps and JFR stay local.
