# Clean Code & Clean Architecture – verbindliche Regeln

Ziel: Code, den ein fremder Entwickler in 1 Stunde versteht, den man ohne Angst ändern kann und bei dem jede Regel nur an EINER Stelle steht.
Grundsätze: Clean Architecture (Robert C. Martin), SOLID, DRY, KISS, YAGNI. Im Zweifel: einfacher statt cleverer.

## 1. Schichten & Abhängigkeitsregel

Pro Feature drei Schichten: `presentation → domain ← data`

- **domain** (Kern): Modelle (freezed), Repository-INTERFACES, Services mit Geschäftslogik. Reines Dart: KEIN Import von flutter, supabase, riverpod, drift, pdf. Kennt keine andere Schicht.
- **data**: implementiert die Repository-Interfaces mit Supabase/drift. Einziger Ort, an dem `supabase_flutter` importiert wird. Wandelt Datenbankfehler in `AppException` um.
- **presentation**: Screens, Widgets, Controller (Riverpod). Spricht NUR mit domain (Interfaces + Services), nie direkt mit data.
- `core/` und `shared/`: von allen nutzbar, kennen aber KEINE Features.
- Features importieren sich NICHT gegenseitig. Gemeinsames gehört nach `core/` (Logik) oder `shared/` (UI). Ausnahme: Picker-Widgets (z. B. ProductPickerSheet) über einen öffentlichen Export des Features (`features/products/products.dart`).
- Verdrahtung (welche Implementierung zu welchem Interface) NUR in `<feature>_providers.dart`.

Verboten: Supabase-Aufruf in Widget oder Controller · BuildContext/Widgets/Farben in domain · Geschäftslogik in Widgets · Feature importiert `data/` eines anderen Features.

## 2. SOLID konkret

- **S:** Eine Klasse, eine Aufgabe (SettlementCalculator rechnet nur Abrechnung; TourCloseController steuert nur den Screen-Zustand; ToursRepository nur Datenzugriff).
- **O:** Erweitern statt ändern. Neue Dokumentart = neuer PDF-Builder aus vorhandenen Bausteinen, keine if/else-Ketten im PdfService.
- **L:** Implementierungen austauschbar. FakeToursRepository verhält sich wie SupabaseToursRepository.
- **I:** Kleine Interfaces. Kein „AppRepository“ mit 50 Methoden; ein Repository pro Feature.
- **D:** Abhängig von Abstraktionen. Controller bekommen Repository-Interfaces über Riverpod, nie `new`.

## 3. Größen-Grenzen (hart)

- Datei max. 300 Zeilen · Klasse max. 200 · Methode max. 30 Zeilen, max. 3 Ebenen Verschachtelung
- `build()` max. 60 Zeilen → Teile in eigene Widget-KLASSEN (keine `_buildXyz()`-Methoden, die Widgets zurückgeben)
- Parameter max. 4, sonst Parameter-Objekt
- Eine öffentliche Klasse pro Datei, Dateiname = Klassenname in snake_case

## 4. Benennung

- Englisch im Code, Deutsch nur in Nutzertexten (ARB).
- Namen sagen WAS, nicht WIE: ✓ `soldQuantity`, `expectedCashCents`, `isBelowMinStock` · ✗ `val`, `tmp`, `data2`, `flag`, `calc()`
- Geld-Variablen enden auf `Cents` (`amountCents`), Gewicht auf `Grams`.
- bool beginnt mit `is/has/can/should`. Methoden sind Verben: `loadTours()`, `closeTour()`, `calculateSettlement()`.
- Klassen-Endungen: `…Screen`, `…Widget` (nur wenn nötig), `…Controller`, `…State`, `…Repository` (Interface), `Supabase…Repository` (Implementierung), `…Calculator`/`…Service` (Logik), `…PdfBuilder`, `…Dto` (nur falls nötig).
- Keine Abkürzungen außer allgemein bekannten (id, url, pdf, vat).

## 5. Modelle & Daten

- Alle Modelle immutable mit freezed, Änderungen nur über `copyWith`.
- JSON-Mapping automatisch (`build.yaml`: `field_rename: snake`).
- Keine nullable Felder ohne fachlichen Grund. Status als Enum, nie als String vergleichen.
- Geld nur als `Money`, Mengen nur als `Quantity` (Value Objects in `core/`).
- Keine Magic Numbers (250 € Kleinbetragsgrenze, 25 Pagination usw.): benannte Konstanten in `core/constants/`.

## 6. Fehlerbehandlung

- Repositories werfen nie, sie geben `Result<T>` zurück (Success/Failure).
- Exceptions nur in `data/` fangen und in `AppException` übersetzen.
- Kein leerer catch, kein `catch (e) { print(e); }`. Kein `!` außer nach expliziter Prüfung direkt davor.
- Controller wandeln Failure in UI-Zustand (Fehlermeldung), nie Absturz.
- Unerwartete Fehler an `ErrorLogger`, Nutzer sieht eine verständliche Meldung.

## 7. State Management (Riverpod)

- Code-Generierung (`@riverpod`), keine handgeschriebenen Provider-Varianten mischen.
- Daten lesen: AsyncNotifier/FutureProvider, Anzeige immer über `AsyncValueView` (Laden/Fehler/Daten an einer Stelle).
- Formulare: eigener Notifier mit freezed-State (Felder, `isSubmitting`, `errorMessage`, `fieldErrors`).
- Widgets: `ref.watch` nur für Anzeige, `ref.read` nur in Callbacks.
- Kein globaler veränderbarer Zustand, keine Singletons außer über Provider. `autoDispose` als Standard.

## 8. Widgets

- Stateless bevorzugen; StatefulWidget nur für reine UI-Zustände (Animation, TextEditingController).
- `const` überall, wo möglich.
- Keine Farben, Schriftgrößen, Abstände direkt im Widget → nur Theme-Tokens (`context.colors`, `AppSpacing`, `AppTextStyles`).
- Keine Texte direkt im Widget → nur `context.l10n`.
- Erst Bausteine aus `shared/` nutzen. Wird etwas 2× gebraucht → nach `shared/` verschieben.
- Widgets bekommen fertige Daten, rechnen nichts.

## 9. Geschäftslogik

- Steht an GENAU zwei Orten mit demselben Ergebnis: Datenbank-Funktion (maßgeblich, speichert) und Dart-Service in `domain/services` (Live-Anzeige).
- Jede Formel hat einen Unit-Test mit den Beispielen aus der Spezifikation und ist in `docs/calculations.md` dokumentiert.
- Keine Logik in SQL-Views, die nicht auch dokumentiert ist.

## 10. Kommentare & Dokumentation

- Kommentare erklären WARUM, nicht WAS. ✓ `// Preise kopieren, damit spätere Preisänderungen alte Touren nicht ändern`
- Jede öffentliche Klasse und jedes Repository-Interface hat einen `///`-Doc-Kommentar (1–3 Sätze).
- Keine auskommentierten Code-Blöcke. Keine TODOs im fertigen Code (stattdessen GitHub-Issue).

## 11. DRY · KISS · YAGNI

- DRY: Gleicher Code an 2 Stellen → Hilfsfunktion/Baustein. Gilt auch für SQL (z. B. `line_value_cents`).
- KISS: Einfachste Lösung, die alle Anforderungen erfüllt. Keine eigenen Frameworks, keine Generics „für später“.
- YAGNI: Nur bauen, was in der Spezifikation steht (Ausnahme: ausdrücklich genannte Vorbereitungen wie Arabisch/RTL).

## 12. Lints & Format

- `very_good_analysis` plus: `prefer_const_constructors`, `require_trailing_commas`, `avoid_dynamic_calls`, `always_use_package_imports`, `public_member_api_docs` (nur für `domain/` und `core/`).
- `dart format` mit Zeilenlänge 100. Importe sortiert: dart → package → projekt.
- 0 Warnungen erlaubt (CI bricht ab).

## 13. SQL-Regeln

- Kleinschreibung, snake_case, Tabellen im Plural.
- Jede Migration macht EINE Sache, der Name beschreibt sie.
- Jede Funktion: `set search_path`, deutsche Fehlermeldungen, kurzer Kommentar.
- Gemeinsame Hilfsfunktionen mit `_` am Anfang. Keine Logik doppelt.
- Alte Migrationen nie ändern, nur neue anhängen.

## 14. Tests als Qualitätsbeweis

- domain/services: Unit-Tests Pflicht. Fakes statt Mocks, wo möglich (FakeRepository in `test/helpers`).
- Testnamen beschreiben Verhalten: `'gibt Fehlbetrag −8,00 € zurück, wenn 860 € statt 868 € übergeben werden'`
- Arrange · Act · Assert sichtbar getrennt.

## 15. Referenz-Muster

```dart
// domain/drivers_repository.dart
/// Zugriff auf Fahrer.
abstract interface class DriversRepository {
  Future<Result<Page<Driver>>> fetch({required int offset, String? search});
  Future<Result<Driver>> save(Driver driver);
  Future<Result<void>> setActive(String id, {required bool isActive});
}

// data/supabase_drivers_repository.dart
final class SupabaseDriversRepository implements DriversRepository {
  const SupabaseDriversRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<Result<Driver>> save(Driver driver) => guard(() async {
        final row = await _client
            .from(Tables.drivers)
            .upsert(driver.toJson())
            .select()
            .single();
        return Driver.fromJson(row);
      });
  // …
}

// drivers_providers.dart
@riverpod
DriversRepository driversRepository(Ref ref) =>
    SupabaseDriversRepository(ref.watch(supabaseClientProvider));

// presentation/controllers/driver_form_controller.dart
@riverpod
class DriverFormController extends _$DriverFormController {
  @override
  DriverFormState build(Driver? initial) => DriverFormState.from(initial);

  Future<bool> submit() async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await ref.read(driversRepositoryProvider).save(state.toDriver());
    return result.when(
      success: (_) {
        ref.invalidate(driversListProvider);
        return true;
      },
      failure: (error) {
        state = state.copyWith(isSubmitting: false, errorMessage: error.message);
        return false;
      },
    );
  }
}
```

Alle Features folgen exakt diesem Muster.

## 16. Code-Review-Checkliste (vor jedem „fertig“)

- [ ] Abhängigkeitsregel eingehalten (domain ohne Flutter/Supabase)?
- [ ] Keine Datei > 300 Zeilen, keine Methode > 30 Zeilen?
- [ ] Keine festen Texte, Farben, Abstände, Magic Numbers?
- [ ] Nichts doppelt, was schon in `core/` oder `shared/` existiert?
- [ ] Fehler über Result behandelt, keine leeren catch?
- [ ] Namen verständlich ohne Kommentar?
- [ ] Tests für neue Logik vorhanden und grün?
- [ ] `flutter analyze`: 0 Hinweise?
- [ ] Würde ein fremder Entwickler das sofort verstehen?

## 17. Refactoring (Ergänzung)

- Refactoring ändert nur die Struktur, nie das Verhalten. Vorher Tests grün, nachher Tests grün.
- Kleine Schritte, ein Refactoring pro Commit, getrennt von Feature- und Bugfix-Commits.
- Auslöser sind Verstöße gegen die Checkliste (Abschnitt 16): zu große Dateien/Methoden, doppelte Logik, Schichtverletzungen. Pfadfinderregel: Was man anfasst, hinterlässt man sauberer.
- Keine Spekulation (YAGNI): nicht „für später“ umbauen, sondern wenn der Code es konkret verlangt.
- Fehlt ein Test für die Stelle, zuerst einen Test schreiben, dann umbauen.
