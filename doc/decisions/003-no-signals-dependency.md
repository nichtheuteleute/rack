# ADR 003: Keine Abhängigkeit zu signals

**Status:** Akzeptiert.

## Context

`RackWidget` baute `buildContent` bisher in einem `Watch` aus `signals_flutter` auf. Signale, die direkt in `buildContent` gelesen wurden, lösten so automatisch einen Rebuild aus. Daraus folgten mehrere Probleme:

- **Halbe Automatik:** Der `Watch` erfasst nur Lesezugriffe direkt in `buildContent`. Kind-Widgets, die ein Signal lesen, brauchen trotzdem einen eigenen Mechanismus (`.watch(context)`, `SignalBuilder`). Wann man selbst etwas tun muss, ist nicht offensichtlich.
- **Grobe Rebuilds:** Jede Signal-Änderung baut den gesamten Screen neu, statt nur den Teil, der das Signal liest.
- **Kopplung an eine Library:** rack war an die Major-Version von signals gebunden. Mit signals 7 wurde `Watch` deprecated; Apps mit einer anderen signals-Version konnten rack nicht einbinden.
- rack beschreibt sich als „State management is not Rack's job“, schrieb aber eine State-Library vor.

## Entscheidung

rack hängt nur noch von Flutter ab. `RackWidget.buildContent` ist eine normale Build-Methode ohne Tracking. Wer reaktive State-Typen nutzt, wrappt die lesenden Teile selbst in den passenden Builder (`SignalBuilder`, `ValueListenableBuilder`, `StreamBuilder`, …).

## Begründung

- **Ein Mechanismus statt zwei:** Reaktivität entsteht immer an der Stelle, an der gelesen wird — im Screen und in Kind-Widgets gleich.
- **Feinere Rebuilds:** Nur der gewrappte Teil baut neu.
- **Keine Versionskonflikte:** Apps wählen ihre signals-Version (oder eine andere Library) frei.
- **Klarer Scope:** rack ist DI + Lifecycle, nicht State Management.

## Konsequenzen

- Ein Signal, das in `buildContent` ohne Builder gelesen wird, löst keinen Rebuild mehr aus. Bestehende Screens müssen die lesenden Teile wrappen.
- Beispiele und README zeigen `SignalBuilder` explizit.
