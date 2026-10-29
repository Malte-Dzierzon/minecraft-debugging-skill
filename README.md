<div align="center">

# Minecraft Debugging Skill

**Drop this skill into your local agent to debug large Minecraft modpacks.**

![](https://img.shields.io/badge/minecraft-java_edition-16a3da?style=flat-square&labelColor=070e15)
![](https://img.shields.io/badge/license-MIT-3b4250?style=flat-square&labelColor=070e15)

</div>

A large modpack spreads its evidence across logs, crash reports, and
profiler output. This skill gives your agent a fixed workflow for reading
it: inventory the instance, reconstruct the timeline, branch by symptom,
and report what the evidence supports — with a reversible test per claim.

<details>
<summary><b>How it works</b></summary>

- Inventory the instance: logs, disconnect reports, crash reports, JVM logs,
  profiler captures — then pin the right run by timestamp, not filename.
- Reconstruct a timeline: first causally relevant failure wins, not the last
  scary line.
- Branch by symptom: crashes and compatibility, or performance and the JVM.
- Report verdict, evidence, confidence, and a ranked action plan.

Four depths: Quick, Standard, Deep, Forensic.

</details>

<details>
<summary><b>Use</b></summary>

```text
Use the minecraft-debugging-skill skill on
/path/to/Prism/instances/MyPack/.minecraft.
The client freezes on world join — inventory first,
then ask me for Quick, Standard, Deep, or Forensic.
```

Works with Forge, NeoForge, Fabric, and Quilt, and any launcher layout:
instance root, game directory, logs folder, or exported pack. Read-only by
default; no uploads without permission.

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
./install.sh --agent codex    # ~/.codex/skills/
./install.sh --all            # every agent dir that already exists
```

`--copy` copies instead of linking, `--dry-run` previews, `--uninstall`
removes. Only the payload is installed — repo docs stay here. Reload the
agent afterwards.

</details>

<details>
<summary><b>Repository layout</b></summary>

- `SKILL.md` — the skill: workflow, rules, branch router.
- `references/1-artifacts.md` — finding artifacts, safe search, privacy.
- `references/2-crash.md` — crash signatures, exception chains, mixins.
- `references/3-performance.md` — Spark, Loading Profiler, GC, hangs.
- `tests/EVALUATIONS.md` — maintainer acceptance scenarios.
- `install.sh` — payload installer for local agents.

</details>
