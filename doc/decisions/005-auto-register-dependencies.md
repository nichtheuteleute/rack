# ADR 005: Deklarierte Abhängigkeiten automatisch registrieren

**Status:** Teilweise ersetzt durch [ADR 006](006-required-depends-on.md): `dependsOn` ist Pflicht, der Default `null` (Listenreihenfolge) entfällt.

## Context

Der Verdrahtungs-Check (`tool/wiring_check`) hat jeden Verdrahtungsschritt der Benchmark-App einzeln entfernt. Abhängigkeiten zwischen Modulen waren bei rack immer Compile-Fehler. Die Lücke war die Modulliste von `RackProvider`: Ein Modul, das gebaut und per Konstruktor weitergereicht, aber nicht gelistet wird, bekommt nie sein `init()`. Die App lief dann mit ungeladenen Daten weiter — ein teilweise stiller Fehler — und brach erst ab, wenn ein Screen das Modul per Typ nachschlug.

Seit ADR 004 nennen Module ihre Abhängigkeiten in `dependsOn`. Diese Information reicht, um die Lücke zu schließen.

## Entscheidung

- `RackProvider` ergänzt die Liste um jedes Modul, das ein Modul (transitiv) in `dependsOn` nennt und das weder gelistet noch von einem übergeordneten Provider bereitgestellt ist. Es wird direkt vor dem ersten Modul eingereiht, das es braucht, initialisiert, per `rack.module<T>()` bereitgestellt und mit dem Provider disposed.
- Dieselbe Instanz in einem übergeordneten Provider gilt als bereitgestellt und wird nicht erneut initialisiert.
- Zwei *verschiedene* Instanzen desselben Modultyps in einem Provider sind ein Fehler (`StateError` über `errorBuilder`). Bisher gewann still die zuletzt gelistete.

## Begründung

- Die Abhängigkeit steht bereits explizit am Modul; sie ein zweites Mal in die Liste zu schreiben, ist eine vergessbare Doppelung.
- Mit `dependsOn` bleibt nur ein Laufzeitfall: ein Modul, von dem kein anderes abhängt, fehlt in der Liste. Der Screen, der es nachschlägt, scheitert dann beim ersten Build mit einer Meldung, die das Modul nennt — für Start-Screens also sofort.
- Die Prüfung auf doppelte Typen fängt den typischen Fehler „Modul zweimal erzeugt“, der sonst zu zwei getrennten Zuständen führt.

## Konsequenzen

- Ohne `dependsOn` ändert sich nichts an der Registrierung; nur die Prüfung auf doppelte Typen ist neu.
- Wer bisher absichtlich zwei Instanzen eines Modultyps in einen Provider gelegt hat, bekommt jetzt einen Fehler und muss einen verschachtelten Provider verwenden.
