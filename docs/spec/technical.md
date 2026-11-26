# Technische Festlegungen für die direkte Umsetzung

Ergänzt `docs/SPEC.md`. Bei Widerspruch gilt diese Datei (neuer). Backend: `docs/spec/backend.md`.

## 1. Projekt-Grunddaten
- App-Name: Warenbestand; Flutter-Projektname: `warenbestand`
- Bundle-ID / Package: `de.<firmenname>.warenbestand` (dev: `…warenbestand.dev`)
- Mindestversionen: iOS 15, Android 8 (API 26)
- Nur Hochformat, Smartphone; Tablet zeigt dieselbe Ansicht zentriert mit max. 600 px Breite
- Sprache de_DE; Zeitzone Europe/Berlin
- Konfiguration über `--dart-define-from-file=config/dev.json` bzw. `prod.json`:
  `{ "FLAVOR": "dev", "SUPABASE_URL": "...", "SUPABASE_ANON_KEY": "...", "PRIVACY_URL": "...", "IMPRINT_URL": "..." }`
- VS Code `launch.json` und `Makefile` mit: run-dev, run-prod, codegen, test, build-ios, build-android, db-reset, db-push

## 2. Kontext-Datei
- `CLAUDE.md` (bzw. AGENTS.md) im Root: Ziel der App, Architektur-Regeln, Ordnerstruktur, Design-Tokens, Begriffsliste, „so baut man ein neues Feature“, Befehle
- Spezifikation liegt in `docs/spec/` (features.md, backend.md, design.md, ux.md, pdf.md, structure.md, technical.md). Vor jedem Schritt lesen und exakt daran halten.

## 3. Screens & Routen (go_router)
```
/login                         Anmelden
/forgot-password               Passwort vergessen (Code per E-Mail)
/onboarding                    3 Einführungsseiten (nur beim ersten Start)
--- Shell mit Bottom-Navigation ---
/home                          Start
/tours                         Tourliste (Tabs: Unterwegs · Geplant · Abgeschlossen)
/tours/new                     Tour planen Schritt 1 (Fahrer, Datum)
/tours/:id/load                Tour planen Schritt 2 (Beladung)
/tours/:id                     Tourdetails
/tours/:id/close               Tour abschließen
/stock                         Bestand
/stock/intake                  Wareneingang
/products/new                  Produkt anlegen
/products/:id                  Produktdetail + Bewegungen
/products/:id/edit             Produkt bearbeiten
/products/:id/correct          Bestand korrigieren
/products/import               CSV-Import
/reports                       Auswertungen
/reports/drivers               Fahrerstatistik
/more                          Mehr-Menü
/expenses                      Ausgaben (Monat)
/expenses/new                  Ausgabe erfassen (optional ?tourId=)
/expenses/:id                  Ausgabe ansehen/bearbeiten
/delivery-notes                Lieferscheine
/delivery-notes/new            Lieferschein erstellen (optional ?tourId=)
/delivery-notes/:id            Lieferschein Vorschau
/delivery-notes/:id/sign       Unterschreiben
/invoices                      Rechnungen
/invoices/new                  Rechnung erstellen (optional ?deliveryNoteId= / ?tourId=)
/invoices/:id                  Rechnung Detail / Vorschau
/drivers                       Fahrerliste
/drivers/new · /drivers/:id    Fahrer anlegen/bearbeiten
/users                         Benutzer (nur Chef)
/company                       Firmendaten (nur Chef)
/account                       Konto (Name, Passwort ändern, Konto löschen)
/help                          Hilfe
/legal                         Impressum & Datenschutz
/pdf-preview                   gemeinsame PDF-Vorschau (Daten über extra)
```
- Nicht-Chef auf Chef-Route → Weiterleitung `/more` + Hinweis
- Nicht angemeldet → `/login`; nach Login zurück zur ursprünglichen Route

## 4. Auth ohne Deep Links
- Login mit E-Mail + Passwort
- Passwort vergessen: 6-stelliger Code per E-Mail (Supabase OTP), Code in der App eingeben, neues Passwort setzen. KEINE Deep Links.
- Neue Benutzer legt der Chef im Supabase-Dashboard an (Anleitung im README); Benutzer setzt beim ersten Login ein eigenes Passwort. (Daher keine Edge Function invite-user.)
- Sitzung bleibt gespeichert (supabase_flutter Standard); automatisch abmelden, wenn das Profil deaktiviert wird (bei jedem App-Start prüfen)

## 5. Datenzugriff – einheitliches Muster
- Jedes Repository gibt `Future<Result<T>>` zurück, Fehler über `guard()`:
  PostgrestException → Meldung aus der Datenbank (schon deutsch); AuthException → deutsche Standardtexte; SocketException/Timeout → „Keine Internetverbindung“
- Listen: Pagination 25 Einträge, neueste zuerst, Suche serverseitig mit `ilike`, Debounce 300 ms
- Detail-Provider: `family(id)`, autoDispose
- Nach jeder Änderung betroffene Provider invalidieren (Liste + Detail + Home)
- Kein Realtime; Pull-to-Refresh und Neuladen beim Zurückkehren auf einen Screen

## 6. Gleichzeitiges Bearbeiten (2 Personen)
- Beim Speichern `updated_at` mitschicken: `update … where id = :id and updated_at = :loadedUpdatedAt`
- 0 Zeilen geändert → „Wurde inzwischen von <Name> geändert. Bitte neu laden.“ + Button „Neu laden“
- RPC-Funktionen sperren selbst in der Datenbank

## 7. Entwürfe & Offline
- Formulare speichern ihren Zustand alle 2 Sekunden lokal (drift, Tabelle `drafts`: key z. B. `"tour_load:<id>"`, json, updated_at)
- Beim Öffnen: lokaler Entwurf vorhanden → „Ungespeicherte Eingaben wiederherstellen?“
- Nach erfolgreichem Speichern lokalen Entwurf löschen
- Offline: Lesen aus Cache, Schreiben gesperrt mit Hinweis (keine Hintergrund-Synchronisierung)

## 8. Mindestversion / Pflicht-Update
- Tabelle `app_config` (min_version_ios, min_version_android, message). Beim Start prüfen; zu alt → Vollbild „Bitte aktualisieren“ mit Store-Link.

## 9. Eingabe von Zahlen
- Geld: „12,50“ oder „12.50“ → 1250 Cent; max. 2 Nachkommastellen
- kg: „12,5“ → 12500 g; max. 3 Nachkommastellen
- Stück/Gläser/Kartons: nur ganze Zahlen
- Tastatur `TextInputType.numberWithOptions(decimal: true)` bzw. `number`
- Beim Fokus Inhalt markieren; +/− Buttons bei Mengen

## 10. Bilder & Dateien
- Storage-Pfade: `receipts/{yyyy}/{mm}/{expenseId}.jpg` (+ `_thumb.jpg`), `signatures/{deliveryNoteId}.png`, `documents/{yyyy}/{typ}/{nummer}.pdf`, `logos/company.png`, `products/{productId}.jpg`
- Vor Upload: JPG, max. 1600 px, Qualität 75, Ziel ≤ 200 KB; Thumbnail 300 px
- Anzeige über Signed URLs (1 Stunde, im Speicher gecacht)
- Beim Löschen eines Datensatzes auch die Datei löschen

## 11. Berechtigungen (Texte Deutsch)
- iOS: `NSCameraUsageDescription` „Zum Fotografieren von Belegen und Produkten.“, `NSPhotoLibraryUsageDescription` „Zum Auswählen von Belegfotos.“
- Android: CAMERA; Fotoauswahl über Photo Picker (keine Speicherberechtigung)
- Berechtigung erst anfragen, wenn die Funktion benutzt wird; bei Ablehnung Hinweis + Button „Einstellungen öffnen“

## 12. CSV-Import Produkte
- Vorlage zum Teilen: `name;kategorie;einheit;stueck_pro_karton;ek;vk;ust;mindestbestand;bestand`
- Trennzeichen `;` oder `,` automatisch, Dezimalkomma erlaubt, UTF-8 mit/ohne BOM
- Vorschau mit Fehlern pro Zeile, Import erst nach Bestätigung, in einer Transaktion (RPC `import_products(json)`)

## 13. Umsatzsteuer-Sonderfälle
- Firmendaten: Schalter „Kleinunternehmer (§ 19 UStG)“ → Rechnungen ohne USt, Hinweistext automatisch auf der Rechnung
- Rechnungen bis 250 € brutto als Kleinbetragsrechnung kennzeichnen (weniger Pflichtangaben, keine E-Rechnungspflicht)

## 14. E-Rechnung (ZUGFeRD / XRechnung)
- Jede festgeschriebene B2B-Rechnung (über 250 €, nicht Kleinunternehmer) wird als ZUGFeRD-PDF erzeugt (Profil EN 16931): sichtbares PDF/A-3 + eingebettete XML (`factur-x.xml`)
- Zusätzlich Export als reine XRechnung-XML (UBL) zum Teilen
- XML aus den Rechnungsdaten in Dart erzeugen (`einvoice/zugferd_builder.dart`), gegen die offiziellen Beispiele testen
- Empfänger: optionale Felder USt-IdNr. und Leitweg-ID / Käuferreferenz (frei eintippen)
- Validierung vor dem Festschreiben: alle Pflichtfelder vorhanden, sonst verständliche Fehlermeldung

## 15. Store-Vorbereitung
- Demo-Konto für Apple/Google-Prüfung (demo@…, Daten im Seed für Demo-Projekt)
- App-Icon aus 1024×1024 PNG (flutter_launcher_icons), Splash weiß mit Logo
- Store-Texte, Datenschutz-Angaben (Data Safety / App Privacy) als `docs/store/*.md`

## 16. Arbeitsweise & „Fertig“-Definition
- Vor jedem Schritt kurzer Plan (Dateien, die angelegt/geändert werden)
- Ein Schritt ist FERTIG, wenn:
  - [ ] `flutter analyze` ohne Fehler/Warnungen
  - [ ] `flutter test` grün
  - [ ] Migration lokal mit `supabase db reset` getestet
  - [ ] Screen auf iOS-Simulator UND Android-Emulator geprüft
  - [ ] keine festen Strings/Farben/Abstände im Code
  - [ ] CLAUDE.md und docs aktualisiert, falls sich etwas geändert hat
- Erst ein Feature komplett als REFERENZ bauen (Fahrer: Liste, Anlegen, Bearbeiten, Deaktivieren – alle Schichten), danach alle anderen exakt nach diesem Muster
- Keine Pakete hinzufügen, die nicht in der Spezifikation stehen, ohne vorher zu fragen
- Keine Platzhalter/TODOs im fertigen Schritt
