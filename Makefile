# Befehle für das Backend. Die Flutter-Befehle (run-dev, run-prod, codegen, test, build-*) kommen mit dem Flutter-Projekt.
.PHONY: run-dev run-prod codegen test build-ios build-android db-start db-stop db-reset db-push db-lint test-backend

run-dev:
	flutter run --dart-define-from-file=config/dev.json

run-prod:
	flutter run --dart-define-from-file=config/prod.json

codegen:
	dart run build_runner build --delete-conflicting-outputs

test:
	flutter analyze && flutter test

build-ios:
	flutter build ipa --dart-define-from-file=config/prod.json

build-android:
	flutter build appbundle --dart-define-from-file=config/prod.json

db-start:
	npx supabase start

db-stop:
	npx supabase stop

# Setzt die lokale Datenbank zurück (Migrationen + seed.sql)
db-reset:
	npx supabase db reset

# Spielt die Migrationen auf das verknüpfte Produktions-Projekt (vorher: supabase link)
db-push:
	npx supabase db push

db-lint:
	npx supabase db lint --level warning --fail-on error

test-backend:
	bash scripts/test_backend.sh
