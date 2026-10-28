# ADR 001: Live-Lookup statt Snapshot im init()-Rack

**Status:** Superseded durch [ADR 002](002-typed-modules.md). `Rack.fromLookup`, `registerInstance` und die `_services`-Map existieren nicht mehr; die hier beschriebene Frage stellt sich mit typisierten Modulen nicht mehr.

## Context

`RackProvider._setup()` baut einen `Rack`-Objekt und übergibt es an `module.init()`. Module können darin Services lesen via `rack.read<T>()`.

Mit der Einführung von `rack.registerInstance<T>()` (für async-konstruierte Services) entstand die Frage: wenn ein Modul in `init()` eine neue Instanz registriert — kann das nächste Modul sie sofort lesen?

## Die zwei Optionen

**Option A — Snapshot:**
```dart
// Services in eine neue Map kopieren
final allServices = {...parent?.services, ..._services};
final rack = Rack.fromLookup((type) => allServices[type]);
```
`allServices` ist eine Kopie zum Zeitpunkt des `_setup()`-Starts. Spätere `registerInstance`-Aufrufe schreiben in `_services`, aber nicht in `allServices`. Module die danach `init()` laufen, sehen die neue Instanz nicht.

**Option B — Live-Lookup (gewählt):**
```dart
final rack = Rack.fromLookup(
  (type) => _services[type] ?? parent?.services[type],
  register: (type, instance) => _services[type] = instance,
);
```
`_services` wird direkt referenziert, nicht kopiert. `registerInstance` schreibt in dieselbe Map, die alle `read<T>()`-Calls befragen. Änderungen sind sofort sichtbar.

## Entscheidung

**Live-Lookup (Option B).**

## Begründung

`registerInstance` ist nur dann sinnvoll, wenn die registrierte Instanz für nachfolgende Module verfügbar ist. Andernfalls könnte man direkt im `FilesStore`-Konstruktor initialisieren, statt auf `init()` zu warten.

Mit Snapshot wäre `registerInstance` nutzlos für Inter-Modul-Abhängigkeiten. Der Wrapper-Workaround (`SwitchableFileSource`) wäre weiterhin nötig.

## Konsequenzen

- Module können in `init()` Instanzen registrieren, die andere Module (in Reihenfolge dahinter) sofort lesen können.
- Die Modulreihenfolge bleibt weiterhin relevant — ein Modul kann nur lesen, was vorherige Module bereits registriert haben.
- `_services` wird während `_setup()` mutiert. Das ist sicher, da `_setup()` sequenziell (await pro Modul) läuft.
- Parent-Services (`parent?.services`) sind read-only — ein Modul kann keine Parent-Services überschreiben via `registerInstance` (es landet in `_services`, Parent-Map bleibt unberührt).
