# ADR 003: Keine Abhängigkeit zu signals

**Status:** Akzeptiert.

## Context

`RackWidget` baute `buildContent` bisher in einem `Watch` aus `signals_flutter` auf. Signale, die direkt in `buildContent` gelesen wurden, lösten so automatisch einen Rebuild aus. Dabei zeigten sich folgende Schwächen:

- **Halbe Automatik:** Der `Watch` erfasst nur Lesezugriffe direkt in `buildContent`. Kind-Widgets, die ein Signal lesen, brauchten trotzdem einen eigenen Mechanismus (`.watch(context)`). Wann man selbst etwas tun muss, war nicht offensichtlich.
- **Gegen die Empfehlung von signals selbst:** signals 7 markiert `Watch`, `WatchBuilder`, `SignalsMixin` und `.watch(context)` als deprecated. Empfohlen werden `SignalBuilder` „so klein und blattnah wie möglich“ sowie `SignalWidget`/`SignalStatefulWidget`, die Lesezugriffe direkt am Element tracken. Ein Wrap um den ganzen Screen ist genau das Muster, das abgelöst wird.
- **API-Wechsel:** signals hatte in kurzer Folge mehrere Majors (6.0 im November 2024, 7.0 im Mai 2026) mit größeren Deprecations. Eine harte Abhängigkeit hätte rack jeden dieser Wechsel mitmachen lassen; der Ersatz `SignalBuilder` existiert erst ab 7, ein breiter Versionsbereich wäre nur mit deprecated API möglich gewesen.
- rack beschreibt sich als „State management is not Rack's job“, schrieb aber eine State-Library vor.

## Entscheidung

rack hängt nur noch von Flutter ab. `RackWidget.buildContent` ist eine normale Build-Methode ohne Tracking. Wer reaktive State-Typen nutzt, wrappt die lesenden Teile selbst in den passenden Builder (`SignalBuilder`, `ValueListenableBuilder`, `StreamBuilder`, …) oder nutzt reaktive Widgets wie `SignalWidget`.

Die empfohlene Nutzung mit signals steht im README unter „Using Rack with signals“.

## Begründung

- **Ein Mechanismus statt zwei:** Reaktivität entsteht immer dort, wo gelesen wird — im Screen und in Kind-Widgets gleich, so wie signals 7 es vorsieht.
- **Feinere Rebuilds:** Nur der gewrappte Teil baut neu.
- **Freie Versionswahl:** Apps wählen ihre signals-Version (oder eine andere Library) selbst.
- **Klarer Scope:** rack ist DI + Lifecycle, nicht State Management.
- **Umkehrbar in die richtige Richtung:** Eine Automatik später wieder einzubauen bricht keinen bestehenden Code (ein zusätzlicher `SignalBuilder` schadet nicht). Sie nach einem Release zu entfernen wäre ein Breaking Change.

## Konsequenzen

- **Stiller Fehler:** Ein Signal, das ohne Builder oder reaktives Widget gelesen wird, löst keinen Rebuild aus — ohne Fehlermeldung und ohne Lint. Das ist der wichtigste Nachteil. Gegenmaßnahmen:
  - Die README-Regel „Every reactive read in the UI is wrapped“.
  - Widget-Tests, die einen Zustand ändern und den neuen Wert erwarten.
  - Optional eine app-eigene Basisklasse `SignalRackWidget`, die `buildContent` in einen `SignalBuilder` legt und so das alte Verhalten für Screens zurückholt (Snippet im README).
- Mehr Code pro Screen als vorher: ein `SignalBuilder` bzw. `SignalWidget` an jeder lesenden Stelle.
- Beispiele und README zeigen `SignalBuilder` und `SignalWidget` explizit.
