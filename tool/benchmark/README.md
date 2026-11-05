# Runtime overhead benchmark

Compares three ways of giving each screen its own controller that gets a service from the app:

| Implementation | Pattern |
|---|---|
| `plain` | `StatefulWidget` creates the controller in `initState` from a global service, disposes it in `dispose` — the hand-written lower bound. |
| `rack` | `RackWidget` + `rack.module<M5>()` under a `RackProvider` with 10 modules. |
| `provider` | `Provider<Controller>(create: (c) => Controller(c.read<S5>()), dispose: …)` under a `MultiProvider` with 10 services — the usual provider pattern. |

1000 screens are mounted, rebuilt with new widget instances, and unmounted, 200 rounds after 20 warm-up rounds. Each step is timed synchronously around `BuildOwner.buildScope` + `finalizeTree`, so the numbers contain exactly the widget/element work — no layout, paint or vsync wait. Reported: median µs per screen.

```sh
cd tool/benchmark
fvm flutter build macos --release
./build/macos/Build/Products/Release/rack_benchmark.app/Contents/MacOS/rack_benchmark
```

## Results

Flutter 3.47.8, release build, Apple Silicon Mac, macOS 27, three runs (median µs per screen, range in brackets):

| | mount | rebuild | unmount |
|---|---|---|---|
| plain | 0.65 (0.63–0.68) | 0.14 (0.13–0.14) | 1.07 (1.01–1.11) |
| **rack** | **0.79 (0.78–0.80)** | **0.17 (0.16–0.18)** | **1.12 (1.04–1.15)** |
| provider | 1.38 (1.34–1.39) | 0.36 (0.35–0.38) | 0.90 (0.90–0.92) |

- rack costs about 0.15 µs per screen more than the hand-written `StatefulWidget` when mounting, and is within noise on unmount.
- Compared with the provider pattern, rack mounts about 40 % and rebuilds about 50 % faster; provider unmounts about 20 % faster.
- In absolute terms all three are below 1.5 µs per screen — 1000 screens take about a millisecond. Runtime performance is not a reason to pick or avoid any of them; rack simply adds no meaningful overhead.
