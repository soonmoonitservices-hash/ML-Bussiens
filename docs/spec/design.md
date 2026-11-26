# Design

Gilt seit 2026-11-22 und ersetzt die frühere Plex-Fassung. Sauber, Schwarz-Weiß, Farbe nur mit Bedeutung. Umgesetzt in `lib/core/theme/` und `lib/shared/widgets/`; alle Werte nur dort, nirgends direkt im Code.

## Farben (`AppColors`)
ink `#0A0A0A` (Text, Buttons, Auswahl) · paper `#FFFFFF` · paperMuted `#F5F5F5` (Felder, Filterleiste) · line `#E5E5E5` · inkMuted `#6B6B6B` · inkFaint `#A3A3A3`.
Bedeutung: success `#16A34A` / `#F0FDF4` (stimmt, Überschuss, bezahlt, unterschrieben) · error `#DC2626` / `#FEF2F2` (Fehlbetrag, Fehler, überfällig, löschen) · warning `#D97706` / `#FFFBEB` (unter Mindestbestand, Entwurf, offline). Ohne diese Bedeutung: schwarz oder grau. Beträge schwarz, nur Verluste und Fehlbeträge rot. Keine Verläufe, keine Schatten.

## Schrift (`AppText`)
Inter (400/500/600/700), Arabisch über IBM Plex Sans Arabic als Ersatzschrift (Inter hat keine arabischen Zeichen). Nummern in IBM Plex Mono. Alle Zahlen tabellarisch.
Seitentitel 28 Bold · Abschnitt 17 SemiBold · große Beträge 32 Bold · Text 15 · Beschriftung 13 grau · Chips/Tabs 12 Medium.

## Abstände und Formen
Abstände 4 · 8 · 12 · 16 · 24 · 32 · 48, Seitenrand 20. Radius: Buttons und Felder 12, Karten 14, Chips Pille. Karten weiß mit 1 px Rahmen (`AppCard`), nur der Blickfang „Heute unterwegs“ ist schwarz.

## Bedienelemente
- Primärbutton: schwarz, weiße Schrift, 52 hoch, gedrückt `#262626`-Ton, deaktiviert `#D4D4D4`, Ladezustand weißer Spinner.
- Sekundär: weiß mit schwarzem Rahmen. Löschen: roter Rahmen, Bestätigung im Dialog rot gefüllt.
- Felder: `#F5F5F5` ohne Rahmen, Fokus 1,5 px schwarz, Fehler rot. Zahlen rechtsbündig.
- Chips und Status als Pillen; Status immer mit Text, nie nur Farbe.
- Kassen-Differenz: grüne oder rote Box mit Text, Fehlbetrag groß und fett.
- Untere Navigation weiß mit Linie oben, aktiv schwarz, inaktiv grau.
- Start: Begrüßung, schwarze Karte „Heute unterwegs“, vier Bereichskarten, Monatsübersicht.

## Icons (`AppIcons`)
Phosphor Regular, ein Set, immer schwarz oder grau. Codepunkte stehen in `AppIcons`; nie `package:phosphor_flutter` importieren (Dart-Klassen lassen sich mit Flutter 3.50 nicht übersetzen).

## Texte
Kurz, sachlich, keine Ausrufezeichen, Emojis oder Floskeln. Deutsch und Arabisch immer beide vollständig (`app_de.arb`, `app_ar.arb`); Sprache folgt dem Gerät; Arabisch läuft rechts nach links (start/end, `AppIcons.back/forward`); Beträge, Mengen und Nummern bleiben links nach rechts. Delegates über `appLocalizationsDelegates`.

## Jeder Screen scrollt, der Hauptbutton klebt
Jeder Screen ist ein `AppScreen`. Kopf und Inhalt scrollen. Der Hauptbutton (`StickyAction`) steht fest unten über Tastatur und Safe Area, mit weißem Auslauf darüber; ein Screen hat höchstens einen. Die untere Navigation und die Offline-Leiste bleiben ebenfalls stehen. Kein Overflow bei 320 px, Systemschrift 200 %, offener Tastatur.

## Barrierefreiheit
Kontrast mindestens AA, Touch-Ziele mindestens 48 × 48, Status nie nur über Farbe. Dunkelmodus später; Farben deshalb nur über das Theme.

## PDF
Schwarz-Weiß, Tabellenkopf `#F5F5F5`, Linien hellgrau; Farbe nur bei Fehlbetrag und Wasserzeichen „ENTWURF“. Schrift im PDF bleibt IBM Plex (deckt Arabisch ab).
