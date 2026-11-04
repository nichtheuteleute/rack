# ADR 002: Module als typisierte Container statt Service-Registry

**Status:** Akzeptiert. Ersetzt [ADR 001](001-live-lookup-in-init.md).

## Context

Bisher registrierten Module Services zur Laufzeit in einer Map (`rack.register<T>()` in `setup()`), andere Module und Controller lasen sie per `rack.read<T>()`. Daraus folgten mehrere Probleme:

- Abhängigkeiten zwischen Modulen waren unsichtbar und wurden erst zur Laufzeit geprüft — ein fehlender Service fiel erst beim `read<T>()` auf.
- Ob ein Modul eine Instanz sieht, die ein anderes Modul während `setup()` registriert, hing von der Lookup-Strategie ab (Snapshot vs. Live-Lookup, siehe ADR 001).
- Lifecycle und Disposal mussten pro registriertem Service über die Registry laufen.

## Entscheidung

Ein `RackModule` ist ein typisierter Container seiner Services:

- Services sind `late final`-Felder, gewrappt in `use(...)`. `late final` macht sie lazy und single-instance, `use()` registriert sie für das Disposal.
- Ein Modul deklariert Abhängigkeiten zu anderen Modulen als **Konstruktor-Argumente**.
- `RackProvider` bekommt fertige Modul-Instanzen, ruft `init()` sequentiell in Listenreihenfolge auf und legt die Module nach ihrem Runtime-Typ in den Baum.
- Controller lesen Module per `rack.module<T>()` / `rack.moduleOrNull<T>()` und greifen dann typisiert auf deren Felder zu.

`RackSetup`, `setup()`, `register<T>()` und `read<T>()` entfallen.

## Begründung

- **Compile-Sicherheit:** Eine fehlende Modul-Abhängigkeit ist ein Compile-Fehler, kein Laufzeit-Assert.
- **Keine Lookup-Semantik zwischen Modulen:** Module referenzieren sich direkt, die Frage aus ADR 001 entfällt.
- **Async-Konstruktion bleibt möglich:** Ein Service, der async erzeugt werden muss, wird in `init()` einem `late final`-Feld zugewiesen. Durch die sequentielle Initialisierung ist er für nachfolgende Module bereit.
- **Lazy by default:** Services, die nie gelesen werden, werden nie erzeugt und nie disposed.

## Konsequenzen

- Die Modulreihenfolge in `RackProvider` bleibt relevant: ein Modul muss nach den Modulen stehen, deren `init()` es voraussetzt.
- Lookup aus dem Widget-Baum erfolgt pro Modul, nicht pro Service. Ein Controller kennt also das Modul, aus dem ein Store stammt.
- Module werden nach **Runtime-Typ** registriert. Eine Subklasse (z.B. ein Fake im Test) wird unter `module<Basisklasse>()` nicht gefunden. Testbarkeit entsteht über Konstruktor-Parameter des echten Moduls.
- Ein verschachtelter `RackProvider` überschreibt Module desselben Typs aus dem Parent.
- `RackProvider` übernimmt die Ownership der übergebenen Instanzen und disposed sie beim Unmount in umgekehrter Reihenfolge. Module müssen daher einmal erzeugt werden, nicht in einer `build`-Methode.
