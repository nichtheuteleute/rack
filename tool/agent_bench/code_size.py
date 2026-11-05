"""Size of a variant's code base: hand-written code (excl. shared files),
generated code, tests and README. Tokens are estimated as chars / 4."""
import pathlib
import sys

SHARED = {"lib/keys.dart", "lib/data/note.dart", "lib/data/notes_storage.dart",
          "lib/data/settings_storage.dart", "test/acceptance_test.dart"}


def loc(text):
    return sum(1 for l in text.splitlines()
               if l.strip() and not l.strip().startswith("//"))


def measure(root):
    root = pathlib.Path(root)
    out = {"hand": [0, 0, 0], "generated": [0, 0, 0], "tests": [0, 0, 0]}
    for f in sorted(root.rglob("*.dart")):
        rel = f.relative_to(root).as_posix()
        if rel.split("/")[0] not in ("lib", "test") or rel in SHARED:
            continue
        text = f.read_text()
        kind = ("generated" if rel.endswith((".g.dart", ".freezed.dart"))
                else "tests" if rel.startswith("test/") else "hand")
        out[kind][0] += 1
        out[kind][1] += loc(text)
        out[kind][2] += len(text) // 4
    readme = root / "README.md"
    out["readme_tokens"] = len(readme.read_text()) // 4 if readme.exists() else 0
    return out


if __name__ == "__main__":
    print(f"{'variant':10} {'lib files':>9} {'lib LOC':>8} {'lib tok':>8} "
          f"{'gen files':>9} {'gen tok':>8} {'test LOC':>8} {'README tok':>10}")
    for path in sys.argv[1:]:
        m = measure(path)
        print(f"{pathlib.Path(path).name:10} {m['hand'][0]:9} {m['hand'][1]:8} "
              f"{m['hand'][2]:8} {m['generated'][0]:9} {m['generated'][2]:8} "
              f"{m['tests'][1]:8} {m['readme_tokens']:10}")
