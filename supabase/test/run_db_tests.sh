#!/usr/bin/env bash
# =====================================================================
# Testy bazy danych na PRAWDZIWYCH migracjach.
#
# Aplikuje shim (preamble) + wszystkie migracje + granty (jak Supabase),
# po czym uruchamia każdy plik z tests/*.sql w osobnej sesji psql.
# Każdy test sam zgłasza błąd (RAISE EXCEPTION) gdy asercja nie przejdzie;
# `ON_ERROR_STOP=1` powoduje niezerowy kod wyjścia → CI czerwone.
#
# Tryby:
#   ./run_db_tests.sh --local     boot efemerycznego Postgresa (lokalnie)
#   ./run_db_tests.sh             użyj istniejącego serwera (CI service);
#                                 połączenie przez zmienne PG* (PGHOST itd.)
# =====================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATIONS="$(cd "$HERE/../migrations" && pwd)"
DB="${PGDATABASE:-app_test}"

LOCAL=0
[[ "${1:-}" == "--local" ]] && LOCAL=1

PG_PID_DIR=""
cleanup() {
  if [[ "$LOCAL" == "1" && -n "$PG_PID_DIR" ]]; then
    runuser -u postgres -- /usr/lib/postgresql/16/bin/pg_ctl \
      -D "$PG_PID_DIR" stop -m fast -w >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if [[ "$LOCAL" == "1" ]]; then
  PGBIN=/usr/lib/postgresql/16/bin
  export PGHOST=/tmp PGPORT=5433 PGUSER=postgres
  PG_PID_DIR="$(mktemp -d /tmp/pgdb.XXXXXX)"
  chown postgres:postgres "$PG_PID_DIR"
  runuser -u postgres -- "$PGBIN/initdb" -D "$PG_PID_DIR" \
    --auth=trust -U postgres >/dev/null
  runuser -u postgres -- "$PGBIN/pg_ctl" -D "$PG_PID_DIR" \
    -o "-p $PGPORT -k /tmp -c listen_addresses=''" \
    -l "$PG_PID_DIR/server.log" -w start >/dev/null
fi

PSQL=(psql -v ON_ERROR_STOP=1 -X -q)

echo ">> tworzę bazę $DB"
"${PSQL[@]}" -d postgres -c "drop database if exists $DB" >/dev/null
"${PSQL[@]}" -d postgres -c "create database $DB" >/dev/null

echo ">> shim (preamble)"
"${PSQL[@]}" -d "$DB" -f "$HERE/preamble.sql" >/dev/null

echo ">> migracje"
for f in $(ls "$MIGRATIONS"/*.sql | sort); do
  "${PSQL[@]}" -d "$DB" -f "$f" >/dev/null
  echo "   applied $(basename "$f")"
done

echo ">> granty (jak Supabase: dostęp dla anon/authenticated)"
"${PSQL[@]}" -d "$DB" >/dev/null <<'SQL'
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public
  to anon, authenticated, service_role;
grant all on all sequences in schema public
  to anon, authenticated, service_role;
SQL

echo ">> testy"
fail=0
for t in $(ls "$HERE"/tests/*.sql | sort); do
  if "${PSQL[@]}" -d "$DB" -f "$t" >/tmp/dbtest.log 2>&1; then
    echo "   PASS $(basename "$t")"
  else
    echo "   FAIL $(basename "$t")"
    sed 's/^/      /' /tmp/dbtest.log
    fail=1
  fi
done

if [[ "$fail" == "1" ]]; then
  echo ">> NIEKTÓRE TESTY BAZY PADŁY"
  exit 1
fi
echo ">> wszystkie testy bazy zielone"
