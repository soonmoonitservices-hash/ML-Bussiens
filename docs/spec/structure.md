# Projektstruktur

Die App folgt Feature-first Clean Architecture:

```text
lib/core/                 Konfiguration, Theme, Router, Fehler, Formatierung
lib/shared/               Wiederverwendbare Widgets und Layouts
lib/features/<feature>/   data, domain, presentation und bei Bedarf pdf
lib/l10n/                 ARB und generierte Lokalisierung
supabase/migrations/      Nur vorwärts gerichtete Datenbankänderungen
test/                     Reine Logik- und PDF-Tests
```

Domain-Code kennt weder Flutter noch Supabase. Präsentation greift nur über
Repositories auf Daten zu. Neue Features übernehmen das Fahrer-Muster aus
Domainmodell, Repository mit `Result<T>`, Präsentationszustand, Pagination,
Fehlerbehandlung und gezielter Invalidierung.

Vollständige Regeln: [`../CLEAN_CODE.md`](../CLEAN_CODE.md) und
[`../SPEC.md`](../SPEC.md), Abschnitte 2 und 16.
