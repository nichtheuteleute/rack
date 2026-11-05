# Agent benchmark results

Run on 2026-11-05 with Claude Code 2.1.318, model alias `sonnet` (Claude Sonnet 5.5), Flutter 3.47.8. Small suite: 72 runs (4 tasks × 3 variants × 6 runs), $7.21. Large suite: 18 runs (2 tasks × 3 variants × 3 runs), $1.52. Method and limits: [README.md](README.md). Raw data: `results/*.jsonl`.

## Small suite (original app, ~3,000 tokens of code per variant)

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

## Small suite per task

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

## Large suite (five more features, 16,000–22,000 tokens per variant)

To check whether rack's explicit wiring reduces search effort once the code base no longer fits into one `cat`, the three variants were extended by their original authors with profile, activity log, archive, export and search (`spec_large/`, `variants_large/`). Two tasks (`tasks_large/`):

- `L1_archive_activity` — the activity log must also record archiving and restoring: adds a **new dependency between two existing features**.
- `L2_fix_reopen_activity` — bug report "un-checking a note logs *Completed* again"; the same bug is injected into each variant, revealing tests are weakened alike.

| variant | lib tokens (hand-written) | generated tokens | lib files |
|---|---|---|---|
| rack | 8,538 | – | 35 |
| riverpod | 6,857 | 7,160 | 23 (+7 generated) |
| bloc | 11,570 | – | 45 |

#### L1_archive_activity

| variant | solved | cost $ | context tok | output tok | turns | time s | lines changed |
|---|---|---|---|---|---|---|---|
| rack | 3/3 | 0.166 (0.125–0.172) | 193,165 (173,578–300,109) | 7,106 (4,423–7,145) | 7 (6–10) | 47 (41–57) | 132 (129–151) |
| riverpod | 2/3 | 0.081 (0.079–0.089) | 130,559 (108,902–166,951) | 1,636 (1,597–1,673) | 5 (4–6) | 21 (21–22) | 27 (27–162) |
| bloc | 3/3 | 0.086 (0.082–0.089) | 127,828 (126,771–129,487) | 2,177 (2,130–2,202) | 5 (5–5) | 22 (22–25) | 53 (47–57) |

#### L2_fix_reopen_activity

| variant | solved | cost $ | context tok | output tok | turns | time s | lines changed |
|---|---|---|---|---|---|---|---|
| rack | 3/3 | 0.055 (0.049–0.057) | 138,378 (133,411–138,583) | 1,027 (1,024–1,032) | 6 (6–6) | 17 (17–18) | 11 (11–11) |
| riverpod | 3/3 | 0.052 (0.051–0.074) | 113,116 (111,988–175,972) | 947 (943–1,392) | 5 (5–7) | 19 (18–31) | 13 (12–14) |
| bloc | 3/3 | 0.069 (0.069–0.072) | 148,383 (146,167–167,072) | 1,601 (1,509–1,623) | 8 (7–9) | 20 (20–20) | 21 (16–24) |

#### Both tasks: sum of per-task medians

| variant | solved | cost $ | context tok | output tok | turns | time s | lines changed |
|---|---|---|---|---|---|---|---|
| rack | 6/6 | 0.221 | 331,543 | 8,133 | 13 | 64 | 143 |
| riverpod | 5/6 | 0.133 | 243,675 | 2,583 | 10 | 40 | 40 |
| bloc | 6/6 | 0.155 | 276,211 | 3,778 | 13 | 43 | 74 |


**Reading**

- **Adding a new dependency between features is where rack is weakest.** For L1, rack cost about twice as much as Riverpod and Bloc ($0.166 vs. $0.081 / $0.086 median) and changed about 130 lines in 6 files: the activity module's constructor, new event types, the archive store, the composition root in `main.dart` and tests. Riverpod needed one `ref.read(activityLogProvider)` in the archive notifier (27 lines, 2 files); Bloc's central repository already broadcast changes (53 lines, 4 files). Compile-checked constructor wiring has a price whenever the dependency graph changes.
- Bug fixing (L2) was cheap everywhere; rack and Riverpod were on par, Bloc slightly more expensive.
- The unsolved Riverpod run only reformatted the shared data files (`dart format`), which the rules forbid; its feature work was correct.
- In none of the 90 runs did an agent open rack's own README or source — the project's README was enough.

## Overall conclusion

Token usage is **not** an advantage of rack. On the small app rack was on par with Riverpod and cheaper than Bloc; on the larger app rack was clearly more expensive when a new cross-feature dependency had to be wired. What holds across all runs: agents solved every rack task (30/30; Riverpod 29/30, Bloc 29/30) without needing rack's documentation.

