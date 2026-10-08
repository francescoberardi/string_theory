#!/usr/bin/env bash
# Verifies the Story 6.3 UUID tenant migration on a populated database (R-001).
#
# 1. Builds a database at the baseline migration (bigint tenant ids) from its
#    definition.sql and seeds an auth user plus one row in each tenant table.
# 2. Applies every later migration.sql, in migration_registry.txt order.
# 3. Asserts the four tenant tables are empty, the auth user is kept, and the
#    string_theory migration version is the latest one.
# 4. Asserts the migrated schema equals a fresh database built from the latest
#    definition.sql (`pg_dump --schema-only`, comments stripped).
#
# Needs psql and pg_dump on the PATH and a PostgreSQL server reached through
# the libpq environment (PGHOST, PGPORT, PGUSER, PGPASSWORD). The PGUSER must
# be allowed to create databases. Two scratch databases are created and
# dropped again; existing databases are not touched.
set -euo pipefail

BASELINE="${BASELINE:-20261005101241116}"
export PGOPTIONS="${PGOPTIONS:-} -c client_min_messages=warning"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
migrations_dir="$script_dir/../migrations"
registry="$migrations_dir/migration_registry.txt"

for tool in psql pg_dump; do
  command -v "$tool" >/dev/null || {
    echo "error: $tool not found on PATH" >&2
    exit 1
  }
done

latest="$(grep -v '^[[:space:]]*$' "$registry" | tail -n 1)"
pending=()
found_baseline=false
while IFS= read -r version; do
  [ -z "$version" ] && continue
  if $found_baseline; then
    pending+=("$version")
  elif [ "$version" = "$BASELINE" ]; then
    found_baseline=true
  fi
done <"$registry"

if ! $found_baseline; then
  echo "error: baseline $BASELINE is not in $registry" >&2
  exit 1
fi
if [ "${#pending[@]}" -eq 0 ]; then
  echo "error: no migration after baseline $BASELINE" >&2
  exit 1
fi

suffix="$$_$(date +%s)"
seeded_db="st_verify_seeded_$suffix"
fresh_db="st_verify_fresh_$suffix"
work_dir="$(mktemp -d)"

psql_admin() { psql -X -q -v ON_ERROR_STOP=1 -d "${PGDATABASE:-postgres}" "$@"; }
psql_on() {
  local db="$1"
  shift
  psql -X -q -v ON_ERROR_STOP=1 -d "$db" "$@"
}
scalar() { psql -X -q -A -t -v ON_ERROR_STOP=1 -d "$1" -c "$2"; }

cleanup() {
  psql_admin -c "DROP DATABASE IF EXISTS \"$seeded_db\";" >/dev/null 2>&1 || true
  psql_admin -c "DROP DATABASE IF EXISTS \"$fresh_db\";" >/dev/null 2>&1 || true
  rm -rf "$work_dir"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

echo "Baseline: $BASELINE"
echo "Applying: ${pending[*]}"

psql_admin -c "CREATE DATABASE \"$seeded_db\";"
psql_admin -c "CREATE DATABASE \"$fresh_db\";"

# 1. Populated database at the baseline.
psql_on "$seeded_db" -f "$migrations_dir/$BASELINE/definition.sql" >/dev/null
auth_user_id="6f1e2a7d-4c1d-4f7a-9c43-0b9a5e0e1a01"
psql_on "$seeded_db" >/dev/null <<SQL
BEGIN;
INSERT INTO "serverpod_auth_core_user" ("id", "createdAt", "scopeNames", "blocked")
  VALUES ('$auth_user_id', now(), '[]', false);
INSERT INTO "racquet" ("id", "userId", "name") VALUES (1, 8826879987572848887, 'Seeded Racquet');
INSERT INTO "string_job" ("id", "userId", "racquetId", "materialCategory", "totalCourtHours", "currentHealthScore")
  VALUES (1, 8826879987572848887, 1, 'coPoly', 1.5, 93);
UPDATE "racquet" SET "activeStringJobId" = 1 WHERE "id" = 1;
INSERT INTO "session_log" ("userId", "racquetId", "startTime", "durationMinutes", "source", "externalWorkoutId")
  VALUES (8826879987572848887, 1, now(), 90, 'HealthKit', 'hk-seeded');
INSERT INTO "restring_event" ("userId", "racquetId", "stringJobId", "stringDescription", "materialCategory",
    "stringingDate", "restringDate", "finalCourtHours", "finalDaysActive", "finalHealthScore")
  VALUES (8826879987572848887, 1, 1, 'Seeded setup', 'coPoly', now(), now(), 1.5, 0, 93);
COMMIT;
SQL

for table in racquet string_job session_log restring_event; do
  [ "$(scalar "$seeded_db" "SELECT count(*) FROM \"$table\";")" = "1" ] ||
    fail "seed row missing in $table"
done

# 2. Apply the pending migrations.
for version in "${pending[@]}"; do
  psql_on "$seeded_db" -f "$migrations_dir/$version/migration.sql" >/dev/null
done

# 3. Data assertions.
for table in racquet string_job session_log restring_event; do
  count="$(scalar "$seeded_db" "SELECT count(*) FROM \"$table\";")"
  [ "$count" = "0" ] || fail "$table has $count rows after migration, expected 0"
done
auth_count="$(scalar "$seeded_db" \
  "SELECT count(*) FROM \"serverpod_auth_core_user\" WHERE \"id\" = '$auth_user_id';")"
[ "$auth_count" = "1" ] || fail "auth user was not kept by the migration"
version="$(scalar "$seeded_db" \
  "SELECT \"version\" FROM \"serverpod_migrations\" WHERE \"module\" = 'string_theory';")"
[ "$version" = "$latest" ] ||
  fail "string_theory migration version is $version, expected $latest"

# 4. Schema assertion against the latest definition.sql.
psql_on "$fresh_db" -f "$migrations_dir/$latest/definition.sql" >/dev/null

dump_schema() {
  # Drop comments, blank lines and pg_dump's per-run \restrict keys.
  pg_dump --schema-only --no-owner --no-privileges -d "$1" |
    grep -v -e '^--' -e '^[[:space:]]*$' -e '^\\restrict' -e '^\\unrestrict'
}
dump_schema "$seeded_db" >"$work_dir/migrated.sql"
dump_schema "$fresh_db" >"$work_dir/definition.sql"

if ! diff -u "$work_dir/definition.sql" "$work_dir/migrated.sql"; then
  fail "migrated schema differs from $latest/definition.sql"
fi

echo "OK: tenant tables emptied, auth user kept, schema matches $latest/definition.sql"
