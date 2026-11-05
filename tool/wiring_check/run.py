"""What happens when a developer forgets one wiring step?

    python3 -I tool/wiring_check/run.py [variant ...]

For every mutation in mutations.py, a fresh copy of the variant is patched,
then `flutter analyze` and the full test suite run. Each mutation is
classified as:

- compile error  — the analyzer reports an error: caught before running
- runtime error  — a test throws a non-assertion exception (crash)
- silent bug     — no exception, but tests fail on wrong behaviour
- undetected     — analyzer and all tests pass

Results go to results.json and RESULTS.md next to this script.
"""
import json
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
VARIANTS = HERE.parent / "agent_bench" / "variants"
sys.path.insert(0, str(HERE))
from mutations import MUTATIONS  # noqa: E402


def sh(cmd, cwd, timeout=600):
    try:
        p = subprocess.run(cmd, cwd=cwd, shell=True, capture_output=True,
                           text=True, timeout=timeout)
        return p.returncode, p.stdout + p.stderr
    except subprocess.TimeoutExpired:
        return 124, "TIMEOUT"


def classify(analyze_out, test_code, test_out):
    errors = [l.strip() for l in analyze_out.splitlines()
              if l.strip().startswith("error •")]
    warnings = [l.strip() for l in analyze_out.splitlines()
                if l.strip().startswith(("warning •", "info •"))]
    if errors:
        return "compile error", errors[0], warnings
    thrown = re.findall(r"The following (\S+) was thrown[^\n]*\n(.*)", test_out)
    # "Bad state: No element" comes from flutter_test finders (a widget the
    # test expects is missing), not from the app.
    crashes = [(t, msg.strip()) for t, msg in thrown
               if t != "TestFailure" and "No element" not in msg]
    # Unit tests (no widget binding) print exceptions without that header.
    for m in re.finditer(r"^\s*(Bad state: .*|ProviderNotFoundException.*|"
                         r"UnimplementedError.*|Null check operator.*)$",
                         test_out, re.M):
        if "No element" not in m.group(1):
            crashes.append(("exception", m.group(1).strip()))
    # Some apps catch startup errors and render them instead of crashing.
    shown = re.search(r"PROBE TEXT: (.*(?:Could not|error|Error).*)", test_out)
    if shown and not crashes:
        crashes.append(("shown in UI", shown.group(1).strip()))
    if crashes:
        return "runtime error", f"{crashes[0][0]}: {crashes[0][1]}", warnings
    if test_code != 0:
        failed = re.findall(r"^\s*Expected: (.*)$", test_out, re.M)
        return "silent bug", (failed[0] if failed else "tests failed"), warnings
    return "undetected", "", warnings


def main():
    variants = sys.argv[1:] or list(MUTATIONS)
    results_path = HERE / "results.json"
    results = json.loads(results_path.read_text()) if results_path.exists() else {}
    with tempfile.TemporaryDirectory() as tmp:
        for variant in variants:
            base = pathlib.Path(tmp) / f"{variant}_base"
            shutil.copytree(VARIANTS / variant, base,
                            ignore=shutil.ignore_patterns("build", ".fvm"))
            code, out = sh("fvm flutter pub get", base)
            assert code == 0, out
            rows = []
            for desc, rel, old, new in MUTATIONS[variant]:
                d = pathlib.Path(tmp) / f"{variant}_m"
                if d.exists():
                    shutil.rmtree(d)
                shutil.copytree(base, d)
                f = d / rel
                src = f.read_text()
                assert src.count(old) == 1, f"{variant}: '{desc}' target not unique"
                f.write_text(src.replace(old, new))
                shutil.copy(HERE / "startup_probe_test.dart",
                            d / "test" / "zz_startup_probe_test.dart")
                _, analyze_out = sh("fvm flutter analyze", d)
                test_code, test_out = sh("fvm flutter test", d)
                kind, detail, warnings = classify(analyze_out, test_code, test_out)
                rows.append({"step": desc, "result": kind, "detail": detail[:200],
                             "analyzer_hints": len(warnings)})
                print(f"{variant:9} {kind:14} {desc}  | {detail[:110]}",
                      flush=True)
            results[variant] = rows
    results_path.write_text(json.dumps(results, indent=2) + "\n")


if __name__ == "__main__":
    main()
