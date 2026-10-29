<div align="center">

# minecraft-debugging-skill

**Drop this skill into your local agent to debug large Minecraft modpacks.**

![](https://img.shields.io/badge/ai_skill-minecraft_debugging-16a3da?style=flat-square&labelColor=070e15)
![](https://img.shields.io/badge/minecraft-java_edition-3b4250?style=flat-square&labelColor=070e15)
![](https://img.shields.io/badge/forge-supported-3b4250?style=flat-square&labelColor=070e15)
![](https://img.shields.io/badge/neoforge-supported-3b4250?style=flat-square&labelColor=070e15)
![](https://img.shields.io/badge/fabric-supported-3b4250?style=flat-square&labelColor=070e15)
![](https://img.shields.io/badge/quilt-supported-3b4250?style=flat-square&labelColor=070e15)
![](https://img.shields.io/badge/license-MIT-3b4250?style=flat-square&labelColor=070e15)

</div>

Large modpacks break in ways generic advice can't fix. This skill gives your
agent a fixed workflow for it: inventory the instance, reconstruct the
timeline, branch by symptom, and report verdict plus evidence. No guessing,
no "allocate 16GB and delete Sodium".

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

Works with any launcher layout: instance root, game directory, logs folder,
or exported pack. Read-only by default; no uploads without permission.

</details>

<details>
<summary><b>Install</b></summary>

```bash
./install.sh
```

Copies the skill payload (`SKILL.md` + `references/`) to
`~/.omp/agent/skills/minecraft-debugging-skill/`. Other location:

```bash
./install.sh ~/.claude/skills/minecraft-debugging-skill
# or: SKILL_DIR=/custom/path ./install.sh
```

`README.md`, `LICENSE`, `THIRD_PARTY_NOTICES.md`, and `tests/` stay in the
repo — only the payload gets installed. Reload the agent if needed.

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
