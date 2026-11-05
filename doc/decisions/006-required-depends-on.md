# ADR 006: `dependsOn` ist Pflicht

**Status:** Akzeptiert. Ersetzt den optionalen Getter aus [ADR 004](004-parallel-init.md) und macht [ADR 005](005-auto-register-dependencies.md) für alle Module wirksam.

## Context

Mit ADR 004/005 war `dependsOn` ein optionaler Getter. Ohne Override galt: Das Modul wartet auf alle zuvor gelisteten Module, und fehlende Abhängigkeiten werden nicht automatisch registriert. Der Schutz vor vergessenen Abhängigkeiten griff also nur, wenn man an ihn dachte — genau die Disziplin, die er ersetzen soll. Zudem gab es zwei Modi (Listenreihenfolge vs. Abhängigkeiten), die beide erklärt werden mussten.

## Entscheidung

`RackModule` hat einen Konstruktor mit dem Pflichtparameter `dependsOn`:

```dart
class FilesModule extends RackModule {
  FilesModule(this.settings) : super(dependsOn: [settings]);
  final SettingsModule settings;
}

class SettingsModule extends RackModule {
  SettingsModule() : super(dependsOn: const []);
}
```

- Ein Modul ohne `dependsOn` kompiliert nicht.
- Die Reihenfolge in `RackProvider.modules` spielt keine Rolle mehr; es gibt nur noch den Abhängigkeits-Modus (ADR 004) mit automatischer Registrierung (ADR 005).
- Die Liste wird beim Konstruieren kopiert. Zyklen sind über Konstruktoren nicht baubar; die Zyklus-Erkennung bleibt für Unterklassen, die den Getter überschreiben.

## Begründung

- **Explizit statt optional:** Jede Abhängigkeit eines Moduls steht sichtbar an genau einer Stelle — in der Konstruktorzeile, direkt neben den Parametern.
- **Ein Modus:** Kein „vor mir Gelistetes zählt als Abhängigkeit“ mehr, keine Reihenfolge-Regel in der Liste.
- **Jetzt oder nie:** rack ist noch nicht veröffentlicht; nach 0.1.0 wäre das ein Breaking Change.

## Alternativen

- **Abstrakter Getter** (`@override List<RackModule> get dependsOn`): ebenso erzwungen, steht aber getrennt vom Konstruktor und kostet mehr Zeilen. Verworfen.
- **Abhängigkeiten aus den Konstruktor-Argumenten ableiten:** ohne Reflection oder Code-Generierung nicht möglich. Verworfen.

## Konsequenzen

- Der Compiler erzwingt, *dass* `dependsOn` angegeben ist, nicht dass es vollständig ist. Ein Konstruktor-Argument, das in `dependsOn` fehlt, kann vor seiner Abhängigkeit initialisiert werden. Die README-Regel verlangt deshalb, `dependsOn` in derselben Zeile wie den Konstruktor zu schreiben.
- Module ohne Abhängigkeiten brauchen einen Konstruktor mit `super(dependsOn: const [])`.
