# ADR 007: Initialisierung in Erzeugungsreihenfolge, ohne `dependsOn`

**Status:** Akzeptiert. Ersetzt [ADR 004](004-parallel-init.md), [ADR 005](005-auto-register-dependencies.md) und [ADR 006](006-required-depends-on.md); die Prüfung auf doppelte Modultypen aus ADR 005 bleibt.

## Context

ADR 004–006 haben Abhängigkeiten zusätzlich zu den Konstruktor-Argumenten in `dependsOn` deklarieren lassen — für parallele Initialisierung und automatische Registrierung. Damit stand jede Abhängigkeit zweimal im Code. Der Compiler konnte erzwingen, *dass* `dependsOn` angegeben ist, aber nicht, dass es vollständig ist: Ein vergessener Eintrag blieb unentdeckt und konnte ein Modul vor seiner Abhängigkeit starten lassen — still und timing-abhängig. Das zu schließen hätte ein eigenes Lint-Paket gebraucht. Außerdem machte `super(dependsOn: …)` jede Moduldefinition länger.

## Entscheidung

- `dependsOn` entfällt. Ein Modul nennt seine Abhängigkeiten nur noch als Konstruktor-Argumente.
- `RackModule` merkt sich beim Erzeugen eine fortlaufende Nummer. `RackProvider` initialisiert seine Module **nacheinander in Erzeugungsreihenfolge**. Eine Abhängigkeit muss existieren, bevor sie einem Konstruktor übergeben werden kann; die Erzeugungsreihenfolge ist deshalb immer eine gültige Abhängigkeitsreihenfolge. Die Reihenfolge der Liste spielt keine Rolle.
- Jedes Modul muss in einem `RackProvider` stehen. `use()` wirft einen `StateError` mit dem Modulnamen, wenn ein Modul benutzt wird, während ein `RackProvider` gemountet ist, aber keiner es bereitstellt — typischerweise beim ersten Zugriff im `init()` des abhängigen Moduls, also beim Start. Ohne gemounteten Provider (z. B. in Unit-Tests) gibt es keine Prüfung.
- Weiterhin Fehler über `errorBuilder`: zwei verschiedene Instanzen eines Modultyps in einem Provider; ein Modul, das bereits ein anderer Provider bereitstellt.

## Begründung

- **Eine Quelle der Wahrheit:** Abhängigkeiten stehen genau einmal im Code, im Konstruktor. Es gibt nichts, das auseinanderlaufen kann — und kein Werkzeug, das es prüfen muss.
- **Korrekt ohne Disziplin:** Die Initialisierungsreihenfolge ergibt sich aus dem Code selbst.
- **Schlanke API:** Module brauchen keinen Konstruktor, wenn sie keine Abhängigkeiten haben.
- **Laut statt still:** Ein vergessenes Modul fällt beim ersten Zugriff mit Namen auf, statt mit ungeladenen Daten weiterzulaufen.

## Konsequenzen

- **Keine parallele Initialisierung.** Die Startzeit ist die Summe aller `init()`-Laufzeiten. Unabhängige Ladevorgänge innerhalb eines Moduls lassen sich mit `Future.wait` bündeln; Netzwerkarbeit gehört ohnehin nicht in den Start. Parallelität kann später als Opt-in zurückkommen, falls sie gebraucht wird.
- **Keine automatische Registrierung.** Jedes Modul muss gelistet werden. Ein vergessenes Modul fällt erst beim ersten `use()` auf; ein Modul ohne `use()`-Stores, dessen `init()` nur Felder setzt, wirft beim Zugriff eine `LateInitializationError`.
- Die Prüfung in `use()` greift nur, solange irgendein `RackProvider` gemountet ist. Ein Modul, das vor dem ersten Provider (z. B. in `main()`) benutzt wird, wird nicht geprüft.
