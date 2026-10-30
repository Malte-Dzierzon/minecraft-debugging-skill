# 2 — crashes and compatibility

- [failure signatures](#failure-signatures)
- [log triage first](#log-triage-first)
- [reading exception chains](#reading-exception-chains)
- [compatibility checks](#compatibility-checks)
- [dependency and version verification](#dependency-and-version-verification)
- [loader, mixin, and transformation conflicts](#loader-mixin-and-transformation-conflicts)
- [world-specific vs pack-wide](#world-specific-vs-pack-wide)
- [minimal testing](#minimal-testing)
- [mixin failures](#mixin-failures)
- [native and graphics failures](#native-and-graphics-failures)
- [memory failures](#memory-failures)

## Failure signatures

Locate the phase first — startup, loader init, mod construction, registry,
resource reload, world load, or runtime — then match the signature:

- **Loader/mod discovery:** missing dependency, wrong MC/loader version,
  invalid metadata, duplicate mod, version-range mismatch, rejected file.
- **Class/linkage:** `ClassNotFoundException`, `NoClassDefFoundError`,
  `NoSuchMethodError`, `NoSuchFieldError`, `AbstractMethodError`,
  `IncompatibleClassChangeError`, `ClassCastException`.
- **Mixin/transform:** target or injection point not found, conflicting
  transformation, bad refmap. See [mixin failures](#mixin-failures).
- **Registry/data:** duplicate entries, bad datapack/JSON, codec errors,
  invalid identifiers.
- **Mod init:** a constructor/setup/registry path throws, wrapped by a loader
  exception.
- **World/data:** fails only on one save or content path.
- **Native/JVM:** `hs_err_pid*.log`, fatal frame, native library, or silent
  exit with no Java exception.
- **Out of memory:** heap, metaspace, direct-buffer, or OS kill — distinct
  causes, distinct evidence. See [memory failures](#memory-failures).
- **Hang:** process alive, no progress — needs repeated thread dumps, not a
  CPU profile.

A signature names a mechanism, not the guilty mod.

## Log triage first

Triage in this order — root cause first, noise never:

1. **First relevant exception + full `Caused by` chain.** Wrappers like
   `ModLoadingException` only report a deeper cause. One representative stack,
   not five.
2. **Lines before the exception:** first warning, version mismatch, failed
   mixin, invalid registry value, missing dependency tied to that cause.
3. **Crash report vs `latest.log` / `debug.log`:** they preserve different
   context — compare both for phase and trigger.
4. **Repeated messages:** group by count (`994× …`), inspect one instance's
   stack, timestamp span, and consequence. Repeated warnings are not equally
   severe: a shader-uniform incompatibility spam, a recipe-registration
   exception, and a configuration-phase NPE differ in phase, severity, and
   relation to the crash. Never rank them by count alone.
5. **No source line available?** Say so. Never invent one.

The last mod in a stack is often where a conflict surfaces, not where it
originated. A throwing vanilla method fed a bad value by a mod looks
identical to a vanilla bug without the earlier evidence.

## Reading exception chains

A JNI `UnsatisfiedLinkError` (e.g. a missing/mismatched native method such
as `NativeDB._open_utf8`) is direct evidence of a native binding/load
mismatch — it is not, by itself, proof of which Java major version caused
it. Before naming a root cause: identify the exact native method
declaration, the packaged native library (version/architecture), the mod
release's declared runtime requirements, and reproducibility under a
documented supported runtime. Java-version mismatch stays a hypothesis
until tested or directly documented.

## Compatibility checks

Extract exact MC version, loader build, Java runtime, mod IDs and versions.
Then check: does the mod support this MC/loader family, require a specific
loader build or Java feature level, duplicate a bridge layer, or share a
patched class/renderer/registry path with another mod? Was the failure
introduced by an update — compare manifests, not memory?

Use primary sources: release notes, issue tracker, source repo, loader docs.
Record exact versions and dates. Never declare an incompatibility from two
mods merely co-occurring in a stack. Verify the report matches the exact
version in use, not a nearby release.

## Dependency and version verification

For dependency-suspect crashes, verify each link in the chain against the
installed artifacts — never from memory or a similarly named release:

1. Read the exact installed mod version (JAR metadata, loader banner, or
   manifest — not the filename alone).
2. Read that release's declared dependencies and version ranges from its
   own docs/source.
3. Confirm the dependency is present at a satisfying version in `mods/`
   or the pack manifest.
4. Confirm the loader build satisfies every participant's declared range.

A satisfied-looking filename pair that violates a declared range is still a
mismatch. Record what each source proves (URL, version/date).

## Loader, mixin, and transformation conflicts

When two or more mods patch the same class/renderer/registry path, or a
loader upgrade moved the target:

1. Name the target class/method and each claimant (mod + version + injector
   kind where visible).
2. Check each claimant's supported MC/loader range — an upstream target
   change breaks previously working patches.
3. Prefer the earliest transformation failure in load order, not the last
   mod named in the final stack.
4. Resolve on a copy: disable one claimant (respecting dependencies),
   retest the same action, compare logs.

Never relax mixin checks as a generic fix — it hides a broken patch and
risks later corruption. Only a mod's own docs can justify a specific
compatibility setting, with a rollback plan.

## World-specific vs pack-wide

Before blaming the pack (or one save), separate the two:

1. Does the failure reproduce on a fresh/disposable world with the same mod
   set? If yes → pack-wide.
2. Does it occur only on one save or content path (datapack, region,
   player data)? If yes → world/data, not pack-wide.
3. Never test either hypothesis on a valued world — use a copy or a
   disposable world, with a backup first.

## Minimal testing

1. Reproduce and record the phase and triggering action.
2. Check metadata and the first relevant error.
3. Test on a copy, never the only working instance.
4. Disable one strongly implicated mod (or a small dependency-connected set),
   respecting dependency constraints.
5. Retest the same action, compare logs. One passing run after many changes
   is weak evidence.
6. Only then consider a controlled binary search over mod groups.

Never test a changed mod set against a valued world without a backup. For
world-specific issues, use a copy or disposable world.

## Mixin failures

A failed injection is a mismatch between a patch and the runtime bytecode.
Candidates: incompatible mod versions, upstream target change, another
transformation altering the target, wrong side/environment, missing optional
path. Identify target class/method, injector kind, required/optional status,
and other transformations before ranking causes.

Never recommend relaxing mixin checks as a generic fix — it hides a broken
patch and risks later corruption. Only a mod's own docs can justify a
specific compatibility setting, with a rollback plan.

## Native and graphics failures

From a JVM fatal log take the error header, problematic frame, native
library, current thread, JVM build, and command line, then correlate with
the MC log. A native frame in a graphics library implicates the
driver/runtime path but doesn't prove defective hardware.

For rendering crashes, correlate with renderer/shader mods and whether the
issue reproduces with shaders and custom resource packs disabled in a
duplicate instance. Spark profiles Java-side work only — never claim it
measures GPU execution.

## Memory failures

- **Java heap OOM:** heap occupancy, allocation pressure, retained
  objects, GC behavior, repeatability.
- **Metaspace OOM:** class loading, classloader retention, transformation
  counts.
- **Direct/off-heap:** buffer pressure, native memory, OS limits.
- **OS kill / abrupt exit:** no Java OOM message doesn't rule out memory
  pressure; check OS/launcher evidence when available.

Heap occupancy alone (e.g. 85%) is not a memory problem. Check allocation
rate, GC frequency and pause time, headroom over time, and symptom
correlation before calling it pressure or a leak. Never jump to "add more
RAM." More heap can postpone a leak, inflate GC latency, or starve the OS.
Match the fix to the failure type; never raise heap as a reflex.
