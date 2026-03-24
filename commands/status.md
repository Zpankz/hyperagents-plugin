---
name: status
description: "Show the current state of the HyperAgents evolution process — active generation, archive health, fitness trajectory, and next steps. Use: /hyperagents:status"
---

# HyperAgents Status Command

Display a comprehensive status report of the evolutionary improvement process.

## Execution

1. **Check initialization**: Verify `.hyperagents/` directory exists
   - If not, tell user to run `/hyperagents:evolve` first

2. **Load archive**: Read `.hyperagents/archive.jsonl`
   - Count total generations
   - Count valid parents
   - Find best generation and its fitness

3. **Display summary table**:
   ```
   HyperAgents Evolution Status
   ────────────────────────────────────
   Generations:     12 / 20
   Valid parents:   9 (75%)
   Best fitness:    0.87 (gen_7)
   Current parent:  gen_7
   Root commit:     abc1234
   Domain(s):       tests, review
   Selection:       score_prop
   ────────────────────────────────────
   ```

4. **Fitness trajectory**: Show last 5 generations with trend
   ```
   gen_8:  0.72 ▼
   gen_9:  0.78 ▲
   gen_10: 0.81 ▲
   gen_11: 0.79 ▼
   gen_12: 0.85 ▲ (latest)
   ```

5. **Next action**: Suggest what to do next based on state:
   - If evolution is in progress: "Run `/hyperagents:evolve --resume` to continue"
   - If max generations reached: "Run `/hyperagents:archive best` to see the winner"
   - If all recent generations are invalid: "Consider changing parent selection or domain"

6. **Disk usage**: Show size of `.hyperagents/` directory
