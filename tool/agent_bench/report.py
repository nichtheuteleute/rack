"""Summarises results/*.jsonl as Markdown tables.

    python3 -I tool/agent_bench/report.py [--min-run N]
"""
import argparse
import json
import pathlib
import re
import statistics

BENCH = pathlib.Path(__file__).resolve().parent
VARIANTS = ["rack", "riverpod", "bloc"]
METRICS = [
    ("cost_usd", "cost $", "{:.3f}"),
    ("context_tokens", "context tok", "{:,.0f}"),
    ("output_tokens", "output tok", "{:,.0f}"),
    ("turns", "turns", "{:.0f}"),
    ("agent_duration_s", "time s", "{:.0f}"),
    ("diff_lines", "lines changed", "{:.0f}"),
]


def diff_lines(stat):
    return sum(int(n) for n in re.findall(r"(\d+) (?:insertion|deletion)", stat))


def load(min_run):
    rows = []
    for f in sorted((BENCH / "results").glob("*.jsonl")):
        for line in f.read_text().splitlines():
            r = json.loads(line)
            if r["run"] < min_run:
                continue
            r["diff_lines"] = diff_lines(r.get("diff", ""))
            rows.append(r)
    return rows


def cell(values, fmt):
    values = [v for v in values if v is not None]
    if not values:
        return "–"
    med = statistics.median(values)
    if len(values) == 1:
        return fmt.format(med)
    return f"{fmt.format(med)} ({fmt.format(min(values))}–{fmt.format(max(values))})"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--min-run", type=int, default=1)
    a = ap.parse_args()
    rows = load(a.min_run)
    tasks = sorted({r["task"] for r in rows})

    print("Median (min–max) per task and variant.\n")
    for task in tasks:
        print(f"### {task}\n")
        print("| variant | solved | " + " | ".join(m[1] for m in METRICS) + " |")
        print("|---|---|" + "---|" * len(METRICS))
        for v in VARIANTS:
            rs = [r for r in rows if r["task"] == task and r["variant"] == v]
            if not rs:
                continue
            solved = sum(r["solved"] for r in rs)
            print(f"| {v} | {solved}/{len(rs)} | " + " | ".join(
                cell([r.get(k) for r in rs], fmt) for k, _, fmt in METRICS)
                + " |")
        print()

    print("### All tasks: sum of per-task medians\n")
    print("| variant | solved | " + " | ".join(m[1] for m in METRICS) + " |")
    print("|---|---|" + "---|" * len(METRICS))
    for v in VARIANTS:
        rs = [r for r in rows if r["variant"] == v]
        if not rs:
            continue
        sums = []
        for k, _, fmt in METRICS:
            meds = [statistics.median([r[k] for r in rs
                                       if r["task"] == t and r.get(k) is not None])
                    for t in tasks
                    if any(r["task"] == t and r.get(k) is not None for r in rs)]
            sums.append(fmt.format(sum(meds)))
        solved = sum(r["solved"] for r in rs)
        print(f"| {v} | {solved}/{len(rs)} | " + " | ".join(sums) + " |")


if __name__ == "__main__":
    main()
