---
name: Parent Selection Strategies
description: "Evolutionary parent selection algorithms for choosing which generation to mutate next. Implements random, best, score-proportional, and novelty-aware selection. Triggers when selecting parents, managing exploration/exploitation tradeoffs, or configuring evolution strategy."
version: 1.0.0
metadata:
  filePattern:
    - "**/select*parent*"
    - "**/archive.jsonl"
    - "**/.hyperagents/config.json"
  bashPattern:
    - "select.*parent"
    - "parent.*selection"
    - "exploration"
    - "exploitation"
  priority: 70
---

# Parent Selection Strategies

Parent selection is how HyperAgents balances exploration (trying new directions) with exploitation (refining what works). The choice of selection method significantly affects evolution dynamics.

## Available Methods

### `random` — Maximum Exploration
```
P(parent_i) = 1 / N  for all valid parents
```
- Every valid parent has equal probability
- Maximum diversity in the search
- Good for early exploration when you don't know what works
- Risk: wastes compute on low-fitness branches

### `latest` — Linear Chain
```
Always select the most recent valid generation
```
- Creates a simple chain: each generation builds on the last
- No branching, no backtracking
- Good for incremental refinement of a known approach
- Risk: can't escape local optima

### `best` — Maximum Exploitation
```
Always select the highest-fitness generation
```
- Aggressively refines the best-known solution
- Fast convergence when near a good solution
- Risk: premature convergence, no exploration of alternatives

### `score_prop` — Balanced (Recommended)
```
P(parent_i) = fitness_i / sum(all_fitness)
```
- Higher-scoring parents are more likely to be selected
- But any valid parent has a chance proportional to its score
- Natural balance of exploitation and exploration
- This is the default in HyperAgents

### `score_child_prop` — Novelty-Aware
```
P(parent_i) = (fitness_i / (1 + children_i)) / Z
```
Where `Z` is the normalizing constant and `children_i` is the number of offspring already created from parent i.

- Favors high-fitness parents that haven't been explored much
- Encourages branching — explores different evolutionary paths
- Best for open-ended search where diversity matters

## Selection Algorithm

```python
def select_parent(archive, output_dir, domains, method):
    # 1. Get candidates (valid parents only)
    candidates = {}
    for genid in archive:
        if not is_valid_parent(output_dir, genid):
            continue
        # Average fitness across all domains
        scores = [get_score(domain, output_dir, genid) for domain in domains]
        if all(s is not None for s in scores):
            candidates[genid] = mean(scores)

    # 2. Apply selection method
    if method == "random":
        return random.choice(list(candidates.keys()))
    elif method == "latest":
        return max(candidates.keys())
    elif method == "best":
        return max(candidates, key=candidates.get)
    elif method == "score_prop":
        weights = list(candidates.values())
        return random.choices(list(candidates.keys()), weights=weights, k=1)[0]
    elif method == "score_child_prop":
        child_counts = count_children(archive, output_dir)
        weights = [
            score / (1 + child_counts.get(gid, 0))
            for gid, score in candidates.items()
        ]
        return random.choices(list(candidates.keys()), weights=weights, k=1)[0]
```

## Validity Check

A generation is a valid parent if:
1. `valid_parent: true` in its metadata
2. It has non-null fitness scores for all active domains
3. It was not marked as failed by the meta-agent

## When to Use Each Method

| Scenario | Recommended Method |
|----------|-------------------|
| Starting evolution, unknown domain | `random` |
| Refining a known-good approach | `best` |
| General purpose, most cases | `score_prop` |
| Open-ended exploration, diversity matters | `score_child_prop` |
| Ablation study, control condition | `latest` |
| Many generations complete, seeking novelty | `score_child_prop` |

## Diagnostics

Signs of poor parent selection:
- **All offspring from one parent**: Switch to `score_child_prop`
- **No improvement for 5+ generations**: Switch to `random` temporarily
- **Fitness oscillating**: Switch to `best` to stabilize
- **Archive diversity too low**: Switch to `random` or `score_child_prop`
