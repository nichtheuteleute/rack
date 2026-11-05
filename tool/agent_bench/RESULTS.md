# Agent benchmark results

Run on 2026-11-05 with Claude Code 2.1.318, model alias `sonnet` (Claude Sonnet 5.5), Flutter 3.47.8. 72 runs (4 tasks × 3 variants × 6 runs), total API cost $7.21. Method and limits: [README.md](README.md). Raw data: `results/*.jsonl`.

## Summary

| | rack | Riverpod | Bloc |
|---|---|---|---|
| Solved | **24/24** | **24/24** | 23/24 |
| Mean cost per run | **$0.095** | **$0.095** | $0.111 |
| Sum of per-task median cost | $0.373 | **$0.352** | $0.441 |
| Sum of per-task median agent time | **103 s** | 127 s | 127 s |
| Runs over 2 minutes | 1 | 2 | 2 |
| Hand-written code in `lib/` (excl. shared files) | 339 lines | 289 lines + 2 generated files | 464 lines |

**What the data supports**

- **Cost and tokens: rack is on par with Riverpod and about 15 % cheaper than Bloc.** Mean cost per run is identical for rack and Riverpod; Riverpod is slightly cheaper on the sum of medians, mainly because of the smallest task. Bloc is the most expensive in total, driven by the cross-feature task 04 (≈ 40 % more than rack and Riverpod).
- **Agent time: rack finished feature tasks fastest.** Median 30 s vs. 47 s (Riverpod) / 38 s (Bloc) for the new screen, 35 s vs. 46 s / 52 s for the new setting. Part of Riverpod's extra time is the `build_runner` step after changing providers.
- **Reliability: rack had no failed run and the fewest long runs.** The long Riverpod and Bloc runs all had the same cause: a widget test the agent wrote for asynchronous state hung, and the agent spent minutes on it; one Bloc run delivered a test suite that never finishes. With six runs per cell this is an observation, not a proven difference.

**What it does not support**

- rack does **not** use fewer tokens than Riverpod. On the smallest task (delete a note) rack was about 25 % more expensive than Riverpod, because the change touches store, controller and widget.
- Bug fixing showed no difference at all — the app is small enough that every agent reads the whole code base first.
- No claim about large code bases: there, structure might matter more for search effort, in either direction.

## Per task

Median (min–max) over 6 runs. "context tok" = all input tokens incl. cache reads.

### 01_delete_note

| variant | solved | cost $ | context tok | output tok | turns | time s | lines changed |
|---|---|---|---|---|---|---|---|
| rack | 6/6 | 0.086 (0.073–0.101) | 134,256 (103,228–194,077) | 2,110 (1,513–2,492) | 5 (4–7) | 22 (18–25) | 51 (27–63) |
| riverpod | 6/6 | 0.069 (0.065–0.073) | 100,024 (97,994–100,646) | 1,712 (1,672–1,771) | 4 (4–4) | 18 (17–23) | 41 (40–43) |
| bloc | 6/6 | 0.085 (0.081–0.089) | 104,342 (103,033–104,552) | 2,252 (2,116–2,385) | 4 (4–4) | 22 (20–29) | 70 (56–76) |

### 02_stats_screen

| variant | solved | cost $ | context tok | output tok | turns | time s | lines changed |
|---|---|---|---|---|---|---|---|
| rack | 6/6 | 0.106 (0.100–0.143) | 119,756 (103,664–179,118) | 3,770 (3,562–4,350) | 4 (4–7) | 30 (28–154) | 163 (159–186) |
| riverpod | 6/6 | 0.106 (0.092–0.193) | 135,125 (102,414–423,916) | 3,614 (3,494–5,958) | 5 (4–13) | 47 (45–465) | 144 (142–153) |
| bloc | 5/6 | 0.127 (0.109–0.198) | 173,467 (137,006–408,729) | 4,220 (3,722–5,574) | 6 (5–13) | 38 (31–621) | 124 (118–133) |

### 03_fix_toggle_persist

| variant | solved | cost $ | context tok | output tok | turns | time s | lines changed |
|---|---|---|---|---|---|---|---|
| rack | 6/6 | 0.056 (0.047–0.064) | 95,762 (91,587–120,231) | 1,082 (912–1,555) | 4 (4–5) | 16 (14–19) | 16 (9–18) |
| riverpod | 6/6 | 0.056 (0.051–0.065) | 97,152 (95,495–122,588) | 1,056 (894–1,503) | 4 (4–5) | 15 (14–17) | 15 (6–16) |
| bloc | 6/6 | 0.052 (0.047–0.064) | 93,997 (92,600–103,366) | 1,026 (878–1,055) | 4 (4–4) | 15 (14–17) | 6 (5–6) |

### 04_hide_done_setting

| variant | solved | cost $ | context tok | output tok | turns | time s | lines changed |
|---|---|---|---|---|---|---|---|
| rack | 6/6 | 0.125 (0.099–0.146) | 185,084 (105,141–242,250) | 3,948 (3,350–4,791) | 6 (4–8) | 35 (27–44) | 114 (92–128) |
| riverpod | 6/6 | 0.121 (0.113–0.144) | 139,109 (129,671–242,304) | 4,208 (3,724–4,463) | 5 (5–8) | 46 (44–64) | 136 (122–163) |
| bloc | 6/6 | 0.178 (0.141–0.191) | 258,275 (139,538–301,674) | 6,359 (5,181–6,768) | 8 (5–9) | 52 (35–60) | 194 (165–283) |

