<div align="center">

# Minecraft Debugging Skill

**Drop this skill into your local agent to debug large Minecraft modpacks.**

![](https://img.shields.io/badge/minecraft-java_edition-16a3da?style=flat-square&labelColor=070e15)
![](https://img.shields.io/badge/license-MIT-3b4250?style=flat-square&labelColor=070e15)

</div>

A large modpack spreads its evidence across logs, crash reports, and
profiler output. This skill gives your agent a fixed workflow for reading
it: wait for the instance path, run a cheap reconnaissance pass, agree on
an analysis depth, then follow one of three pipelines — and report bottom
line plus the one next test that settles the uncertainty.
Works with Forge, NeoForge, Fabric, and Quilt, in any launcher layout.

## What it does — and does not

It diagnoses crashes, startup/loading failures, FPS stutter, tick lag,
memory/GC pressure, and mod compatibility from the instance you point it
at, using logs, crash reports, Spark profiles, Loading Profiler output, and
JVM evidence. It does not scan your computer for modpacks, install or
change anything on its own, or upload your data anywhere. Every invasive
step — live profiling, JVM attach, heap dumps, instance changes, uploads —
needs your explicit approval first.

## The path gate

Nothing happens without an instance path. If you haven't supplied one, the
agent asks once and stops — no searching `/`, no home-directory crawl, no
launcher-library enumeration. Paste the instance root or the
`minecraft/` / `.minecraft/` game directory inside it. Prism Launcher:
right-click instance → Folder; Modrinth / CurseForge / FTK App: instance
settings → installation folder; vanilla: `.minecraft/`.

Once you supply the path, the agent runs a small read-only reconnaissance
pass (Minecraft/loader versions, mod categories, Spark/Loading Profiler
presence, existing evidence files, detectable external tools) and reports a
compact summary. No JVM attach, no profiling, no deep log reading — just
enough to pick the right depth.

## Four depths, three pipelines

> How deep should I investigate? **Quick**, **Standard**, **Deep**, or **Forensic**?

| Depth | Pipeline | What you get |
|---|---|---|
| **Quick** | A — lightweight, minimal | Triage from existing evidence. One leading explanation, confidence, what is unproven, one next test. No new capture. Not a full audit. |
| **Standard** | A — lightweight, full | Normal diagnosis: focused inventory, pinned session, Spark-first analysis, at most one targeted capture. |
| **Deep** | B — sequential, multi-source | Multi-source investigation with controlled comparison and a consistency pass. One complementary tool per open question. |
| **Forensic** | C — multi-agent (or B sequentially without sub-agents) | Bounded parallel workstreams, evidence ledger, lead synthesis, ≤2 follow-up loops, independent review. |

## Which profiler answers which question

The agent never runs every profiler — it picks the minimum matching path:

- **Crash / incompatibility** → exception chain + logs + versions (Spark only if runtime evidence matters).
- **Low FPS / stutter** → client Spark + frame-time distribution; GPU-side evidence stays GPU-side.
- **Tick lag / TPS** → server Spark + tick path.
- **Startup time** → phase timestamps + Loading Profiler (if safe).
- **Memory / GC** → VisualVM / JFR + post-GC occupancy (one high heap % is not a leak).
- **Hang** → repeated thread dumps, not a CPU profile.

**Spark** is the primary Minecraft-aware profiler. **Loading Profiler** is
an optional, intrusive, startup-only specialist — never for runtime FPS,
never on a valued world. **VisualVM** and **JFR / JMC** are optional JVM
tools for CPU/GC/allocation/lock questions. **async-profiler** and Linux
**perf / Hotspot** are escalation paths for specific unanswered questions,
never defaults.

## The pipelines

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/workflow-simple-dark.svg" />
  <img src="assets/workflow-simple-light.svg" alt="Pipeline A: path gate, reconnaissance, depth choice, targeted evidence, optional capture, verification, report" width="860" />
</picture>

*Pipeline A — Quick stops when existing evidence suffices; Standard may add one bounded local capture.*

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/workflow-deep-dark.svg" />
  <img src="assets/workflow-deep-light.svg" alt="Pipeline B: path gate, reconnaissance, full inventory with session lock, Spark analysis, one complementary capture, correlation, controlled comparison, report" width="860" />
</picture>

*Pipeline B — Deep adds full inventory, one complementary tool per unresolved hypothesis, and a controlled comparison.*

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/workflow-forensic-dark.svg" />
  <img src="assets/workflow-forensic-light.svg" alt="Pipeline C: lead-owned path and session ledger, bounded parallel investigators, synthesis, contradiction check, bounded follow-up, independent review, report" width="860" />
</picture>

*Pipeline C — Forensic runs bounded parallel workstreams under a lead, reconciles disagreement, and audits the draft before reporting.*

<details>
<summary><b>How it works</b></summary>

- Wait for the instance path — no scanning for modpacks.
- Reconnoitre cheaply, then ask exactly one depth question.
- Inventory the evidence with timestamps and session binding — then pin
  the run by correlation, not filename.
- Route by symptom to the minimum matching profiler; verify versions,
  settings ownership, and measurement limits.
- Report bottom line, evidence, what is not proven, ranked reversible
  steps, and the one next capture that settles the uncertainty.
</details>

<details>
<summary><b>Safety and privacy</b></summary>

Read-only by default. The agent never installs, removes, or edits mods,
configs, JVM flags, worlds, or evidence without your explicit approval,
and never uploads logs, profiles, or dumps. Logs can leak usernames,
paths, server addresses, and tokens — excerpts are redacted and kept local.

</details>

<details>
<summary><b>Install</b></summary>

```bash
git clone https://github.com/Malte-Dzierzon/minecraft-debugging-skill.git
cd minecraft-debugging-skill
./install.sh
```

Symlinks the payload (`SKILL.md` + `references/`) into
`~/.omp/agent/skills/minecraft-debugging-skill/`, so a later `git pull`
updates the installed skill. Other agents:

```bash
./install.sh --agent claude   # ~/.claude/skills/
./install.sh --agent codex     # ~/.codex/skills/
./install.sh --all            # every agent dir that already exists
```

`--copy` copies instead of linking, `--dry-run` previews, `--uninstall`
removes. Only the payload is installed — repo docs stay here. Reload the
agent afterwards.

</details>

<details>
<summary><b>Repository layout</b></summary>

- `SKILL.md` — the skill: path gate, reconnaissance, depths, pipelines, report shape.
- `references/1-artifacts.md` — reconnaissance vs inventory, session pinning, privacy.
- `references/2-crash.md` — crash signatures, log triage, compatibility, minimal tests.
- `references/3-performance.md` — symptom→tool matrix, Spark, Loading Profiler, JVM tools, capture protocol.
- `references/4-verification.md` — setting ownership, LOD/shader/Java rules, source hierarchy.
- `tests/EVALUATIONS.md` — maintainer acceptance scenarios.
- `install.sh` — payload installer for local agents.

</details>
