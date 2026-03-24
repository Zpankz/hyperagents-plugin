---
name: Evolutionary Archive Management
description: "Manage the HyperAgents evolutionary archive — an append-only log of all code generations with fitness scores, lineage tracking, and diff storage. Triggers when working with .hyperagents/ directory, archive.jsonl files, or generation metadata."
version: 1.0.0
metadata:
  filePattern:
    - "**/.hyperagents/**"
    - "**/archive.jsonl"
    - "**/metadata.json"
  bashPattern:
    - "archive"
    - "generation"
    - "genid"
  priority: 80
---

# Evolutionary Archive Management

The evolutionary archive is the persistent memory of the HyperAgents improvement process. It stores every generation's code changes, fitness scores, and lineage relationships.

## Archive Structure

```
.hyperagents/
├── archive.jsonl              # Append-only generation log
├── config.json                # Evolution configuration
├── next_parent.json           # Pre-computed next parent selection
├── gen_initial/               # Baseline generation
│   ├── metadata.json          # Generation metadata
│   └── <domain>_eval/         # Evaluation results
│       ├── report.json        # Aggregate scores
│       └── predictions.csv    # Per-item predictions
├── gen_0/
│   ├── metadata.json
│   ├── agent_output/
│   │   ├── model_patch.diff   # The code diff
│   │   └── meta_agent_chat_history.md
│   └── <domain>_eval/
│       ├── report.json
│       └── predictions.csv
├── gen_1/
│   └── ...
└── gen_N/
    └── ...
```

## archive.jsonl Format

Each line is a self-contained JSON snapshot of the archive state after adding a new generation:

```json
{"current_genid": 3, "archive": ["initial", 0, 1, 2, 3]}
```

This append-only format enables:
- Recovery from crashes (last complete line is the truth)
- Historical analysis (see how the archive grew)
- Atomic updates (each line is a complete snapshot)

## metadata.json Format

Each generation's metadata records its full context:

```json
{
  "gen_output_dir": ".hyperagents/gen_3",
  "current_genid": 3,
  "parent_genid": 1,
  "prev_patch_files": [".hyperagents/gen_1/agent_output/model_patch.diff"],
  "curr_patch_files": [".hyperagents/gen_3/agent_output/model_patch.diff"],
  "parent_agent_success": true,
  "optimize_option": "only_agent",
  "can_select_next_parent": true,
  "run_eval": true,
  "run_full_eval": true,
  "valid_parent": true
}
```

## Key Operations

### Adding a Generation
1. Create `gen_<id>/` directory
2. Run meta-agent, save diff and chat history to `agent_output/`
3. Run evaluation, save results to `<domain>_eval/`
4. Write `metadata.json` with all context
5. Append to `archive.jsonl` with updated archive list

### Reconstructing a Generation
To get the full codebase state at any generation:
1. Start from the root commit
2. Apply all diffs in the lineage chain: initial -> parent -> ... -> target
3. The lineage is stored in `metadata.json` as `prev_patch_files` + `curr_patch_files`

### Querying the Archive
- **Best generation**: Sort by fitness, take max
- **Lineage of N**: Follow `parent_genid` links from N to initial
- **Valid parents**: Filter where `valid_parent: true`
- **Improvement rate**: Compare each generation to its parent

## Fitness Score Retrieval

Scores live in `gen_<id>/<domain>_eval/report.json`. The score key varies by domain:
- `overall_accuracy` — classification domains
- `average_progress` — game environments
- `average_fitness` — control tasks
- `accuracy_score` — code editing
- `points_percentage` — proof grading

## Ensemble Scoring

When ensemble optimization is enabled, additional scores are stored at:
`gen_<id>/report_ensemble_<domain>_<split>.json`

The `max` score type returns the better of agent and ensemble scores.

## Safety Rules

1. **Never modify archive.jsonl in place** — only append
2. **Never delete gen_initial/** — it's the baseline
3. **Always write metadata.json atomically** — write to temp file, then rename
4. **Back up before pruning** — copy archive.jsonl before removing generations
5. **Validate lineage integrity** — every genid's parent must exist in the archive
