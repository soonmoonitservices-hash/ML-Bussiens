# UX-Checkliste (Nielsen, ISO 9241-110, WCAG 2.2 AA)

Vor jedem Release alle Screens prüfen. Stand 2026-11-22. ✔ umgesetzt · ◐ teilweise · ✘ offen (Grund).

## Nielsen
1. Systemstatus: ✔ Skeleton in Listen, Spinner im Button, Erfolgsmeldungen, Status oben, Schritt „x von y“, Live-Berechnung · ✔ Offline-Leiste · ◐ „Nicht gespeichert“-Anzeige (nur Rückfrage beim Verlassen)
2. Reale Welt: ✔ Kartons + Gläser, kg, deutsche Formate, Reihenfolge der Tour
3. Kontrolle: ✔ Zurück überall, „Änderungen verwerfen?“ in allen Formularen (Textfelder), Bestätigung bei Festschreiben/Storno/Unterschrift, „Start rückgängig“ · ✘ „Gelöscht · Rückgängig“ (braucht Soft-Delete in der Datenbank), Entwurf automatisch zwischenspeichern (Schritt 10, Drift) · ✘ Tour wieder öffnen (Backend-Funktion fehlt)
4. Konsistenz: ✔ gleiche Widgets, Suche und Filterleiste oben, gleiche Listenzeilen
5. Fehlervermeidung: ✔ Zahlentastatur, Begrenzungen, Produkt nicht doppelt, deaktivierte Buttons, Warnung bei Differenz über 50 € · ◐ Hinweis „max. 55“ nur bei Rückgabe prüfen
6. Wiedererkennen: ✔ Auswahl aus Listen, Platzhalter in Suchfeldern · ✔ Relative Daten und Fälligkeit in Listen · ✘ „Zuletzt benutzt“, Adressvorschläge
7. Effizienz: ✔ Pull-to-refresh, +/−-Tasten · ✘ „Tour kopieren“, Wischen auf Listeneinträgen
8. Minimalismus: ✔ eine Hauptaktion pro Screen
9. Fehlermeldungen: ✔ Meldungen der Datenbank 1:1 auf Deutsch, am Feld · ✘ Aktionsknopf in der Meldung („Wareneingang buchen“)
10. Hilfe: ✔ Leerzustände · ✘ ⓘ-Hinweise, Einführung beim ersten Start, Hilfe-Screen

## WCAG
- Kontrast: Warn-Orange `#D97706` und Hellgrau `#A3A3A3` liegen unter 4,5 : 1 (Vorgabe des Kunden); Warnung steht immer mit Text und Icon.
- Touch-Ziele 48 × 48 ✔, Schrift 200 % (manuell prüfen), Semantics-Labels über Tooltips ◐.

## Messziele (ISO 9241-11)
Tour planen unter 1 min, abschließen unter 2 min, Beleg unter 20 s, Lieferschein unter 1 min, SUS ≥ 80. Nur mit echten Nutzern messbar (Testaufgaben 1–5 aus dem Pflichtenheft).
