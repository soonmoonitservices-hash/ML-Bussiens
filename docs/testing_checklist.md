# Manuelle Test-Checkliste

Vor jeder Auslieferung auf 1 iPhone und 1 Android-Handy durchklicken. Automatisch getestet werden nur die Geld- und Mengenberechnungen (siehe `docs/spec/tests.md`).

Gerät: ______________  Version: ______  Datum: ______________  Getestet von: ______________

- [ ] Anmelden / Abmelden
- [ ] Produkt anlegen (Karton-Produkt + kg-Produkt)
- [ ] Wareneingang buchen → Bestand stimmt
- [ ] Tour planen: 13 Kartons + 3 Gläser → zeigt 55 Gläser
- [ ] Tour starten → Bestand wird weniger
- [ ] Tour abschließen: 7 zurück → 48 verkauft, Differenz richtig
- [ ] Ausgaben zur Tour hinzufügen (Diesel, Essen)
- [ ] Lieferschein erstellen, unterschreiben, PDF teilen per WhatsApp
- [ ] Rechnung erstellen, festschreiben, PDF prüfen (Pflichtangaben)
- [ ] Beleg fotografieren → landet im richtigen Monatsordner
- [ ] Monats-PDF exportieren
- [ ] Auswertungen zeigen richtige Zahlen
- [ ] Ohne Internet: Hinweis erscheint, nichts geht kaputt
- [ ] Angefangenes Formular bleibt: Tour planen, Lieferschein und Rechnung (neu) halb ausfüllen, Seite verlassen bzw. App ganz schließen, wieder öffnen → Stand ist da, Hinweis „Entwurf ist wieder da“; „Verwerfen“ leert das Formular; nach dem Speichern kommt der Stand nicht zurück
- [ ] Produktliste: Reihenfolge ziehen, Seite verlassen, zurückkommen → bleibt; Tour, Lieferschein und Rechnung zeigen dieselbe Reihenfolge
- [ ] Neuer Benutzer: als Superadmin erscheint oben „Zu meiner Firma / Neue Firma“; „Neue Firma“ mit Firmenname legt eine eigene Firma an (der neue Chef sieht keine Daten der anderen Firma, der Superadmin nichts von seiner). Als normaler Benutzer oder Chef erscheint die Wahl nicht
- [ ] Produkt hinzufügen: in der Liste bei mehreren Produkten gleich die Menge eintippen („Karton“, „Einzeln“; kg: „Pro Kilogramm“), „Speichern“ → alle Produkte mit Menge stehen mit ihren Mengen in der Ladung

Zahlen zum Prüfen (Beispiel): 903,00 € Umsatz − 35,00 € Ausgaben = 868,00 € Soll; 860,00 € übergeben → Fehlbetrag −8,00 €.
- [ ] Arabisch: Gerätesprache umstellen, Richtung, Pfeile, Beträge und Nummern prüfen
- [ ] Systemschrift 200 %, iPhone SE, Querformat: nichts abgeschnitten, kein Overflow
- [ ] Kopf und Buttons scrollen mit, nur die untere Navigation bleibt stehen
