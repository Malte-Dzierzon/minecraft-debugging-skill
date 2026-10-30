# 3 — performance and the JVM

- [symptom→tool matrix](#symptomtool-matrix)
- [spark — primary minecraft profiler](#spark--primary-minecraft-profiler)
- [spark capture procedure](#spark-capture-procedure)
- [reading spark numbers](#reading-spark-numbers)
- [loading profiler — startup only](#loading-profiler--startup-only)
- [visualvm — optional local JVM GUI](#visualvm--optional-local-jvm-gui)
- [JFR and JMC — deep JVM events](#jfr-and-jmc--deep-jvm-events)
- [async-profiler — specialist escalation](#async-profiler--specialist-escalation)
- [linux perf and hotspot — OS-level](#linux-perf-and-hotspot--os-level)
- [client vs server](#client-vs-server)
- [JVM: runtime, GC, hangs](#jvm-runtime-gc-hangs)
- [capture protocol](#capture-protocol)
- [controlled experiments and statistics](#controlled-experiments-and-statistics)

## Symptom→tool matrix

One matching evidence path per symptom. Never run every profiler.

| Symptom | Primary tool | Complementary (one, on hypothesis) |
|---|---|---|
| Crash / startup failure / incompatibility | Exception chain + logs + version metadata ([2](2-crash.md)) | Spark only if runtime evidence is relevant |
| Low FPS / stutter | Client Spark + frame-time distribution | GPU-side signal (GPU hypothesis); VisualVM/JFR (CPU/GC/lock hypothesis) |
| Server tick lag / TPS / MSPT | Server Spark + tick path | Long-tick filter (intermittent, when supported) |
| Startup / loading time | Phase timestamps + Loading Profiler (if safe) | JFR/JMC or logs (concrete JVM/loader question only) |
| Memory / GC / suspected leak | VisualVM graphs / JFR GC+allocation / post-GC occupancy | async-profiler live/heap mode; MAT on existing/approved dump |
| Hang / freeze | 2–3 thread dumps + lock ownership | JFR thread/lock events |
| Network lag | Ping/packet + server tick/network evidence | — (healthy TPS never proves a healthy network) |

Missing tools never block diagnosis — record the gap and continue.

## Spark — primary minecraft profiler

Spark is the default domain-specific profiler for Minecraft runtime work
when installed and applicable. Command examples below are illustrative —
confirm the installed version's help and actual command prefix before use.

Rules:

1. Identify the target first: client, dedicated server, or integrated
   single-player server. Client installs may expose `/sparkc` instead of
   `/spark` on Forge/Fabric; dedicated servers use their applicable
   `/spark`. Never blindly apply a client command to a server or vice versa.
2. Check the installed Spark version and command help before relying on any
   flag. Support and syntax differ across versions and platforms.
3. Record capture conditions before interpreting: MC/loader/mod versions,
   JVM, side, world/server, location, action, shaders/resource packs,
   GUI/F3/overlay state, render/simulation distance, sample window,
   interval, selected threads, whether the symptom occurred.
4. Prefer the default sampling interval initially; changing it changes
   granularity and overhead. Tune only to answer a specific question.
5. Choose thread filters only after identifying actual thread names (a
   `Render thread` name is common but not guaranteed). All-thread profiles
   suit cross-thread contention questions only — not automatically better.
6. For intermittent tick issues, use long-tick filtering only when the
   installed version supports it, with a threshold justified by the symptom.
7. Keep captures short and reproducible: typically ~60–120 s of
   representative workload, then adapt to symptom and sample rate.
8. Preserve the profile locally when supported — current Spark docs describe
   `/spark profiler stop --save-to-file` under the config directory. Verify
   against installed help/version.
9. Never upload profiles to a public viewer or share viewer URLs without
   explicit user permission.
10. Never interpret `.sparkprofile` as plain text. Use the official
    viewer/export or a verified parser. If it cannot be decoded, say so.

```text
/sparkc profiler info
/sparkc profiler start --timeout 90
/sparkc profiler stop --save-to-file
```

## Spark capture procedure

1. Verify the command prefix and `profiler` subcommand from installed help.
2. Confirm side (client vs server) and thread targets.
3. Start with a bounded duration (`--timeout`) covering the symptom window.
4. Keep workload representative: no open menus/inventories/F3/shader
   screens unless the menu itself is the symptom.
5. Save locally; note the output path.
6. Record the full baseline entry (see [capture protocol](#capture-protocol)).

Ask before starting live profiling unless the user explicitly requested it.
The request covers only the named capture and scope.

## Reading Spark numbers

Hard rules for reading Spark numbers correctly:

1. **Thread first.** Identify which thread/process was sampled before any
   claim. Total process CPU (e.g. 31–37%) never proves which thread limits
   the frame. "Render-thread-limited" needs the render thread hot, not a
   process percentage plus familiar method names.
2. **Inclusive vs exclusive.** Merged/overlapping call paths double-count
   parents and children. Never sum merged mod percentages into a combined
   cost (`11.42% + 9.09% ≈ 20.5%` is invalid unless the format's accounting
   makes it additive). State the denominator: samples, wall time, or thread
   time.
3. **Samples ≠ time.** A sample share is not wall-clock duration, exact CPU
   utilization, tick time, or GPU execution time without a valid denominator
   and documented semantics. Never convert a percentage into milliseconds.
4. **Distribution, not max.** A single extreme max (e.g. 1910 ms against a
   3.13 ms median and 7.27 ms p95) is a potentially important isolated hitch,
   not sustained lag. Correlate it with timestamps/events; report median,
   p95, max, duration, interval, and capture conditions together.
5. **GUI state.** Cost recorded with a menu, F3 overlay, or shader settings
   screen open (e.g. `GuiLayerManager.render()`, BetterF3, `mouseClicked()`
   frames) is not normal gameplay overhead. Ask for or capture a clean
   gameplay profile before ranking UI cost as an in-game cost.
6. **Hot ≠ broken.** A hot path is observed work, not proven waste —
   confirm against expected workload and a controlled change. Obfuscated
   names and heuristic class-substring rules can misclassify; inspect real
   stacks. A mod name in a hot frame is not a removal recommendation.
7. **GPU is unmeasured.** Spark samples Java-side work only. Shader/shadow
   cost, GPU frame time, and utilization need GPU-side evidence; never
   present a Java method share as GPU time.

## Loading profiler — startup only

Specialized startup/bootstrap/loading breakdown, not a general performance
profiler. Never use it for FPS, render-thread, tick, GC, or runtime lag.

1. Detect presence first: exact mod version, MC version, loader
   (Forge/NeoForge support varies by release), and whether that release
   supports the installed MC/loader pair. Re-check current releases at
   analysis time — never hard-code a compatibility list.
2. Confirm the actual report filename/path for that version from project
   docs/source or generated files.
3. Attribution is by code usage: resource loading (incl. block models),
   mixins, and Fabric mods loaded through Sinytra Connector can count as
   vanilla. Per-mod shares are a useful signal, not perfect accounting.
4. The project warns against loading existing worlds — the mod is intrusive
   and may be incompatible with some mods during world load. Treat as a
   hard safety rule: never load a valuable world with it installed.
5. Safe policy: explicit approval first; fresh startup capture only in a
   disposable duplicate instance (+ disposable test world only if world
   entry is necessary; prefer stopping at the title screen). Remove it from
   the duplicate afterwards; verify the original is untouched.
6. Compare multiple launches; separate cold from warm starts.
7. Never infer startup cost from Spark runtime data.

## VisualVM — optional local JVM GUI

First-class optional tool when available — live JVM CPU/heap/GC/thread
overview, not Minecraft-aware profiling. Good for users who prefer a visual
desktop UI.

1. Detect availability (`command -v` or equivalent); never assume it.
   Missing PATH entry = "not detected by this check", not "not installed".
2. Confirm the target Minecraft PID — distinguish it from Prism Launcher or
   other Java processes. Confirm runtime/JDK compatibility and same-user
   attach prerequisites.
3. Ask before attaching to the live Minecraft JVM (unless explicitly
   requested).
4. Monitor overview first: CPU, heap, GC activity, metaspace, loaded
   classes, thread counts.
5. Use sampling before instrumentation for a first profile —
   instrumentation adds significant overhead and is never the default.
6. Correlate the time window with the in-game symptom and any Spark capture.
7. Thread dumps only for hang/blocking hypotheses (repeat to show stable
   blocking). Heap dumps are invasive (large, pause, private data):
   explicit approval, disk space, local destination. A class histogram may
   answer the question without a full dump.
8. A live CPU/heap graph is context, not proof of which mod caused a
   problem. VisualVM complements Spark; it does not replace Minecraft-aware
   profiling and measures little of the GPU pipeline.

## JFR and JMC — deep JVM events

Preferred next step when the question concerns JVM behavior and Spark alone
cannot explain it. JFR records timestamped JVM events (CPU samples,
allocations, GC, latency, synchronization, thread behavior); JMC is the
desktop UI for `.jfr` recordings.

Templates — choose deliberately:

- `default.jfc`: low-overhead general recording. First capture when
  available; does not include every detailed allocation/heap statistic.
- `profile.jfc`: richer profiling data with additional overhead. Only when
  the extra detail answers a concrete question.

Safe workflow:

1. Detect the selected Minecraft Java process, not merely any Java process.
2. Check `jcmd` attach capability and runtime compatibility (`jcmd` should
   generally run as the same OS user). Check that version's `jcmd <pid>
   help` before use — exact subcommand syntax varies.
3. Ask before attaching/recording unless the consent policy's current rules
   or an explicit request cover it.
4. Prefer short bounded captures (commonly 30–120 s) during reproducible
   workload. Local `.jfr` path with a session identifier; never upload.
5. `default` first; `profile` deliberately with stated overhead reason.
6. Correlate GC pauses with symptom timestamps; inspect allocation samples,
   execution samples, thread parks/locks as the hypothesis requires — and
   only in a session shared with the symptom (no cross-session correlation).
7. Allocation rate ≠ retained memory ≠ leak. Use post-GC retained growth.

```bash
jcmd <MC_PID> JFR.start name=mc-debug settings=default duration=90s filename=/path/to/private/mc-debug.jfr
jcmd <MC_PID> JFR.check
```

Illustrative only — verify against the selected JDK and never paste with an
arbitrary PID. On attach failure, report the exact error and continue with
available evidence.

## Async-profiler — specialist escalation

Deep/Forensic only, when a specific question remains unanswered and the
tool fits the HotSpot-based runtime + OS/architecture. Never a general
Minecraft profiler replacement. Modes (CPU, allocation, live-object,
native-memory, lock, perf counters) are chosen per hypothesis, smallest
useful capture first (a CPU capture can be short with an HTML flame graph
export). Verify release, platform, Java compatibility, `perf_event`
constraints, output format; never change kernel perf settings, add
capabilities, or request elevated privileges automatically. Missing native
symbols or unresolved frames are reported, not papered over. Output stays
local.

## Linux perf and Hotspot — OS-level

Linux-only, when OS-level CPU/perf-counter context is genuinely required:

- `perf` gathers Linux performance samples and counters (kernel/permission
  constraints apply); KDAB Hotspot is a GUI for inspecting them.
- Neither replaces Spark's Minecraft-aware thread/call context.
- Native/JVM symbols may be incomplete without debug info.
- Never present Linux CPU samples as GPU execution time.
- Never weaken kernel security settings to make a profile work.

## Client vs server

- Render thread hot → rendering, chunk rebuilds, shaders, overlays, sync
  waits, mod/renderer compatibility.
- Tick thread hot → entities, block entities, worldgen, chunk load/save,
  pathfinding, server-side mod work.
- Low GPU use with one saturated thread → suspect a CPU-side or sync limit,
  then confirm rather than assume.
- Low CPU with poor frame time → blocking, caps, I/O, driver waits, power
  management, GPU-side limits.
- Good average FPS with visible stutter → examine the frame-time distribution
  (p95/p99), not the average.

## JVM: runtime, GC, hangs

Confirm the actual runtime first: the launcher's Java may differ from the
terminal's `java -version`. `jcmd <pid> VM.version` and `VM.command_line`
show what's really running — if a command fails, report it, don't infer.
Same user, compatible tooling, and attach support are prerequisites, not
assumptions. Live capture, heap dumps, and flag changes need permission.

- **GC pressure** is not "heap bar high." Signals that matter: allocation
  rate, occupancy after collection, pause time and frequency, promotion
  behavior, and whether a pause lines up with the visible hitch. Stable
  post-GC occupancy with short pauses is churn, not a leak — don't raise
  the heap as a default. Never force GC to make a graph look better.
- **Suspected leak** needs repeated measurements showing retained growth,
  not one high reading. Heap dumps are intrusive (size, pause, private
  data): consent, disk space, and a private destination first. A class
  histogram may answer the question without a full dump.
- **Hang** needs two or three dumps seconds apart. Idle `WAITING`/`PARKED`
  worker pools are normal — look for a lock cycle or the same stacks not
  progressing. A `sleep` in a stack may be intentional throttling.
- **JFR** can join CPU, allocation, GC, and lock data in one capture; check
  the runtime's event support and keep recordings short and local.
- VisualVM and similar tools complement but don't replace Minecraft-aware
  profiles, and measure little of the GPU pipeline.

## Capture protocol

Record as much of the baseline as is relevant and available; mark missing
fields explicitly, never invent values:

instance path + session ID; MC/loader versions; pack manifest + mod count;
actual launcher-selected Java executable, version/vendor, relevant JVM args
(if safely available); OS/kernel + CPU/GPU context; heap maximum; world or
server (single-player vs dedicated); location/route/action/entity density;
render/simulation distance; shader pack/version, resource packs, LOD
mods/settings; VSync/FPS cap, display mode; warm-up + cold/warm; tool, mode,
interval, duration, thread selection, local output path; overlays/menus/F3/
inventories/shader/pause state during capture.

## Controlled experiments and statistics

Baseline first, one variable at a time: same world, location, route, action,
entities, render and simulation distance, shaders, resource packs, JVM, and
mod list. Separate cold from warm starts. Report medians and tail latency
(p95/p99 where the tool provides them), never one lucky run. Isolate mods in
a duplicate instance with dependencies respected, and never open a valued
world with a changed mod set. If the delta sits inside run-to-run noise, the
result is inconclusive — say so.

- Keep Spark sample %, tick duration, FPS/frame-time, CPU/GPU utilization,
  heap metrics as separate classes. Never fabricate a percentile or convert
  sampling share to exact milliseconds without a valid denominator.
- Never sum inclusive/overlapping call-tree branches.
- Max is an outlier indicator, not normal performance, until repeated and
  correlated.
- For inconclusive deltas within noise, state "inconclusive".

**Experiment ledger** (compact table or numbered list in the report; never
persist files in the user's instance unless requested): ID + date/session,
question/hypothesis, controlled workload, one changed variable, exact
capture command/settings, output artifacts, observed result,
interpretation/confidence, rollback action, next decision.
