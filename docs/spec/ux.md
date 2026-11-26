# UX

- Listen laden 25 Einträge pro Seite, neueste zuerst, und unterstützen
  Pull-to-Refresh.
- Suche läuft serverseitig und startet 300 ms nach der letzten Eingabe.
- Formulare markieren Zahlen beim Fokus vollständig und begrenzen Dezimalstellen
  entsprechend Geld oder Gewicht.
- Offline sind gelesene Cache-Daten sichtbar; Schreibaktionen bleiben gesperrt.
- Lokale Entwürfe werden beim Öffnen zur Wiederherstellung angeboten.
- Kritische Aktionen benötigen eine verständliche Bestätigung und zeigen
  Datenbankfehler auf Deutsch.
- Gleichzeitige Änderungen führen zu einer Konfliktmeldung mit Neu-laden-Aktion.
- Leere, Lade-, Fehler- und Berechtigungszustände sind explizit darzustellen.

Routen und Detailverhalten: [`technical.md`](technical.md).
