# PDF-Erstellung

Alle PDFs werden direkt in der App erzeugt (kein Server, 0 € Kosten) mit den Flutter-Paketen `pdf` + `printing`. Einmal sauber bauen: ein gemeinsames Baukasten-System, alle Dokumente nutzen dieselben Bausteine. Kein Dokument hat eigenen Layout-Code für Kopf, Fuß, Tabelle oder Summen.

## Technik
- Erzeugung in einem Isolate (`compute` / `Isolate.run`), damit die App nicht hängt
- Eingabe: fertige, unveränderliche Daten-Objekte (z. B. `InvoicePdfData`), KEINE Datenbank-Aufrufe im PDF-Code
- Ausgabe: `Uint8List`
- Bilder (Logo, Unterschrift, Belegfotos) vorher laden und als Bytes übergeben
- Schriften als Assets einbetten: IBM Plex Sans Regular, Medium, SemiBold (für Arabisch später IBM Plex Sans Arabic, RTL-fähig vorbereiten: `textDirection` aus den Daten, nie fest links/rechts)
- Alle Texte aus einer `PdfStrings`-Klasse (Deutsch), keine festen Strings im Layout
- Geld, Datum und Mengen mit denselben Formatierern wie in der App (1.234,56 € · 16.11.2026 · „55 Gläser“ · „12,5 kg“)

## Ordner
```
lib/core/pdf/
  pdf_service.dart          generate<T>(builder, data) → Uint8List (im Isolate)
  pdf_theme.dart            A4, Ränder, Schriften, Farben, Größen
  pdf_strings.dart          alle Texte
  widgets/
    pdf_company_header.dart   Logo links, Firmenname + Adresse rechts
    pdf_address_window.dart   Empfänger im Fensterbereich nach DIN 5008
    pdf_doc_meta.dart         Titel + Nummer + Datum + weitere Felder als Tabelle
    pdf_items_table.dart      generische Tabelle, Spalten konfigurierbar, Kopfzeile wiederholt sich auf jeder Seite
    pdf_totals_block.dart     Netto, USt 7 %, USt 19 %, Brutto (rechtsbündig)
    pdf_signature_block.dart  Unterschriftsbild + Name + Datum/Uhrzeit
    pdf_note_block.dart       Hinweistext
    pdf_footer.dart           Firma · Bank · Steuernr. · USt-IdNr. · Geschäftsführer · „Seite X von Y“
    pdf_key_value_list.dart   „Wareneinsatz ........ 517,60 €“
    pdf_image_page.dart       ein Belegfoto pro Seite, eingepasst, mit Bildunterschrift
features/<feature>/pdf/
  delivery_note_pdf.dart, invoice_pdf.dart, tour_summary_pdf.dart, expenses_month_pdf.dart, report_pdf.dart
```

## Layout (für alle Dokumente gleich)
- A4 hochkant; Ränder: links 25 mm, rechts 20 mm, oben 15 mm, unten 25 mm
- Schrift: Text 10 pt, Tabellen 9 pt, Fußzeile 7,5 pt, Titel 16 pt fett
- Farben: Überschriften und Tabellenkopf Dunkelgrün #0B4A2E, Text fast schwarz, Linien hellgrau; druckt auch schwarz-weiß gut lesbar
- Empfängeradresse im Fensterbereich DIN 5008 Form B (passt in Fensterumschlag), kleine Absenderzeile darüber
- Mehrseitig: MultiPage; Tabellen brechen sauber um, Tabellenkopf wiederholt sich, Summenblock nie allein auf einer neuen Seite
- Fußzeile auf jeder Seite mit Seitenzahl; Zahlen in Tabellen rechtsbündig; lange Produktnamen umbrechen, nie abschneiden

## Dokumente

### 1. Lieferschein
- Kopf, Empfänger, Titel „Lieferschein“, Nummer LS-2026-001, Lieferdatum, Tour-Nummer (falls vorhanden)
- Tabelle: Pos. · Artikel · Menge · Einheit (bei Karton-Produkten zusätzlich „= 13 Kartons + 3 Gläser“)
- KEINE Preise
- Text: „Ware vollständig und unbeschädigt erhalten.“
- Unterschriftsblock mit Bild, Name, Datum und Uhrzeit; ohne Unterschrift: leere Linie „Unterschrift Empfänger“
- Wasserzeichen „ENTWURF“, solange nicht unterschrieben

### 2. Rechnung (Pflichtangaben § 14 UStG)
- Kopf mit vollständigem Namen und Anschrift der Firma, Empfänger
- Titel „Rechnung“, Rechnungsnummer, Rechnungsdatum, Leistungsdatum, Fälligkeitsdatum, ggf. Bezug Lieferschein-Nr.
- Tabelle: Pos. · Artikel · Menge · Einheit · Einzelpreis netto · USt % · Gesamt netto
- Summen: Netto, USt 7 % (Betrag), USt 19 % (Betrag), Gesamtbetrag brutto (nur vorkommende Steuersätze)
- Zahlungshinweis: „Bitte überweisen Sie X € bis zum TT.MM.JJJJ auf …“ + IBAN/BIC
- Fußtext aus Firmendaten; Fußzeile mit Steuernummer und/oder USt-IdNr.
- Entwurf: großes Wasserzeichen „ENTWURF – keine gültige Rechnung“, keine Nummer
- Storno: Titel „Stornorechnung“, Hinweis „Storno zu Rechnung RE-…“, negative Beträge
- Werte (Summen) kommen fertig aus der Datenbank, das PDF rechnet NICHT selbst
- (aus `docs/spec/technical.md`) Kleinunternehmer: Hinweistext `small_business_note`, keine USt. Kleinbetragsrechnung (≤ 250 €) kennzeichnen.

### 3. Tourabrechnung
- Titel „Tourabrechnung“, Tour-Nr., Fahrer, Datum, Start/Ende
- Tabelle: Artikel · Geladen · Zurück · Verkauft · Preis · Umsatz
- Ausgaben-Liste (Art, Betrag)
- Zusammenfassung: Umsatz, Ausgaben, Soll-Bargeld, Übergebenes Bargeld, Differenz (Fehlbetrag rot / Überschuss grün), Begründung, Wareneinsatz, Tourgewinn
- Unterschriftsfelder (leer): „Fahrer“ und „Geprüft“

### 4. Monatsbelege für den Steuerberater
- Deckblatt: Firma, „Ausgabenbelege November 2026“, Anzahl Belege, Summen netto / USt / brutto, Aufteilung nach Kategorie
- Übersichtstabelle: Nr. · Datum · Bezeichnung · Kategorie · USt % · Netto · Brutto
- Danach jeder Beleg auf eigener Seite: Foto eingepasst (Seitenverhältnis bleibt), darüber Nr., Datum, Bezeichnung, Betrag; Beleg ohne Foto: nur Datenzeile
- Fotos vorher auf max. 1600 px verkleinern (Ziel: unter 10 MB pro Monat)
- Auch einzelner Beleg als PDF möglich (gleicher Baustein)

### 5. Auswertungsbericht
- Titel „Auswertung“ + Zeitraum
- Kennzahlen: Umsatz, Wareneinsatz, Ausgaben, Gewinn, Veränderung zum Vorzeitraum
- Tabellen: Top-Produkte, Ausgaben nach Kategorie, Fahrerstatistik
- Einfache Balkendiagramme direkt mit pdf-Widgets gezeichnet (kein Screenshot)

## Dateinamen
- `Lieferschein_LS-2026-001_Feinkost-Kaya.pdf`
- `Rechnung_RE-2026-001_Feinkost-Kaya.pdf`
- `Stornorechnung_RE-2026-005.pdf`
- `Tourabrechnung_T-2026-012_Mehmet-Yilmaz_2026-11-16.pdf`
- `Belege_2026-11.pdf`
- `Auswertung_2026-11-01_bis_2026-11-30.pdf`

Umlaute und Sonderzeichen ersetzen, Leerzeichen → Bindestrich.

## Speichern & Teilen
- Vorschau-Screen (für alle PDFs gleich): `PdfPreview` mit Buttons „Teilen“, „Drucken“, „Speichern“
- Teilen über `share_plus` (WhatsApp, E-Mail, Dateien)
- In Supabase Storage (Bucket `documents`) speichern NUR bei unterschriebenem Lieferschein und festgeschriebener Rechnung/Storno (rechtssicher, unveränderbar, Pfad in `pdf_path`). Später immer dieses gespeicherte PDF öffnen, nicht neu erzeugen.
- Alle anderen PDFs (Tour, Belege, Auswertung) bei Bedarf neu erzeugen, nicht speichern
- Pfade: `documents/{jahr}/{typ}/{nummer}.pdf`

## Vorbereitung für später
- Rechnungs-Daten so aufbauen, dass später ZUGFeRD (PDF mit eingebetteter XML) ergänzt werden kann, ohne das Layout zu ändern
- Arabisch: Schrift und Textrichtung über Parameter umschaltbar

## Tests
- Golden-Test pro Dokument nicht nötig
- Ein Unit-Test pro Dokument: PDF wird ohne Fehler erzeugt, mit 1 Position und mit 60 Positionen
- Dateinamen-Funktion testen (Umlaute, Sonderzeichen)
