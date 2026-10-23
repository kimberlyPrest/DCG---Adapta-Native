# Instrucao da Pasta Supabase

Fonte de verdade tecnica do banco DCG dentro do repositorio central.

## Antes de qualquer mudanca

1. `README.md`
2. `docs/ai_context_global.md`
3. `docs/permissoes_e_login.md`
4. `docs/relationships.md`
5. `docs/table_index.md`
6. Dominio afetado em `db/domains/`
7. `db/current/` para nomes reais (quando existir)

## Regras

- Migration nova em `db/migrations/YYYYMMDD_NNN_nome_do_grupo/`, com `README.md`.
- Tabela nova: RLS ligada na mesma migration, policies por acao com `(SELECT public.hub_pode_executar(...))`, `REVOKE ALL ... FROM anon`.
- Tabela com `industria_id`: `SELECT` usa `public.pode_ver_industria(industria_id)`.
- Modulo novo: inserir em `modulos` e `modulo_acoes` na mesma migration (modulo inexistente = acesso negado).
- `npm test` em `tests/` verde antes de aplicar.
- Snapshot aplicado reflete em `db/current/`.
- Decisao estrutural atualiza `docs/ai_context_global.md`; relacionamento atualiza `docs/relationships.md`.

## Nao fazer

- Nao usar `USING (true)` em escrita para `authenticated`.
- Nao criar usuario, senha, token ou dado real em migration.
- Nao usar migration como script operacional (reset de senha, limpeza, correcao).
- Nao dar `GRANT EXECUTE` de `hub_pode_executar_usuario` para `authenticated`.
