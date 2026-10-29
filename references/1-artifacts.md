# 1 — finding artifacts

- [where to look](#where-to-look)
- [what to look for](#what-to-look-for)
- [pinning the right run](#pinning-the-right-run)
- [reading safely](#reading-safely)
- [privacy](#privacy)

## Where to look

Start from the exact supplied path. It may be the instance root, the game
directory (`minecraft/` or `.minecraft/`), a logs folder, or an exported pack.
If `instance.cfg` or `mmc-pack.json` sits in the parent, that parent is the
instance root — include its metadata. Layout varies by launcher and user
choice; never assume a fixed structure. Without a supplied path, ask for it
first — never go looking for instances on your own.

## What to look for

Search in priority order, stopping when the evidence suffices for the chosen
depth:

1. Session logs: `logs/latest.log`, `logs/debug.log`, rotated `*.log.gz`.
2. Disconnect reports: `debug/disconnect-*.txt` — client packet/kick
   analysis, often richer than the log tail.
3. Crash reports: `crash-reports/crash-*.txt` (client and server variants).
4. JVM fatal logs: `hs_err_pid*.log`, `replay_pid*.log`.
5. Startup timing: `logs/profiler/loading-*.txt` (Loading Profiler output).
6. Profiler captures: `*.sparkprofile`, `*.jfr`, `*.hprof`, VisualVM
   snapshots, timing reports.
7. Mod-generated diagnostics: Crash Assistant output under
   `logs/crash_assistant/` or `local/crash_assistant/`, plus any directory or
   file matching `*crash*`, `*report*`, `*profile*`, `*diagnos*`, `*dump*`.
   Never assume a fixed path — discover by name, content, and timestamp.
8. Environment: launcher config, pack manifest (`modrinth.index.json`,
   `manifest.json`), mod list, loader banner inside the log.
9. Configs: only the ones implicated by evidence, never the whole `config/`
   tree.

Notes:

- `mods/*.jar.disabled` files are signal: someone already suspected that mod.
  Ask why before drawing conclusions.
- Don't paste hundreds of `mods/*.jar` entries into the report — a count plus
  versions suffices unless a specific mod is implicated.
- A mod JAR filename may not match its internal version; prefer
  `META-INF/mods.toml`, `neoforge.mods.toml`, `fabric.mod.json`, or
  loader-reported metadata when versions matter.
- Names are hints, not a schema. Artifacts may be renamed, compressed,
  exported, or saved outside the instance.

## Pinning the right run

`latest.log` may belong to a later successful start, and a crash can occur
before it is finalized. Correlate file modification times, in-log session
banners, and the user's described action. Prefer one consistent event sequence
over a single timestamp.

## Reading safely

List candidates first, then read targeted line-numbered windows. A triage
search is an aid, not proof — many healthy logs contain the word `error`, and
some failures use none of these tokens:

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
