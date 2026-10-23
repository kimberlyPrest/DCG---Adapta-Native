#!/usr/bin/env bash
# Aplica as migrations centrais (supabase/db/migrations/YYYYMMDD_NNN_nome/) no
# Supabase unico do .env e registra cada grupo em
# supabase_migrations.schema_migrations, o mesmo historico que o Skip e o
# Supabase CLI usam. Assim o banco tem UMA linha do tempo, nao uma por sistema.
#
# Uso:
#   scripts/aplicar-migrations.sh              # simulacao: lista o que esta pendente
#   scripts/aplicar-migrations.sh --confirmar  # aplica os pendentes, um grupo por transacao
#
# Versao registrada: YYYYMMDD + "2" + NNN com 5 digitos (ex.: 20261023_001 ->
# 20261023200001), para ficar depois das migrations de seed do Skip do mesmo dia.
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
MIGRATIONS="$RAIZ/supabase/db/migrations"
PSQL="${PSQL:-/opt/homebrew/opt/libpq/bin/psql}"

ler_env() {
  awk -v k="$1" -F= '$0 ~ "^[[:space:]]*"k"[[:space:]]*=" {
    sub(/^[^=]*=[[:space:]]*/, ""); gsub(/[[:space:]"\r]+$/, ""); gsub(/^"/, ""); print
  }' "$RAIZ/.env"
}

DB_URL="$(ler_env SUPABASE_DB_URL)"
if [ -z "$DB_URL" ]; then
  echo "SUPABASE_DB_URL ausente no .env da raiz." >&2
  exit 1
fi

CONFIRMAR=false
[ "${1:-}" = "--confirmar" ] && CONFIRMAR=true

aplicadas="$("$PSQL" "$DB_URL" -X -A -t -c 'select version from supabase_migrations.schema_migrations')"

pendentes=0
for dir in "$MIGRATIONS"/[0-9]*_[0-9]*_*/; do
  grupo="$(basename "$dir")"
  data="${grupo:0:8}"
  nnn="${grupo:9:3}"
  versao="${data}2$(printf '%05d' "$((10#$nnn))")"
  nome="${grupo:13}"

  if grep -qx "$versao" <<<"$aplicadas"; then
    echo "ja aplicada  $versao  $grupo"
    continue
  fi
  pendentes=$((pendentes + 1))

  if ! $CONFIRMAR; then
    echo "PENDENTE     $versao  $grupo"
    continue
  fi

  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT
  sql="$(cat "$dir"/[0-9]*.sql)"
  {
    echo "$sql"
    printf "INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('%s', '%s', ARRAY[\$dcgmig\$%s\$dcgmig\$]);\n" \
      "$versao" "$nome" "$sql"
  } >"$tmp"

  echo "aplicando    $versao  $grupo"
  "$PSQL" "$DB_URL" -X -q -1 -v ON_ERROR_STOP=1 -f "$tmp"
  rm -f "$tmp"
done

if ! $CONFIRMAR && [ "$pendentes" -gt 0 ]; then
  echo
  echo "$pendentes grupo(s) pendente(s). Rode com --confirmar para aplicar."
fi
