---
name: select-parent
description: "Select the next parent generation for mutation using configurable selection strategies. Use: /hyperagents:select-parent [--method <method>]"
---

# HyperAgents Select Parent Command

Choose the next parent generation from the evolutionary archive to serve as the base for the next mutation.

## Arguments

- `--method <method>`: Selection strategy (default: from config or `score_prop`)
  - `random`: Uniform random from valid parents
  - `latest`: Most recent valid generation
  - `best`: Highest fitness score
  - `score_prop`: Probability proportional to fitness score
  - `score_child_prop`: Score-proportional weighted by child count (favors less-explored parents)
- `--dry-run`: Show selection probabilities without selecting

## Selection Methods

### `random`
Simple uniform selection from all valid parents. Good for maximum exploration.

### `latest`
Always select the most recent valid generation. Creates a linear improvement chain.

### `best`
Always select the highest-scoring generation. Aggressive exploitation, risks getting stuck.

### `score_prop` (recommended)
Probability proportional to fitness score:
```
P(parent_i) = score_i / sum(all_scores)
```
Balances exploitation (high-scoring parents selected more) with exploration (any valid parent has a chance).

### `score_child_prop`
Score-proportional, but down-weights parents that already have many children:
```
P(parent_i) = (score_i / (1 + child_count_i)) / sum(adjusted_scores)
```
Encourages exploring under-visited branches of the archive tree.

## Execution

1. Load archive from `.hyperagents/archive.jsonl`
2. Filter to valid parents only (`valid_parent: true`)
3. Compute per-domain scores for each candidate
4. Average scores across domains
5. Apply selection method
6. If `--dry-run`, display selection probabilities for all candidates
7. Otherwise, output the selected parent genid
8. Save selection to `.hyperagents/next_parent.json`

## Output

```json
{
  "selected_parent": 7,
  "method": "score_prop",
  "candidates": 9,
  "selection_probability": 0.18,
  "parent_fitness": 0.87
}
```
