# Fluxo de Trabalho DCG

Vale para desenvolvedor, IA ou qualquer pessoa que altere sistemas, banco, documentos ou specs.

## 1. Orientação

Identificar: pedido, sistemas afetados, tipo de mudança (código, banco, permissão, documento, processo), SPEC existente, impacto em outros sistemas pelo banco.

Leitura mínima: `README.md`, `AGENTS.md`, `04-Sistemas/00 - Sumario Sistemas.md`, `03-Projeto/00_INDICE.md`, `supabase/README.md`.

## 2. Mudança de documento

Editar o documento, registrar no `CHANGELOG.md` se mudar decisão, pendência ou fluxo.

## 3. Mudança em sistema

1. Confirmar o repositório do sistema em `04-Sistemas/<sistema>/`.
2. Ler o `AI_DB_CONTEXT.md` do sistema e `supabase/docs/permissoes_e_login.md`.
3. Criar/atualizar SPEC.
4. Implementar no repo do sistema; telas novas com `ProtectedRoute`/`pode()`.
5. Rodar testes do sistema.
6. Atualizar contexto local e central; `CHANGELOG.md`.
7. Commit e push no sistema; atualizar ponteiro do submodule; commit no central.

## 4. Mudança de banco

1. SPEC descreve a necessidade.
2. Ler `ai_context_global.md`, `permissoes_e_login.md`, `relationships.md`, domínio.
3. Migration em `supabase/db/migrations/YYYYMMDD_NNN_nome/` com RLS e módulos na mesma pasta.
4. Casos novos em `supabase/tests/permissoes.test.mjs`; `npm test` verde.
5. Aplicar no Supabase real (`.env` local).
6. Reextrair `supabase/db/current/`; atualizar `table_index.md`, `relationships.md`, domínio e `AI_DB_CONTEXT.md` dos sistemas afetados.

## 5. Mudança de permissão

Papéis e atribuições mudam pela UI da Central DP, não por migration. Migration só cria módulo/ação novo. Mudança de papel relevante vai para o `CHANGELOG.md`.

## 6. Mudança que cruza sistemas

SPEC única com sistemas afetados, dado compartilhado, tabelas/funções/policies, ordem de implementação, teste por sistema e rollback.

## 7. Commits

- Código: commit no sistema + commit no central (SPEC, changelog, contexto, ponteiro).
- Só documentação: commit no central.
- PR do sistema cita a SPEC central.
- Nunca ponteiro de submodule para commit não enviado.
