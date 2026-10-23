# Snapshot do banco real

Vazio: o projeto Supabase existe (Postgres 17), mas nenhuma migration foi aplicada (conferido em 2026-10-23).

Após aplicar as migrations, extrair com o `libpq` do Homebrew (`/opt/homebrew/opt/libpq/bin`):

```bash
pg_dump "$SUPABASE_DB_URL" --schema-only --schema=public > 01_schema_full.sql
psql "$SUPABASE_DB_URL" -Atc "select pg_get_functiondef(p.oid) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public'" > 03_functions.sql
psql "$SUPABASE_DB_URL" -Atc "select format('%s.%s %s %s', schemaname, tablename, policyname, cmd) from pg_policies order by 1" > 07_rls_policies.txt
```

Registrar aqui a data da extração e quais migrations ela reflete.
