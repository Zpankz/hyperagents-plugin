# KNOWLEDGE_GRAPH_ROLE.md

> This file documents this repository's role in the unified
> CICM/ANZCA medical knowledge graph. The canonical skill lives at:
> `MAK95-Vault/.claude/skills/medical-knowledge-graph/`.
> The skill ingests this repository as part of its build pipeline.

## Role

GEPA evolutionary-Pareto orchestration substrate. The medical-knowledge-graph skill's gepa/ directory mirrors the plugin's archive.jsonl + gen_NNN/ + meta-agent/evaluator/task-agent pattern. The skill can be evolved either standalone (via gepa/run_generation.py) or wrapped as a hyperagents domain harness for full /hyperagents:evolve orchestration.

## Source of truth

- Skill manifest: `MAK95-Vault/.claude/skills/medical-knowledge-graph/SKILL.md`
- Build pipeline: `scripts/build_graph.py`
- Ontology (homoiconic): `ontology/{nodes,edges,properties}.yaml`
- Self-improvement loop: `gepa/README.md`

## Branch

Development branch for this initiative: `claude/medical-knowledge-graph-UjThY`
