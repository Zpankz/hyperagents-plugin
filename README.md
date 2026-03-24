# HyperAgents Plugin for Claude Code

A Claude Code plugin that brings **self-referential self-improving agents** to your development workflow. Inspired by Meta's [HyperAgents](https://arxiv.org/abs/2603.19461) paper — evolutionary optimization of skills, agents, hooks, and code via LLM-driven mutation and fitness-based selection.

## What It Does

HyperAgents runs an evolutionary loop over your code:

```
SELECT PARENT → MUTATE (meta-agent) → EVALUATE (fitness) → ARCHIVE → repeat
```

Each generation, a meta-agent modifies target code in a sandboxed git worktree. The changes are scored by a pluggable fitness function. The best mutations survive and become parents for the next generation. The system can even improve its own selection algorithms and evaluation criteria.

## Install

```bash
# Clone the plugin
git clone https://github.com/Zpankz/hyperagents-plugin.git ~/.claude/plugins/hyperagents-plugin

# Or symlink from a local clone
ln -s /path/to/hyperagents-plugin ~/.claude/plugins/hyperagents-plugin
```

## Commands

| Command | Description |
|---------|-------------|
| `/hyperagents:evolve` | Start or resume an evolutionary improvement loop |
| `/hyperagents:evaluate` | Evaluate a generation against fitness criteria |
| `/hyperagents:archive` | View, query, and manage the evolutionary archive |
| `/hyperagents:select-parent` | Select next parent with configurable strategy |
| `/hyperagents:status` | Show evolution progress dashboard |

## Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| `meta-agent` | Opus | Self-referential code mutator — can modify any file including itself |
| `task-agent` | Sonnet | Domain task executor — the agent that gets evolved |
| `evaluator` | Haiku | Fitness evaluation runner |
| `ensemble-agent` | Haiku | Combines predictions from multiple archive generations |

## Skills (Auto-Activating)

- **Self-Referential Self-Improvement** — Core evolutionary improvement pattern
- **Evolutionary Archive** — Append-only generation tracking with lineage
- **Fitness Evaluation** — Domain-agnostic scoring framework
- **Parent Selection** — 5 selection strategies (random, latest, best, score_prop, score_child_prop)
- **Domain Harness** — Pluggable evaluation harness creation
- **Staged Evaluation** — Two-phase eval to save 75%+ compute on broken mutations

## Hooks

- **PostToolUse**: Tracks file edits during evolution
- **Stop**: Snapshots archive state on session end
- **SessionStart**: Detects and reports evolution state on resume

## CLI Utilities

```bash
# Archive management
bash scripts/archive-manager.sh show|best|lineage|fitness|validate|export

# Fitness scoring
bash scripts/fitness-scorer.sh compute|compare|rank|trend
```

## Key Concepts

### Self-Referential Improvement

Unlike traditional agent frameworks where the orchestrator is fixed, HyperAgents allows the meta-agent to modify **any** part of the codebase — including:
- Task agent prompts and logic
- Evaluation criteria and scoring
- Parent selection algorithms
- Its own system prompt

### Evolutionary Archive

All generations are stored in an append-only `.hyperagents/archive.jsonl`. Each generation records its parent, fitness scores, code diff, and metadata. This enables:
- Backtracking to any previous generation
- Ensemble methods combining best generations
- Analysis of what improvement strategies work

### Sandboxed Mutation

All mutations happen in isolated git worktrees. Failed mutations never touch the main branch. Diffs are captured and stored for deterministic replay.

### Staged Evaluation

A two-phase evaluation strategy: quick check on 10% of samples first, full evaluation only if the quick check passes. Saves 75%+ compute by rejecting obviously broken mutations early.

## Architecture

```
hyperagents-plugin/
├── .claude-plugin/plugin.json     # Plugin manifest
├── commands/                       # 5 slash commands
├── agents/                         # 4 specialized subagents
├── skills/                         # 6 auto-activating skills
├── hooks/                          # 3 event-driven hooks
└── scripts/                        # 2 CLI utilities
```

## Based On

[HyperAgents: Self-Referential Self-Improving Agents](https://arxiv.org/abs/2603.19461) by Jenny Zhang, Bingchen Zhao, Wannan Yang, Jakob Foerster, Jeff Clune, Minqi Jiang, Sam Devlin, Tatiana Shavrina (Meta / FAIR, 2026).

## License

CC-BY-NC-SA-4.0 (matching the original HyperAgents repository)
