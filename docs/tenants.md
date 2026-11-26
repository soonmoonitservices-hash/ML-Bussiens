# Mehrere Firmen (Mandanten)

Eine Datenbank, mehrere Firmen. Nach der Anmeldung sieht jeder Benutzer nur die Daten seiner Firma: Produkte, Fahrer, Touren, Lieferscheine, Rechnungen, Ausgaben, Lagerbewegungen, Firmendaten, Benutzer und Dateien (Fotos, Unterschriften, PDFs). Nummern (Tour, Lieferschein, Rechnung) und Artikelnummern zählen je Firma.

## Wie die Trennung funktioniert
- Tabelle `tenants` (Firmen). Jeder Benutzer (`profiles.tenant_id`) gehört zu genau einer Firma.
- Jede Geschäftstabelle hat `tenant_id`. Neue Zeilen erhalten die Firma des Benutzers (`current_tenant()`); Positionen und Bewegungen übernehmen sie vom Elternteil.
- Zugriffsregeln (RLS) lassen nur Zeilen der eigenen Firma zu. Funktionen mit erhöhten Rechten prüfen selbst, dass der übergebene Datensatz zur Firma gehört (`_require_row_in_tenant`). Verknüpfungen über Firmen hinweg lehnt `_tenant_guard` ab.
- Dateien liegen unter `<firma>/…`; die Speicher-Regel erlaubt nur den eigenen Ordner.
- Getestet in `supabase/tests/tenants.test.sql`.

## Neue Firma (neuer Kunde) anlegen
1. Im Supabase-Dashboard: Authentication, Users, Add user, E-Mail und Passwort des Chefs, „Auto Confirm User“ anhaken.
2. Der Benutzer bekommt automatisch eine **neue Firma** (Name aus der E-Mail) und ist deren **Chef**. Die allererste Anmeldung der Datenbank landet in der Firma „Standard“.
3. Der Chef trägt unter Mehr, Firmendaten seine Angaben ein (Briefkopf, Steuernummer, IBAN).
4. Firmennamen umbenennen (optional), im SQL Editor:
   ```sql
   update tenants set name = 'Feinkost Beispiel GmbH'
   where id = (select tenant_id from profiles where email = 'chef@beispiel.de');
   ```

## Weitere Benutzer (Verwaltung)
Jeder Benutzer einer Firma kann in der App unter **Mehr, Benutzer, „+“** weitere Benutzer anlegen: Name, E-Mail, Passwort. Sie landen automatisch in derselben Firma und sehen dieselben Daten. Nur der Superadmin sieht oben die Wahl **Zu meiner Firma / Neue Firma** (siehe unten). **Chef und Verwaltung haben gleiche Rechte** (Firmendaten, Benutzer, Touren wieder öffnen, Rechnungen stornieren). Die Rolle bleibt eine Bezeichnung; in jeder Firma bleibt mindestens ein aktiver Chef. Dahinter steckt die Edge Function `create-user` (Service-Role-Key nur dort); die Firma kommt immer aus dem Konto des Aufrufers.

Benutzer sperren oder die Rolle ändern: Mehr, Benutzer, Eintrag antippen.

## Startprodukte für eine Firma
`supabase/seed_produkte.sql`: oben `DEINE-EMAIL` durch die E-Mail des Chefs ersetzen, im SQL Editor ausführen.

## Grenzen
- Eine Firma pro Benutzer. Die App-Konfiguration (Pflicht-Update) und die Datenbank-Einstellungen gelten für alle Firmen gemeinsam.
- Free-Plan: Datenbank (500 MB), Speicher (1 GB) und Bandbreite teilen sich alle Firmen. Ab etwa 3 bis 4 kleinen Firmen im Blick behalten (Dashboard, Usage).
- Das Backup sichert die ganze Datenbank, nicht je Firma.

## Superadmin
Genau ein Konto ist Superadmin: `rasho.juan95@gmail.com` (Tabelle `platform_admins`, geprüft über `is_superadmin()`). Kein anderes Konto kann das, auch kein Chef. In der App erscheint für ihn unter **Mehr** der Eintrag **Firmen verwalten**:
- **Neue Firma** („+“, öffnet „Neuer Benutzer“ mit vorgewähltem **Neue Firma**; dieselbe Wahl gibt es unter Mehr, Benutzer, „+“): Firmenname, Name, E-Mail, Passwort. Der Benutzer bekommt eine eigene, neue Firma mit allen Funktionen und ist deren Chef. Er sieht nur seine eigenen Daten, der Ersteller sieht nichts von dieser Firma (außer in „Firmen verwalten“: Name, Chef, Benutzerzahl, Sperre). Edge Function `create-user` mit `mode: new_company`; der Server prüft über `is_superadmin()`, dass der Aufrufer Superadmin ist. Normale Benutzer und Chefs bekommen die Wahl nicht angezeigt und vom Server ein 403.
- **Firma sperren / freigeben:** Antippen der Firma. Eine gesperrte Firma (Chef und alle Manager) sieht und ändert nichts mehr; beim Anmelden steht „Dein Zugang ist gesperrt“. Die Firma bleibt mit allen Daten erhalten (Funktion `superadmin_set_blocked`).
- **Firma endgültig löschen:** Antippen, „Firma endgültig löschen“, dann den Firmennamen eintippen. Gelöscht werden alle Daten, Dateien und Anmelde-Konten der Firma. **Nicht rückgängig zu machen** (Edge Function `superadmin-delete-firm`, Datenbank-Funktion `superadmin_delete_tenant`).
- Die eigene Firma des Superadmins lässt sich weder sperren noch löschen.
- Weitere Superadmins gibt es nur über einen Eintrag in `platform_admins` (SQL Editor, E-Mail klein geschrieben).
