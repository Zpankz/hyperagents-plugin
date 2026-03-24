---
name: evaluate
description: "Evaluate a specific generation or the current codebase against fitness criteria. Supports staged (quick) and full evaluation modes. Use: /hyperagents:evaluate [--genid <id>] [--domain <domain>] [--staged]"
---

# HyperAgents Evaluate Command

Run fitness evaluation on a generation or the current codebase state.

## Arguments

- `--genid <id>`: Evaluate a specific archived generation (default: current working state)
- `--domain <domain>`: Evaluation domain to use
- `--staged`: Run quick staged evaluation only (smaller sample)
- `--full`: Force full evaluation even if staged eval fails
- `--samples <n>`: Number of evaluation samples (-1 for all)

## Execution Flow

### 1. Resolve Target

If `--genid` is provided:
- Load the generation's metadata from `.hyperagents/gen_<id>/metadata.json`
- Apply the lineage patches to reconstruct the generation's state
- Use a temporary worktree for evaluation

If no `--genid`:
- Evaluate the current working tree state directly

### 2. Determine Domain

If `--domain` is specified, use it. Otherwise:
- Check `.hyperagents/config.json` for default domain
- Infer from project structure (test files, CI config, package.json scripts)
- Ask the user if ambiguous

### 3. Run Evaluation

**Staged evaluation** (default first pass):
- Run with a small sample (10 items or 10% of full set)
- If score is 0 or null, report failure and skip full eval
- This saves compute on obviously broken mutations

**Full evaluation** (if staged passes or `--full` flag):
- Run with full sample set
- Record detailed per-item results
- Generate a report.json with aggregate scores

### 4. Report Results

Display:
- Overall fitness score
- Per-domain breakdown (if multi-domain)
- Comparison to parent generation (if available)
- Comparison to best-in-archive
- Specific items that improved or regressed

### 5. Save Results

Write evaluation results to:
- `.hyperagents/gen_<id>/<domain>_eval/report.json`
- `.hyperagents/gen_<id>/<domain>_eval/predictions.csv`

## Domain Evaluation Interface

Each domain must implement:
- `harness(task_list, agent_path, output_dir)` — run the agent on tasks
- `report(output_dir)` — generate score summary
- `score_key` — the JSON key in report.json containing the fitness score

Built-in domain types:
- `tests`: Run project test suite, score = pass rate
- `lint`: Run linters, score = 1 - (issues / baseline_issues)
- `benchmark`: Run custom benchmark script
- `review`: LLM-as-judge evaluation of code quality
- `custom`: User-defined evaluation script
