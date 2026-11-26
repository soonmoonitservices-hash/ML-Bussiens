# Architektur

Die Flutter-App folgt Feature-first Clean Architecture. Domainmodelle und
Berechnungen sind unabhängig von Flutter und Supabase. Repositories kapseln
alle externen Zugriffe und liefern `Future<Result<T>>`; Präsentationscode
verwendet ausschließlich diese Repositories. Gemeinsame Infrastruktur liegt
unter `lib/core`, wiederverwendbare UI unter `lib/shared`.

Supabase ist für Authentifizierung, PostgreSQL, private Dateien und atomare
Geschäftsfunktionen zuständig. Kritische Bestands-, Nummern- und
Rechnungslogik bleibt in Datenbank-RPCs. Details und Ordnerstruktur stehen in
`docs/SPEC.md` und `docs/spec/structure.md`.
