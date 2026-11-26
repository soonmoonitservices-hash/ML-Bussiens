#!/usr/bin/env bash
# Setzt die lokale Datenbank zurück (Migrationen + seed.sql).
set -euo pipefail
cd "$(dirname "$0")/.."
npx --yes supabase db reset
