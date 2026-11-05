# Agent benchmark: how much does an AI coding agent spend per task?

Question: do code bases built with rack let a coding agent finish tasks with fewer tokens, less money and less time than equivalent code bases built with Riverpod or Bloc?

## Setup

- **One app, three variants.** `spec/APP_SPEC.md` describes a small notes app (async startup, notes list with add / toggle / filter, settings screen, notes depend on settings). It was built three times — `variants/rack` (rack + signals), `variants/riverpod` (Riverpod 3 with code generation), `variants/bloc` (flutter_bloc) — each by a separate agent that was told to follow the library's official best practices and could not see the other variants. All three share the data layer (`spec/shared`), pass the same acceptance test (`spec/acceptance`), use the same lint rules and have a README with an architecture section of at most 40 lines.
- **Four tasks** (`tasks/`), worded identically for every variant and without naming the library:
  1. `01_delete_note` — small end-to-end feature (key, state, UI, persistence).
  2. `02_stats_screen` — new feature that reads state of two existing features.
  3. `03_fix_toggle_persist` — find and fix a bug from a user report. The same bug is injected into each variant (`inject.py`), and the tests that would reveal it directly are weakened the same way.
  4. `04_hide_done_setting` — new persisted setting that changes another feature's behaviour.
- **Runs.** `run.py` copies the variant to a fresh git repo outside this repository and runs Claude Code headless (`claude -p`, model alias `sonnet`, no skills, no MCP servers, no project settings, no session persistence). Runs are sequential (parallel runs interfered with each other through Flutter's startup lock and `pkill`), and tasks and variants are interleaved.
- **Grading.** After the agent finishes, the task's hidden test and the *original* acceptance test are added; a run counts as solved if they pass, all of the project's tests pass, `flutter analyze` is clean, and the shared data layer is untouched (unless the task asks to change it).
- **Metrics** (from the `result` event of the stream): cost in USD, context tokens (all input tokens incl. cache reads — what the model had to read), output tokens, turns, agent time, lines changed (excluding generated `*.g.dart` and `pubspec.lock`).

```sh
python3 -I tool/agent_bench/run.py 01_delete_note --runs 6 --parallel 1
python3 -I tool/agent_bench/report.py
python3 -I tool/agent_bench/code_size.py tool/agent_bench/variants/*
```

## Limits — read before quoting numbers

- **Small code base.** Each variant is about 3,000 tokens of hand-written code. An agent can read all of it in one or two commands, so differences in *search* effort barely show up. Larger apps may behave differently, in either direction.
- **Model prior knowledge.** The model knows Riverpod and Bloc from training; rack it only knows from the project's README. That is a realistic condition for a new library, but it is not the same condition.
- **One model, one agent, one app.** Results are for Claude Sonnet in Claude Code on this app. Six runs per cell show the spread but are not enough for strong statistical claims.
- **Variants written by agents.** Each followed its library's docs, but "idiomatic" is a judgement call. The variants are in this folder for anyone to review.

## Code size of the variants

From `code_size.py` (tokens ≈ characters / 4, shared files excluded):

| variant | lib files | lib lines | lib tokens | generated tokens | test lines | README tokens |
|---|---|---|---|---|---|---|
| rack | 13 | 339 | 3,083 | – | 105 | 725 |
| riverpod | 8 | 289 | 2,625 | 2,733 (2 files) | 123 | 664 |
| bloc | 15 | 464 | 3,991 | – | 136 | 783 |

## Results

See [RESULTS.md](RESULTS.md).
