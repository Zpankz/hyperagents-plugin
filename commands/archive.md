---
name: archive
description: "View, query, and manage the HyperAgents evolutionary archive. Shows generation history, fitness scores, lineage trees, and best performers. Use: /hyperagents:archive [show|best|lineage|prune|export]"
---

# HyperAgents Archive Command

Manage the evolutionary archive that tracks all generations of self-improvement.

## Subcommands

Parse the first argument as a subcommand:

### `show` (default)
Display the current archive state:
1. Read `.hyperagents/archive.jsonl`
2. For each generation, show: genid, parent, fitness scores, valid_parent status
3. Format as a table with the best generation highlighted
4. Show total generations, valid parents count, and best score

### `best`
Find and display the best generation:
1. Read all generations from the archive
2. Rank by average fitness across all domains
3. Display the top generation's:
   - Full metadata
   - Diff summary (files changed, insertions, deletions)
   - Fitness scores per domain
4. Offer to apply the best generation's patch to the current branch

### `lineage <genid>`
Trace the ancestry of a specific generation:
1. Starting from `<genid>`, follow `parent_genid` links back to initial
2. Display the lineage as a tree showing fitness progression
3. Highlight where the biggest improvements occurred

### `prune`
Remove invalid or low-performing generations:
1. Identify generations where `valid_parent` is false
2. Identify generations with fitness below the archive median
3. Ask for confirmation before removing
4. Update archive.jsonl (create backup first)
5. Clean up orphaned patch files and worktrees

### `export`
Export the best generation's changes:
1. Find the best generation
2. Collect all patches in the lineage (from initial to best)
3. Create a combined diff
4. Write to `.hyperagents/best_combined.diff`
5. Optionally create a new git branch with the changes applied

## Archive File Format

The archive lives at `.hyperagents/archive.jsonl`. Each line is a JSON object representing one generation. The file is append-only — new generations are added at the end.

Read it with:
```bash
jq -s '.' .hyperagents/archive.jsonl
```

## Safety

- Always create backups before modifying the archive
- Never delete the initial generation
- Warn if the archive appears corrupted (missing parent references)
