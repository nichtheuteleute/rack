# ADR 004: Parallele Initialisierung über `dependsOn`

**Status:** Akzeptiert.

## Context

`RackProvider` hat `init()` aller Module strikt nacheinander in Listenreihenfolge ausgeführt. Das ist einfach und sicher, macht den App-Start aber so lang wie die Summe aller Ladezeiten. Im Agenten-Benchmark (tool/agent_bench) lud eine App mit fünf Modulen à 50 ms deshalb 250 ms, die Riverpod- und Bloc-Varianten derselben App 50 ms.

rack kennt die Abhängigkeiten zwischen Modulen nicht: Sie stehen als Konstruktor-Argumente im Code, sind zur Laufzeit aber nicht auslesbar (keine Reflection, keine Code-Generierung).

## Entscheidung

`RackModule` bekommt einen optionalen Getter `List<RackModule>? get dependsOn`:

- `null` (Default): Das Modul wartet auf alle Module, die vor ihm in derselben `RackProvider`-Liste stehen — exakt das bisherige Verhalten.
- Eine explizite Liste: Das Modul startet, sobald diese Module fertig sind. `const []` heißt „hängt von nichts ab“.

`RackProvider` sortiert die Module topologisch, startet jedes `init()`, sobald seine Abhängigkeiten abgeschlossen sind, und meldet Zyklen als `StateError` über `errorBuilder`. Abhängigkeiten, die nicht im selben Provider liegen (z. B. aus einem Parent-Provider), sind bereits initialisiert und werden ignoriert. Schlägt ein `init()` fehl, starten die davon abhängigen Module nicht.

## Begründung

- **Rückwärtskompatibel:** Ohne Override ändert sich nichts. Parallelität ist pro Modul opt-in; wer `dependsOn` nicht überschreibt, kann kein Race bekommen.
- **Explizit wie der Rest von rack:** Die Abhängigkeit steht sichtbar am Modul, typisiert auf die Instanz — keine Strings, keine Typ-Lookups.
- **Listenreihenfolge wird unwichtig,** sobald alle Module ihre Abhängigkeiten deklarieren.

## Alternativen

- **Immer parallel, Module warten selbst** (`await settings.ready` in `init()`): schneller per Default, aber ein vergessenes `await` ist ein stilles Race. Verworfen.
- **Flag `RackProvider(parallel: true)`:** Ohne Abhängigkeitsangaben wäre unklar, was parallel laufen darf. Verworfen.

## Konsequenzen

- Die Abhängigkeit eines Moduls steht bei paralleler Initialisierung zweimal im Code: als Konstruktor-Argument und in `dependsOn`. Wird ein Konstruktor-Argument ergänzt, aber nicht in `dependsOn` eingetragen, startet das Modul womöglich zu früh. Die README-Regel nennt beides zusammen.
