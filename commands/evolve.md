---
name: evolve
description: "Start or resume a HyperAgents evolutionary improvement loop. Iteratively mutates code/skills/agents, evaluates fitness, and selects parents for the next generation. Use: /hyperagents:evolve [--domain <domain>] [--generations <n>] [--resume]"
---

# HyperAgents Evolve Command

You are orchestrating an evolutionary self-improvement loop inspired by Meta's HyperAgents framework. This is the core generate loop — it coordinates the meta-agent, task-agent, evaluation, archive management, and parent selection.

## Arguments

Parse the user's arguments:
- `--domain <domain>`: The evaluation domain (default: infer from project context)
- `--generations <n>`: Maximum generations to run (default: 5)
- `--resume`: Resume from existing archive state
- `--target <path>`: What to evolve (a skill, agent, hook, or code file)
- `--parent-selection <method>`: One of `score_prop`, `random`, `latest`, `best` (default: `score_prop`)
- `--skip-staged`: Skip staged evaluation (go straight to full eval)

## Execution Flow

### Phase 1: Initialize

1. Check for existing archive at `.hyperagents/archive.jsonl` in the project root
2. If `--resume`, load the archive and continue from the last generation
3. If fresh start:
   - Create `.hyperagents/` directory structure
   - Record the current git commit as `root_commit`
   - Create `gen_initial/` with baseline evaluation
   - Initialize `archive.jsonl` with the initial node

### Phase 2: Generate Loop

For each generation from `start` to `max_generation`:

1. **Select Parent**: Use the parent selection method to pick an ancestor from the archive
2. **Create Worktree**: Launch a git worktree for isolated mutation (`hyperagents/gen_<id>`)
3. **Run Meta-Agent**: Dispatch the `meta-agent` subagent in the worktree with:
   - The target file(s) to improve
   - Previous evaluation results from the archive
   - The number of remaining iterations
4. **Capture Diff**: Record the meta-agent's changes as a patch file
5. **Staged Evaluation**: Run quick fitness check on a small sample
   - If score is 0 or null, skip full evaluation (saves cost)
6. **Full Evaluation**: If staged eval passes, run complete fitness evaluation
7. **Update Archive**: Append the new generation to `archive.jsonl` with metadata
8. **Cleanup**: Remove the worktree, keep the patch and results

### Phase 3: Report

After all generations complete:
1. Display a progress summary showing fitness over generations
2. Highlight the best generation and its improvements
3. Show the diff of the best generation vs the initial state
4. Suggest applying the best generation's changes to the main branch

## Archive Structure

Each generation in `.hyperagents/archive.jsonl` is a JSON line:
```json
{
  "genid": 3,
  "parent_genid": 1,
  "timestamp": "2026-03-25T10:30:00Z",
  "patch_file": ".hyperagents/gen_3/model_patch.diff",
  "fitness_scores": {"accuracy": 0.85, "quality": 0.72},
  "valid_parent": true,
  "meta_agent_success": true,
  "run_full_eval": true
}
```

## Key Principles

- **Sandboxed mutation**: All changes happen in git worktrees, never on the main branch
- **Immutable archive**: Never modify past generations, only append new ones
- **Fail-safe**: If a generation fails, mark it as invalid parent and continue
- **Observable**: Log every step to `.hyperagents/gen_<id>/generate.log`
- **Deterministic replay**: Store enough metadata to reproduce any generation

## Agent Dispatch

Use the Agent tool to dispatch subagents:
- `meta-agent`: For generating code mutations (run in worktree isolation)
- `evaluator`: For fitness evaluation
- `ensemble-agent`: For combining predictions from multiple archive members

Always use `run_in_background: true` for evaluation agents to enable parallelism.
