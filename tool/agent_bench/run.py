"""Runs a coding agent (Claude Code, headless) on one task in every variant
and records cost, effort and outcome.

    python3 -I tool/agent_bench/run.py 01_delete_note --runs 3 --model sonnet

Each run works in a fresh git-initialised copy of the variant outside the
repo, with skills, MCP servers and project settings disabled. Afterwards the
task's hidden test is copied in and `flutter analyze` / `flutter test` decide
whether the task was solved. Results are appended to results/<task>.jsonl.
"""
import argparse
import concurrent.futures
import datetime
import json
import pathlib
import shutil
import subprocess
import time

BENCH = pathlib.Path(__file__).resolve().parent
REPO = BENCH.parent.parent
WORK = pathlib.Path("/tmp/rack-bench")
RACK_SNAPSHOT = WORK / "pkg" / "rack"
VARIANTS = ["rack", "riverpod", "bloc"]
IGNORE = shutil.ignore_patterns(".dart_tool", "build", ".fvm", "_spec")
DATA_FILES = ["lib/data/note.dart", "lib/data/notes_storage.dart",
              "lib/data/settings_storage.dart", "lib/data/profile_storage.dart",
              "lib/data/activity_storage.dart", "lib/data/archive_storage.dart"]
# Suites: "small" (the original app) and "large" (with five more features).
SUITES = {
    "small": {
        "variants": BENCH / "variants",
        "tasks": BENCH / "tasks",
        "acceptance": [BENCH / "spec" / "acceptance" / "acceptance_test.dart"],
    },
    "large": {
        "variants": BENCH / "variants_large",
        "tasks": BENCH / "tasks_large",
        "acceptance": [
            BENCH / "spec" / "acceptance" / "acceptance_test.dart",
            BENCH / "spec_large" / "acceptance" / "acceptance_large_test.dart",
        ],
    },
}
SUITE = SUITES["small"]


def task_dir(task):
    return SUITE["tasks"] / task


def task_config(task):
    p = task_dir(task) / "config.json"
    return json.loads(p.read_text()) if p.exists() else {}


def transcript_path(task, variant, run):
    return WORK / "transcripts" / task / variant / f"{run}.jsonl"


def sh(cmd, cwd, timeout=600):
    try:
        p = subprocess.run(cmd, cwd=cwd, shell=True, capture_output=True,
                           text=True, timeout=timeout)
    except subprocess.TimeoutExpired as e:
        # A hanging command (e.g. a test suite that never finishes) fails.
        out = (e.stdout or b"").decode(errors="replace") if isinstance(
            e.stdout, bytes) else (e.stdout or "")
        return 124, out + f"\nTIMEOUT after {timeout}s"
    return p.returncode, p.stdout + p.stderr


def snapshot_rack():
    """The rack variant depends on rack by path; give it only the package
    files, never the repo (which contains this benchmark)."""
    if RACK_SNAPSHOT.exists():
        shutil.rmtree(RACK_SNAPSHOT)
    RACK_SNAPSHOT.mkdir(parents=True)
    shutil.copytree(REPO / "lib", RACK_SNAPSHOT / "lib")
    for f in ["pubspec.yaml", "README.md", "LICENSE", "CHANGELOG.md"]:
        shutil.copy(REPO / f, RACK_SNAPSHOT / f)


def prepare(task, variant, run):
    d = WORK / "runs" / task / variant / str(run)
    if d.exists():
        shutil.rmtree(d)
    shutil.copytree(SUITE["variants"] / variant, d, ignore=IGNORE)
    inject = task_dir(task) / "inject.py"
    if inject.exists():
        code, out = sh(f"python3 -I '{inject}' {variant} '{d}'", BENCH)
        assert code == 0, out
    code, out = sh("fvm flutter pub get", d)
    assert code == 0, out
    sh("git init -q && git add -A && git -c user.name=bench "
       "-c user.email=bench@localhost commit -qm baseline", d)
    return d


def run_agent(d, transcript, prompt, model, timeout_s):
    cmd = ["claude", "-p", prompt, "--model", model,
           "--output-format", "stream-json", "--verbose",
           "--dangerously-skip-permissions",
           "--setting-sources", "project",
           "--strict-mcp-config", "--disable-slash-commands",
           "--no-session-persistence"]
    start = time.time()
    transcript.parent.mkdir(parents=True, exist_ok=True)
    with open(transcript, "w") as log:
        try:
            subprocess.run(cmd, cwd=d, stdout=log, stderr=subprocess.STDOUT,
                           timeout=timeout_s)
            timed_out = False
        except subprocess.TimeoutExpired:
            timed_out = True
    return time.time() - start, timed_out


def parse_transcript(path):
    """Sums up a stream-json transcript. A session can emit several `result`
    events (the agent resumes after background commands): cost is cumulative,
    turns, duration and tokens are per segment and are summed."""
    tools, read_chars, results = {}, 0, []
    for line in path.read_text().splitlines():
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            continue
        if ev.get("type") == "assistant":
            for block in ev["message"].get("content", []):
                if block.get("type") == "tool_use":
                    tools[block["name"]] = tools.get(block["name"], 0) + 1
        elif ev.get("type") == "user":
            content = ev.get("message", {}).get("content", [])
            for block in content if isinstance(content, list) else []:
                if block.get("type") == "tool_result":
                    c = block.get("content")
                    if isinstance(c, list):
                        c = "".join(x.get("text", "") for x in c
                                    if isinstance(x, dict))
                    read_chars += len(c or "")
        elif ev.get("type") == "result":
            results.append(ev)

    def total(key):
        return sum(r.get("usage", {}).get(key) or 0 for r in results)

    return {
        "cost_usd": max((r.get("total_cost_usd") or 0 for r in results),
                        default=None),
        "turns": sum(r.get("num_turns") or 0 for r in results),
        "agent_duration_s": sum(r.get("duration_ms") or 0 for r in results)
        / 1000,
        "result_segments": len(results),
        "input_tokens": total("input_tokens"),
        "cache_creation_tokens": total("cache_creation_input_tokens"),
        "cache_read_tokens": total("cache_read_input_tokens"),
        "output_tokens": total("output_tokens"),
        # Everything the model had to read, cached or not.
        "context_tokens": total("input_tokens")
        + total("cache_creation_input_tokens")
        + total("cache_read_input_tokens"),
        "tool_calls": tools,
        "tool_calls_total": sum(tools.values()),
        "tool_result_chars": read_chars,
        "is_error": any(r.get("is_error") for r in results),
    }


def evaluate(d, task):
    allowed = set(task_config(task).get("allow_changed", []))
    data_ok = all(sh(f"git diff --quiet HEAD -- {f}", d)[0] == 0
                  for f in DATA_FILES if f not in allowed)
    # The agent may extend the project's tests; the original acceptance test
    # and the task's hidden test are added as separate files.
    originals = []
    for i, src in enumerate(SUITE["acceptance"]):
        name = f"zz_acceptance_original_{i}_test.dart"
        shutil.copy(src, d / "test" / name)
        originals.append(name)
    shutil.copy(task_dir(task) / "hidden_test.dart",
                d / "test" / "zz_hidden_test.dart")
    analyze_code, analyze_out = sh("fvm flutter analyze", d)
    test_code, test_out = sh("fvm flutter test", d)
    hidden_code, hidden_out = sh(
        "fvm flutter test test/zz_hidden_test.dart "
        + " ".join(f"test/{n}" for n in originals), d)
    for f in originals + ["zz_hidden_test.dart"]:
        (d / "test" / f).unlink()
    sh("git add -A", d)
    _, stat = sh("git diff --cached --shortstat HEAD -- . "
                 "':(exclude)pubspec.lock' ':(exclude)*.g.dart'", d)
    _, files = sh("git diff --cached --name-only HEAD", d)
    return {
        "solved": hidden_code == 0 and test_code == 0 and analyze_code == 0
        and data_ok,
        "hidden_and_acceptance_passed": hidden_code == 0,
        "all_tests_passed": test_code == 0,
        "analyze_clean": analyze_code == 0,
        "data_layer_ok": data_ok,
        "diff": stat.strip(),
        "changed_files": files.split(),
        "analyze_tail": analyze_out.strip().splitlines()[-3:],
        "hidden_tail": hidden_out.strip().splitlines()[-3:],
    }


def one(task, variant, run, model, timeout_s):
    d = prepare(task, variant, run)
    prompt = (task_dir(task) / "prompt.md").read_text()
    transcript = transcript_path(task, variant, run)
    wall, timed_out = run_agent(d, transcript, prompt, model, timeout_s)
    rec = {"task": task, "variant": variant, "run": run, "model": model,
           "timestamp": datetime.datetime.now().isoformat(timespec="seconds"),
           "wall_s": round(wall, 1), "timed_out": timed_out,
           "workdir": str(d), "transcript": str(transcript)}
    rec.update(parse_transcript(transcript))
    rec.update(evaluate(d, task))
    return rec


def reevaluate(task, variant, run, model):
    """Grades an existing work dir again, e.g. after the grader crashed."""
    d = WORK / "runs" / task / variant / str(run)
    transcript = transcript_path(task, variant, run)
    rec = {"task": task, "variant": variant, "run": run, "model": model,
           "timestamp": datetime.datetime.now().isoformat(timespec="seconds"),
           "wall_s": None, "timed_out": False, "workdir": str(d),
           "transcript": str(transcript), "reevaluated": True}
    rec.update(parse_transcript(transcript))
    rec.update(evaluate(d, task))
    return rec


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("task")
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--start", type=int, default=1)
    ap.add_argument("--model", default="sonnet")
    ap.add_argument("--variants", default=",".join(VARIANTS))
    ap.add_argument("--parallel", type=int, default=3)
    ap.add_argument("--timeout", type=int, default=1500)
    ap.add_argument("--suite", choices=sorted(SUITES), default="small")
    ap.add_argument("--reevaluate", action="store_true",
                    help="grade existing work dirs instead of running agents")
    a = ap.parse_args()
    global SUITE
    SUITE = SUITES[a.suite]
    if a.reevaluate:
        out = BENCH / "results" / f"{a.task}.jsonl"
        for v in a.variants.split(","):
            for r in range(a.start, a.start + a.runs):
                rec = reevaluate(a.task, v, r, a.model)
                with open(out, "a") as f:
                    f.write(json.dumps(rec) + "\n")
                print(v, r, "solved", rec["solved"], rec["hidden_tail"])
        return

    snapshot_rack()
    out = BENCH / "results" / f"{a.task}.jsonl"
    out.parent.mkdir(exist_ok=True)
    # Interleave variants so time-of-day effects hit all of them alike.
    jobs = [(a.task, v, r, a.model, a.timeout)
            for r in range(a.start, a.start + a.runs)
            for v in a.variants.split(",")]
    with concurrent.futures.ThreadPoolExecutor(a.parallel) as pool:
        for rec in pool.map(lambda j: one(*j), jobs):
            with open(out, "a") as f:
                f.write(json.dumps(rec) + "\n")
            print(f"{rec['variant']:9} run {rec['run']}: "
                  f"solved={rec['solved']} cost=${rec['cost_usd']} "
                  f"turns={rec['turns']} tools={rec['tool_calls_total']} "
                  f"wall={rec['wall_s']}s", flush=True)


if __name__ == "__main__":
    main()
