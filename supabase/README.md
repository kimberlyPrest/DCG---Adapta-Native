# Supabase DCG — fonte de verdade do banco

Esta pasta é a referência central do banco único do ecossistema DCG (Central DP, IO, Books, CRM, Margem Real).

Quando uma IA, uma IDE ou uma pessoa for mexer em qualquer sistema, ela entende o banco a partir daqui — nunca a partir de migrations dentro dos projetos.

## Diferença em relação ao Lucenera

O Lucenera consolidou um banco que já existia. Aqui o banco nasce do zero (os sistemas antigos são PocketBase). Então:

- não há legado a respeitar: as regras do `AGENTS.md` valem desde a primeira tabela;
- `db/current/` só passa a existir depois da primeira aplicação;
- dados dos sistemas antigos entram por importação rastreável (SPEC própria), não por migration.

## Estado atual (2026-10-23)

- Projeto Supabase: criado (credenciais no `.env` da raiz), Postgres 17, **vazio** — conferido em 2026-10-23 (0 tabelas em `public`, 0 usuários).
- Migrations escritas: `20261023_001_fundacao_identidade_acesso`, `20261023_002_cadastros_mestres`.
- Testadas em Postgres local (PGlite) com stub de `auth`: `cd supabase/tests && npm install && npm test` — 45 casos de permissão e RLS.
- Edge Functions escritas, não publicadas.

## Como usar esta pasta

1. `docs/ai_context_global.md`: decisões estruturais.
2. `docs/permissoes_e_login.md`: contrato de login, permissão e SSO que todo sistema segue.
3. `docs/relationships.md` e `docs/table_index.md`: quem é dono de cada tabela.
4. `db/domains/`: lógica de cada área.
5. `db/migrations/`: alterações, agrupadas por objetivo.
6. `tests/`: rodar antes de aplicar qualquer migration que toque permissão ou RLS.

## Fluxo para mudança de banco

1. SPEC em `03-Projeto/SPECs/`.
2. Migration em `db/migrations/YYYYMMDD_NNN_nome/` com `README.md`.
3. Casos novos em `tests/permissoes.test.mjs` se houver tabela ou policy nova; `npm test` verde.
4. Aplicar no Supabase real.
5. Reextrair `db/current/`.
6. Atualizar domínio, `relationships.md`, `table_index.md` e o `AI_DB_CONTEXT.md` do sistema afetado.

## Estrutura

```text
supabase/
  config.toml     Auth sem cadastro público; JWT por função.
  db/
    current/      Snapshot do banco real (após primeira aplicação).
    domains/      Explicação por domínio.
    migrations/   Migrations centrais.
  docs/           Contexto global para IA, contratos, relações e pendências.
  functions/      Edge Functions centrais (SSO, convite).
  tests/          Testes de permissão/RLS em PGlite.
```
