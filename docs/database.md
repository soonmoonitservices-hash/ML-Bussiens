# Datenbank

Die Datenbank wird ausschließlich über fortlaufend nummerierte Dateien in
`supabase/migrations` geändert. Migrationen 01–15 enthalten Tabellen, Trigger,
RPCs, Views, RLS, Storage-Regeln, Berichte und Änderungsverlauf. Alte
Migrationen werden nach dem Einspielen nicht verändert.

Die öffentliche App nutzt nur den Publishable/Anon-Key. Alle Tabellen sind per
RLS geschützt; kritische Buchungen erfolgen atomar über die in
`docs/backend_api.md` dokumentierten Funktionen. Lokale Prüfung:
`make db-reset`, danach `make test-backend`.
