# 3 — performance and the JVM

- [match the tool to the symptom](#match-the-tool-to-the-symptom)
- [spark](#spark)
- [reading spark numbers](#reading-spark-numbers)
- [loading profiler](#loading-profiler)
- [client vs server](#client-vs-server)
- [JVM: runtime, GC, hangs](#jvm-runtime-gc-hangs)
- [controlled experiments](#controlled-experiments)

## Match the tool to the symptom

- Startup/load time → phase timing and per-mod load report.
- Frame time, stutter → frame-time distribution, render thread, GPU metrics.
- Tick lag → TPS/MSPT, tick-thread tree.
- Memory/GC → allocation rate, post-GC occupancy, pause distribution.
- Hang → repeated thread dumps and lock ownership, not a CPU profile.
- Lag with healthy TPS → packets, ping, client frame time — 20 TPS doesn't
  rule out a client hitch.

Never use TPS to explain a render-thread stall or FPS to diagnose server
MSPT. Single-player runs both in one process, so name the hot thread before
concluding anything.

## Spark

Record before interpreting: game action, location, settings, shader state,
JVM, mod list, sample duration, thread, mode — and whether the symptom was
actually occurring. Prefer a short capture around the event over minutes of
unrelated gameplay. Use a local saved export when supported; never upload a
profile to a public viewer without permission.

Client installs may expose `/sparkc` instead of `/spark`; server-only
commands may not exist on clients. Check the installed version's help.

`.sparkprofile` is binary, not text. Use the official viewer/export or a
verified compatible parser. If parsing fails, say so — never invent fields
or a call tree from `strings` output.

## Reading Spark numbers

Hard rules — these are the mistakes the old workflow kept making:

1. **Thread first.** Identify which thread/process was sampled before any
   claim. Total process CPU (e.g. 31–37%) never proves which thread limits
   the frame. "Render-thread-limited" needs the render thread hot, not a
   process percentage plus familiar method names.
2. **Inclusive vs exclusive.** Merged/overlapping call paths double-count
   parents and children. Never sum merged mod percentages into a combined
   cost (`11.42% + 9.09% ≈ 20.5%` is invalid unless the format's accounting
   makes it additive). State the denominator: samples, wall time, or thread
   time.
3. **Distribution, not max.** A single extreme max (e.g. 1910 ms against a
   3.13 ms median and 7.27 ms p95) is a potentially important isolated hitch,
   not sustained lag. Correlate it with timestamps/events; report median,
   p95, max, duration, interval, and capture conditions together.
4. **GUI state.** Cost recorded with a menu, F3 overlay, or shader settings
   screen open (e.g. `GuiLayerManager.render()`, BetterF3, `mouseClicked()`
   frames) is not normal gameplay overhead. Ask for or capture a clean
   gameplay profile before ranking UI cost as an in-game cost.
5. **Hot ≠ broken.** A hot path is observed work, not proven waste —
   confirm against expected workload and a controlled change. Obfuscated
   names and heuristic class-substring rules can misclassify; inspect real
   stacks. A mod name in a hot frame is not a removal recommendation.
6. **GPU is unmeasured.** Spark samples Java-side work only. Shader/shadow
   cost, GPU frame time, and utilization need GPU-side evidence; never
   present a Java method share as GPU time.

## Loading profiler

Attribution is by code usage: resource loading, mixins, and bridged Fabric
mods may count as vanilla. It is intrusive — never load a valued world with
it installed; use a disposable world or stop after the loading measurement.
Capture a fresh representative startup, record the exact output location,
and compare multiple launches (cold vs warm) before ranking mods. Reported
shares are attribution under its model, not perfect per-mod accounting.
Never infer startup cost from runtime Spark data. Verify the profiler's
current output format and known limitations from its official project
documentation or source at analysis time
(https://modrinth.com/mod/loading-profiler).

## Client vs server

- Render thread hot → rendering, chunk rebuilds, shaders, overlays, sync
  waits, mod/renderer compatibility.
- Tick thread hot → entities, block entities, worldgen, chunk load/save,
  pathfinding, server-side mod work.
- Workers hot → inspect what they do and whether they contend with the main
  thread; aggregate worker CPU can hide latency.
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

## Controlled experiments

Baseline first, one variable at a time: same world, location, route, action,
entities, render and simulation distance, shaders, resource packs, JVM, and
mod list. Separate cold from warm starts. Report medians and tail latency
(p95/p99 frame time), not one lucky run. Isolate mods in a duplicate
instance with dependencies respected, and never open a valued world with a
changed mod set. If the delta sits inside run-to-run noise, the result is
inconclusive — say so.
