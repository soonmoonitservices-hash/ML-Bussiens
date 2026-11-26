# Umsetzungsstand der technischen Festlegungen

Stand: 22. November 2026. Diese Datei trennt vorhandene Implementierung von
reiner Spezifikation. Ein vorhandener Route-Eintrag gilt nicht als umgesetztes
Feature.

## Fertig

- Supabase-Backend: Migrationen 01–15, RLS, Storage-Buckets, Kern-RPCs,
  Berichts-Views, CSV-Import-RPC und Konto-Löschfunktion.
- Reine Dart-Logik für Geld, Mengen, USt, Tourbeladung, Tourabrechnung und
  Rechnungssummen.
- Gemeinsamer PDF-Baukasten und PDFs für Lieferschein, Rechnung,
  Tourabrechnung, Monatsbelege und Auswertungen einschließlich Tests.
- Flutter-Grundgerüst: Konfiguration per `--dart-define-from-file`, deutsches
  Theme/Locale, Portrait-Modus, maximal 600 px Inhaltsbreite, `go_router`,
  Bottom-Navigation und Auth-Weiterleitung mit Rücksprung zur Zielroute.
- Login und Passwort-Wiederherstellung über E-Mail-Code, gespeicherte
  Supabase-Sitzung und Profil-/Aktivprüfung beim App-Start.
- Chef-Routenschutz für `/users` und `/company`.
- Referenz-Feature Fahrer: serverseitige Suche mit 300-ms-Debounce,
  25er-Pagination, Pull-to-Refresh, Anlegen, Bearbeiten, De-/Reaktivieren und
  optimistische Sperre über `updated_at` mit Name des letzten Bearbeiters.
- Zentrale `Result<T>`-/`guard()`-Fehlerbehandlung.
- Android API 26, iOS 15, deutsche Kamera-/Fotoberechtigungstexte.
- VS-Code-Starts und Make-Ziele für Run, Codegen, Tests und Builds.
- Mengen-Eingabe mit Dezimalbegrenzung, Fokusauswahl und Plus/Minus sowie
  Differenz-Banner für Tourabrechnungen.
- Design nach `docs/spec/design.md` (Plex, Schwarz-Weiß, Phosphor, scrollende
  Köpfe) und Deutsch/Arabisch (RTL) über ARB.
- Produkte und Lager: Bestandsliste mit Lagerwert, Suche, Filter und
  Nachladen, Produktdetail mit Bewegungen, Produkt anlegen/bearbeiten,
  Wareneingang, Bestandskorrektur, Auswahl-Sheet. Noch nicht auf einem Gerät
  geprüft.
- Touren: Liste mit Filter und Suche, Planen in zwei Schritten mit Live-Wert der
  Ladung und Bestandswarnung, Entwurf speichern, Starten, Start rückgängig,
  Entwurf löschen, Tourdetail inkl. Ansicht der Abrechnung, Wieder öffnen (Chef).
  Noch nicht auf einem Gerät geprüft.
- Tour abschließen: Rückgabe je Produkt, Ausgaben hinzufügen/entfernen, Bargeld,
  Live-Abrechnung (Soll, Differenz, Wareneinsatz, Gewinn) mit Pflicht-Begründung
  bei Differenz und Bestätigung. Ausgaben ohne Belegfoto.
- Lieferscheine: Liste mit Suche und Filter, Erstellen/Bearbeiten mit freiem
  Empfänger und Übernahme aus einer Tour, Unterschreiben mit dem Finger, PDF
  (Entwurf mit Wasserzeichen, nach der Unterschrift abgelegt in `documents`),
  gemeinsame PDF-Vorschau mit Teilen und Drucken, Rechnung aus Lieferschein.
  Ablauf Anlegen, Unterschreiben, Ablegen gegen die lokale Supabase geprüft.
- Ausgabenbelege: Monatsordner mit Summe (aus der Datenbank), Filter Alle/Tourkosten/
  Sonstige, Erfassen/Bearbeiten/Löschen, Beleg per Scan, Kamera oder Galerie
  (auf 1600 px verkleinert, Bucket `receipts`), Detail mit Vollbild-Betrachter,
  Sammel-PDF je Monat und Einzel-PDF. Abfragen und Upload gegen die lokale
  Supabase geprüft. Produktfoto beim Anlegen/Bearbeiten und im Detail.
- Rechnungen: Liste mit Offen-Summe, Filter und Suche; Formular mit freiem
  Empfänger, Produkt- und freien Positionen, Rabattpreis, Live-Summen; Entwurf
  speichern, Vorschau, Festschreiben mit Bestätigung (PDF wird abgelegt);
  Detail mit Bezahlt/Wieder offen und Storno (Chef) samt Storno-PDF; Kleinunternehmer-
  Darstellung. Ablauf gegen die lokale Supabase geprüft. E-Rechnung (XML) fehlt.
- Firmendaten (alle Felder, Kleinunternehmer, Zahlungsziel; nur Chef speichert), Konto (Name, Passwort, Abmelden, Konto löschen über Edge Function), Benutzerliste (Rolle, sperren), Hilfe. Kein Impressum/Datenschutz in der App (private App; nur falls ein Store eine Datenschutz-URL verlangt, dann als Webseite). Logo-Upload und Speicheranzeige fehlen.
- Mischkartons (Migration 22, lokal getestet, noch nicht in der Cloud): Vorlage aus mehreren Produkten, wird beim Beladen einer Tour in die Einzelprodukte aufgelöst; Verwaltung unter Mehr. Noch nicht in Lieferschein und Rechnung. Sprachschalter im Konto und im Login.
- Geschenkte Produkte beim Tour-Abschluss (Migration 23, lokal getestet, noch nicht in der Cloud): `close_tour` nimmt je Produkt `gift_qty`; Geschenke gehen nicht zurück ins Lager, bringen keinen Umsatz, zählen als Wareneinsatz. Neue Spalten `tour_items.gift_qty` und `billed_qty`.
- Benutzer anlegen in der App (Edge Function `create-user`, in der Cloud) und gleiche Rechte für Chef und Verwaltung (Migration 28).
- Mehrere Firmen in einer Datenbank (Migrationen 24-27, in der Cloud eingespielt am 2026-11-23): jede Firma sieht nur ihre eigenen Daten und Dateien; siehe docs/tenants.md. Dateipfade im Speicher beginnen mit der Firmen-Kennung (`tenantPath`).
- Bestand entfernt (Migration 29) und alles löschbar (Migration 30), beides lokal getestet, noch nicht in der Cloud. Reiter „Bestand“ heißt jetzt „Produkte“. Mehrwertsteuer nur noch bei Rechnungen.
- Begründung bei Kassendifferenz ist freiwillig (Migration 31) und das übergebene Bargeld geht in den Gewinn ein (Migration 32): Gewinn = Umsatz − Wareneinsatz − Ausgaben + Differenz. Beides nur lokal.
- Kleinunternehmer-Regelung entfernt (Migration 33, lokal): Rechnungen weisen immer Mehrwertsteuer aus; die Einstellung ist aus der App verschwunden und in der Datenbank gesperrt.
- Superadmin (Migrationen 34-35, Edge Function `superadmin-delete-firm`): Firmen sperren oder endgültig löschen. Nur DEINE-SUPERADMIN-EMAIL.
- Neue Firma anlegen (2026-11-24): im Bildschirm „Neuer Benutzer“ wählt nur der Superadmin zwischen „Zu meiner Firma“ und „Neue Firma“ (Edge Function `create-user` mit `mode`, lokal getestet). Der frühere Bildschirm „Neuer Chef“ und die Funktion `superadmin-create-chef` entfallen. **Reihenfolge beim Ausrollen:** zuerst `create-user` in der Cloud neu einspielen (rückwärtskompatibel), dann die neue App verteilen, danach `superadmin-create-chef` in der Cloud löschen.
- Produkte mit zwei Namen (Deutsch, Arabisch; mindestens einer) und Karton-Inhalt direkt im Produkt (Migration 36, lokal getestet): ersetzt die getrennten Mischkartons.
- Beim Tour-Abschluss lassen sich aus einem Karton einzelne Produkte abziehen: zurück oder geschenkt, der Umsatz sinkt um ihren Verkaufspreis (Migration 37, lokal getestet).
- Beim Tour-Abschluss zwei Knöpfe nach dem Gewinn: „Verkaufte Ware“ und „Zurückgeholte Ware“ (Liste mit Menge, Einzelpreis, Gesamtpreis, als PDF teilbar). Nur im Abschluss-Screen, nicht in der Tour-Detailseite.
- Einführung beim ersten Start (einmalig, gemerkt mit shared_preferences) und Offline-Leiste „Keine Internetverbindung“ (connectivity_plus). Noch offen: Sperre beim Speichern ohne Netz, Entwürfe und Offline-Cache (Drift).
- Auswertungen: Zeitraum Tag/Woche/Monat/Jahr/Eigener mit Vor-/Zurück, Kennzahlen
  mit Veränderung zum Vorzeitraum, Balkendiagramm Umsatz gegen Ausgaben, Top-Produkte,
  Ausgaben nach Kategorie, Fahrerstatistik, Bericht als PDF. Zeitraumlogik mit Tests;
  Antworten der `report_*`-Funktionen gegen die lokale Supabase geprüft.

## Teilweise

- Alle geforderten Routen sind registriert. Noch nicht umgesetzte Bereiche
  zeigen bewusst eine eindeutige Hinweisseite und keine vorgetäuschten Daten.
- Startseite und Mehr-Menü sind vorhanden; Kennzahlen und letzte Touren fehlen.
- Mindestversionsdaten und Store-URLs existieren im Backend; die clientseitige
  Vollbild-Pflichtupdateprüfung fehlt.
- ZUGFeRD-/XRechnungsfelder sind im Backend vorbereitet; Builder, XML-Export
  und PDF/A-3-Einbettung fehlen.

## Offen

- Benutzer- und Firmendatenverwaltung in Flutter.
- CSV-Import-Oberfläche (braucht noch eine Dateiauswahl).

- Ausgaben, Fotoverarbeitung/Uploads, Signed-URL-Cache und Dateilöschung.
- Rechnungsformular und PDF-Vorschau der übrigen Dokumente.
- Drift-Cache und automatisch alle zwei Sekunden gespeicherte Entwürfe;
  Offline-Schreibsperre und Offline-Banner.
- Einmalige Onboarding-Persistenz.
- App-Icon/Splash aus finalem Kundenlogo, Store-Texte, Demo-Konto und
  Store-Datenschutzangaben.
- iOS-/Android-Gerätetest sowie lokaler `supabase db reset` in der aktuellen
  Arbeitsumgebung.

## Verifikation

- `flutter analyze`: ohne Hinweise.
- `flutter test`: 72 Tests erfolgreich.
- Android-Debug-Build wurde gestartet, blieb in dieser Windows-Umgebung im
  Gradle-Schritt ohne Ausgabe hängen und wurde kontrolliert beendet. Er ist
  daher nicht als erfolgreich vermerkt.
