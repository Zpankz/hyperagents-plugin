---
name: Self-Referential Self-Improvement
description: "Apply HyperAgents' self-referential improvement pattern to any code artifact. Triggers when Claude is asked to 'improve', 'optimize', 'evolve', or 'self-improve' code, agents, skills, or prompts. Also triggers on repeated failures as an automatic recovery strategy."
version: 1.0.0
metadata:
  filePattern:
    - "**/*.md"
    - "**/SKILL.md"
    - "**/agents/*.md"
    - "**/.hyperagents/**"
  bashPattern:
    - "hyperagents"
    - "evolve"
    - "self-improve"
  priority: 90
---

# Self-Referential Self-Improvement

This skill implements the core insight from Meta's HyperAgents paper: **agents can improve themselves by treating their own code/prompts as mutable targets, evaluating changes with fitness functions, and selecting the best mutations across generations.**

## When This Skill Activates

- User asks to "improve", "optimize", or "evolve" a skill, agent, or code file
- A task fails repeatedly (automatic recovery via self-improvement)
- User explicitly invokes `/hyperagents:evolve`
- User asks about self-referential improvement patterns

## The Self-Improvement Cycle

```
┌─────────────────────────────────────────────┐
│              GENERATE LOOP                   │
│                                              │
│  1. SELECT PARENT (from archive)             │
│         │                                    │
│  2. MUTATE (meta-agent modifies code)        │
│         │                                    │
│  3. EVALUATE (fitness scoring)               │
│         │                                    │
│  4. ARCHIVE (store generation + score)       │
│         │                                    │
│  5. SELECT NEXT PARENT (fitness-weighted)    │
│         │                                    │
│         └──────── repeat ────────────┘       │
└─────────────────────────────────────────────┘
```

## Key Principles

### 1. Everything is Mutable
Unlike traditional agent frameworks where the orchestrator is fixed, HyperAgents allows the meta-agent to modify:
- Task agent prompts and logic
- Tool definitions and tool selection strategies
- Evaluation criteria and scoring rubrics
- Parent selection algorithms
- Even its own system prompt

### 2. Fitness-Driven Selection
Changes are not accepted blindly. Every mutation is evaluated:
- **Staged evaluation**: Quick check on small sample (fail fast)
- **Full evaluation**: Comprehensive scoring if staged passes
- **Archive comparison**: New generation scored against all ancestors

### 3. Evolutionary Archive
All generations are kept in an append-only archive:
- Enables backtracking to any previous generation
- Supports ensemble methods (combining best aspects of multiple generations)
- Provides data for analysis of what improvement strategies work

### 4. Sandboxed Mutation
All changes are made in isolation:
- Git worktrees provide sandboxed copies of the codebase
- Failed mutations don't corrupt the main branch
- Diffs are captured and stored for replay

## Applying Self-Improvement to Claude Code Artifacts

### Improving a Skill
1. Identify the skill's evaluation criteria (what makes it "good"?)
2. Create a fitness function (test it on sample inputs, score the outputs)
3. Run the evolve loop targeting the SKILL.md file
4. Each generation modifies the skill's instructions
5. The best-scoring version becomes the new skill

### Improving an Agent
1. Define the agent's success criteria
2. Create test cases that exercise the agent
3. Run the meta-agent to modify the agent's system prompt
4. Evaluate each version against the test cases
5. Select the best-performing version

### Improving Hooks
1. Measure hook execution time and false positive rate
2. Run evolve loop on the hook script
3. Each generation modifies the hook logic
4. Score based on accuracy and performance
5. Deploy the best version

## Implementation Pattern

When asked to self-improve a target:

```
1. Create .hyperagents/ directory if not exists
2. Define fitness function for the target
3. Store initial version as gen_initial
4. For N generations:
   a. Select parent from archive
   b. Create git worktree
   c. Dispatch meta-agent to modify target in worktree
   d. Capture diff
   e. Run fitness evaluation
   f. Store results in archive
   g. Clean up worktree
5. Apply best generation's changes
```

## Anti-Patterns to Avoid

- **Goodhart's Law**: Don't let the meta-agent optimize the evaluator to give itself higher scores without real improvement
- **Catastrophic forgetting**: Ensure improvements in one area don't regress others
- **Infinite loops**: Set a hard generation limit; diminishing returns are expected
- **Over-mutation**: Prefer small, focused changes over wholesale rewrites
