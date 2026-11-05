# What happens when one wiring step is forgotten?

Same notes app in four variants (`tool/agent_bench/variants`: rack, Riverpod, Bloc, provider), each built by a separate agent following its library's best practices. A **wiring step** is a place a developer has to write so that a dependency reaches the code that needs it: root registrations, constructor arguments, listeners/proxies between features. Lookups that are also the usage (`rack.module<T>()`, `ref.watch(x)`, `context.read<T>()` where the result is used) are not counted — they cannot be forgotten without removing the code that needs them.

`run.py` removes each step on its own (`mutations.py`), then runs `flutter analyze`, the full test suite and a startup probe, and classifies the outcome. Run on 2026-11-05, Flutter 3.47.8.

## Summary

| variant | wiring steps | caught by the compiler | runtime error (crash or error screen) | silent wrong behaviour | not detected |
|---|---|---|---|---|---|
| rack (no `dependsOn`) | 5 | **3** | 2 (one of them partly silent) | 0 | **0** |
| **rack with `dependsOn`** | **4** | **3** | **1 (at startup, names the module)** | **0** | **0** |
| Riverpod | **2** | 0 | 2 | **0** | **0** |
| Bloc | 8 | 2 | 4 | 1 | 1 |
| provider | 7 | 2 | 4 | 1 | 0 |

`rack with dependsOn` is the same variant with the module dependencies also declared in `RackModule.dependsOn`, as the rack README recommends (`PREPARE` in `mutations.py`). `RackProvider` then registers a declared dependency itself, so listing the settings module is no longer a step that can be forgotten: removing it changes nothing, all tests pass.

## Per step

| variant | forgotten step | outcome |
|---|---|---|
| rack | settings module not listed in `RackProvider` | runtime, **partly silent**: the app starts, but the settings module's `init()` never runs, so the stored setting is ignored without an error; `No module of type SettingsModule registered in Rack` only when the settings screen opens |
| rack | notes module not listed in `RackProvider` | runtime: `No module of type NotesModule registered in Rack` |
| rack | notes module does not get the settings module | **compile error** (constructor argument) |
| rack | settings module does not get its storage | **compile error** |
| rack | notes module does not get its storage | **compile error** |
| rack with `dependsOn` | settings module not listed in `RackProvider` | **not a step anymore**: registered automatically through `NotesModule.dependsOn`, app works |
| rack with `dependsOn` | notes module not listed in `RackProvider` | runtime **at startup**: `No module of type NotesModule registered in Rack` |
| rack with `dependsOn` | the three constructor arguments | **compile errors**, as above |
| Riverpod | notes storage not overridden | runtime: error screen at startup (`ProviderException`) |
| Riverpod | settings storage not overridden | runtime: error screen at startup (`ProviderException`) |
| Bloc | notes storage not provided | runtime: `ProviderNotFoundException` |
| Bloc | settings storage not provided | runtime: `ProviderNotFoundException` |
| Bloc | `SettingsCubit` not provided | runtime: `ProviderNotFoundException` |
| Bloc | settings cubit does not get its storage | **compile error** |
| Bloc | `NotesBloc` not provided on the notes page | runtime: `ProviderNotFoundException` |
| Bloc | notes bloc does not get its storage | **compile error** |
| Bloc | notes bloc does not get the initial sort order | not detected — the listener below happens to cover it today; a latent bug |
| Bloc | notes do not listen to settings changes | **silent**: list keeps the old order, no error |
| provider | notes storage not provided | runtime: `ProviderNotFoundException` |
| provider | settings storage not provided | runtime: `ProviderNotFoundException` |
| provider | `SettingsModel` not provided | runtime: `ProviderNotFoundException` |
| provider | `NotesModel` not provided | runtime: `ProviderNotFoundException` |
| provider | settings model does not get its storage | **compile error** |
| provider | notes model does not get its storage | **compile error** |
| provider | notes model does not get the settings (`ProxyProvider.update`) | **silent**: list keeps the old order, no error |

## Reading

- **Dependencies between features are where the approaches differ.** In rack the notes module takes the settings module as a constructor argument — forgetting it does not compile. In Bloc and provider the same dependency is a listener or proxy update that compiles fine when missing; the app then silently shows stale data. Riverpod has no such step at all: features reference each other's providers directly.
- **In rack, every dependency between modules is compile-checked.** The two runtime cases both come from the module list. One fails immediately with a message naming the missing module; the other (a module that is constructed and passed on, but not listed) runs without its `init()` and fails only when its own screen looks it up — until then it silently works with unloaded data.
- **Riverpod needs the least wiring** (2 steps, both overrides for injected storages). Its feature-to-feature references are compile-checked too, but implicit: you see them only by reading the providers' bodies.
- **With `dependsOn`, rack closes that gap.** `RackProvider` registers declared dependencies itself, so a dependency can no longer be left uninitialized. The one remaining runtime case — a module nobody depends on (the notes module, looked up by its screen) missing from the list — fails at startup with a message naming it. Two different instances of one module type are rejected at startup as well.
