#!/usr/bin/env bash
# Setzt die lokale Datenbank zurück (Migrationen + seed.sql) und führt die Backend-Tests aus.
# Pflicht vor einem Release: start_tour.test.sql und close_tour.test.sql.
# extended.test.sql ist der längere Gesamtablauf (Rechnung, Storno, Sperren, Auswertungen).
# Jede Testdatei bekommt supabase/tests/_helpers.sql vorangestellt und setzt am Ende ein ROLLBACK.
set -euo pipefail
cd "$(dirname "$0")/.."

npx --yes supabase db reset

for test_file in supabase/tests/*.test.sql; do
  echo "== $(basename "$test_file")"
  cat supabase/tests/_helpers.sql "$test_file" \
    | docker exec -i supabase_db_warenbestand psql -U postgres -d postgres -X -q -t -A
done
