# What happens when one wiring step is forgotten?

Same notes app in four variants (`tool/agent_bench/variants`: rack, Riverpod, Bloc, provider), each built by a separate agent following its library's best practices. A **wiring step** is a place a developer has to write so that a dependency reaches the code that needs it: root registrations, constructor arguments, listeners/proxies between features. Lookups that are also the usage (`rack.module<T>()`, `ref.watch(x)`, `context.read<T>()` where the result is used) are not counted — they cannot be forgotten without removing the code that needs them.

`run.py` removes each step on its own (`mutations.py`), then runs `flutter analyze`, the full test suite and a startup probe, and classifies the outcome. Run on 2026-11-05, Flutter 3.47.8.

## Summary

| variant | wiring steps | caught by the compiler | runtime error (crash or error screen) | silent wrong behaviour | not detected |
|---|---|---|---|---|---|
| **rack** (current: `dependsOn` required) | 5 | **3** | **1 (at startup, names the module)** | **0** | 1 latent (incomplete `dependsOn`) |
| rack before `dependsOn` was required | 5 | 3 | 2 (one of them partly silent) | 0 | 0 |
| Riverpod | **2** | 0 | 2 | **0** | **0** |
| Bloc | 8 | 2 | 4 | 1 | 1 |
| provider | 7 | 2 | 4 | 1 | 0 |

Since [ADR 006](../../doc/decisions/006-required-depends-on.md) every rack module names its dependencies in the required `super(dependsOn: [...])`, and `RackProvider` registers a dependency that is not listed. Listing a dependency is therefore no longer a step that can be forgotten. A new step appeared instead: keeping `dependsOn` complete. The compiler enforces that it is given, not that it lists every constructor argument. The second rack row is the same variant before the change.

## Per step

| variant | forgotten step | outcome |
|---|---|---|
| rack | settings module not listed in `RackProvider` | **not a step anymore**: registered through `NotesModule`'s `dependsOn`, app works |
| rack | notes module not listed in `RackProvider` | runtime **at startup**: `No module of type NotesModule registered in Rack` |
| rack | notes module does not get the settings module | **compile error** (constructor argument) |
| rack | settings module does not get its storage | **compile error** |
| rack | notes module does not get its storage | **compile error** |
| rack | notes module's `dependsOn` omits the settings module | not detected — harmless here because `NotesModule.init()` does not read the settings; if it did, it could start before the settings are loaded |
| rack | … and the settings module is not listed either | runtime, partly silent: settings never initialized; `No module of type SettingsModule registered in Rack` when the settings screen opens |
| rack before ADR 006 | settings module not listed | runtime, partly silent (as in the row above) |
| rack before ADR 006 | notes module not listed | runtime: `No module of type NotesModule registered in Rack` |
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
- **In rack, every dependency between modules is compile-checked** (constructor arguments), and with the required `dependsOn` a dependency can no longer be left unregistered. What remains: a module nobody depends on but a screen looks up must be listed — forgetting it fails at startup with the module's name — and `dependsOn` has to be kept complete; an incomplete one is not detected and can let a module initialize before its dependency.
- **Riverpod needs the least wiring** (2 steps, both overrides for injected storages). Its feature-to-feature references are compile-checked too, but implicit: you see them only by reading the providers' bodies.
