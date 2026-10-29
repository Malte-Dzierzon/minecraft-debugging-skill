# 2 — crashes and compatibility

- [failure signatures](#failure-signatures)
- [reading exception chains](#reading-exception-chains)
- [compatibility checks](#compatibility-checks)
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

## Reading exception chains

1. Find the first causally relevant exception and every `Caused by` /
   suppressed section. Wrappers like `ModLoadingException` only report a
   deeper cause.
2. Identify the throwing method, its callers, and the phase.
3. Search earlier log lines for the first warning, version mismatch, failed
   mixin, invalid registry value, or missing dependency tied to that cause.
4. Compare crash report against `latest.log` / `debug.log` — they preserve
   different context.
5. No source line available? Say so. Never invent one.

The last mod in a stack is often where a conflict surfaces, not where it
originated. A throwing vanilla method fed a bad value by a mod looks
identical to a vanilla bug without the earlier evidence.

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

- **Java heap OOM:** needs heap occupancy, allocation pressure, retained
  objects, GC behavior, repeatability.
- **Metaspace OOM:** class loading, classloader retention, transformation
  counts.
- **Direct/off-heap:** buffer pressure, native memory, OS limits.
- **OS kill / abrupt exit:** no Java OOM message doesn't rule out memory
  pressure; check OS/launcher evidence when available.

Never jump to "add more RAM." More heap can postpone a leak, inflate GC
latency, or starve the OS. Match the fix to the failure type.
