# Sumário dos sistemas DCG

Estado em 2026-10-23. Detalhes do banco compartilhado e regras para o Skip: `00-Contexto/BANCO_UNICO_SKIP.md`.

## Bases novas (Skip + Supabase único)

| Sistema | Slug | Pasta | Repo | Projeto Skip | Commit |
|---|---|---|---|---|---|
| Central DP | `hub` | — (5ª base, a criar) | — | — | — |
| Inteligência Operacional | `io` | `sistema-1-io/` | `Daniel-Diretoria/Sistema-1` | 69061 "Sistema 1" | `26d1bcb` |
| Auditoria de Books | `books` | `sistema-2-books/` | `Daniel-Diretoria/sistema-2` | 69056 "Sistema 2" | `505f888` |
| CRM de Orçamento e Contratos | `crm` | `sistema-3-crm/` | `Daniel-Diretoria/sistema-3` | 69058 "Sistema 3" | `dbb820e` |
| Margem Real | `margem-real` | `sistema-4-margem-real/` | `Daniel-Diretoria/sistema-4` | 69057 "Sistema 4" | `27f054f` |

As 4 bases têm só a tela de login do template Skip e apontam para o Supabase do `.env`. Nada foi implementado nelas ainda.

## Código legado a portar (`_legado-pocketbase/`)

Cópias dos repos PocketBase de `../Plano — 3a0e27a1/05 - sistemas/`, com histórico e alterações locais preservados. Os originais continuam lá.

| Pasta | Vira | Commit | Pendências locais |
|---|---|---|---|
| `intelig-ncia-operacional-mvp-0z6ruqoxc/` | sistema-1-io | `e99ea53` | **156 em staging, sem commit** |
| `sistema-de-auditoria-de-books-ceb4pqbl5/` | sistema-2-books | `72ffc89` | 6 em staging |
| `crm-de-or-amento-e-contratos-pthayt36e/` | sistema-3-crm | `563de9b` | nenhuma |
| `margem-real-jx91subtk/` | sistema-4-margem-real | `f5f3597` | nenhuma |

Fora por decisão: Gestão de Ocorrências (vai para a Central DP, D-01) e os dois repos incorporados.

## Ordem de migração por sistema

1. SPEC do sistema em `03-Projeto/SPECs/` (módulos, ações, tabelas próprias, mapa coleção PocketBase → tabela Supabase).
2. Migration central com tabelas, módulos e RLS; `scripts/aplicar-migrations.sh --confirmar`.
3. Na base Skip: regenerar `types.ts`, instalar `src-auth` com o slug, portar telas do legado trocando PocketBase por Supabase.
4. Preencher `<base>/supabase/` com o pacote de `_template-sistema/supabase/`.
5. Hooks PocketBase → Edge Functions ou funções SQL; crons → `pg_cron`.
6. Importar dados reais por script rastreável (nunca migration).

Ordem sugerida: fundação (SPEC-001/002) → IO (dona dos mestres) → CRM → Books → Margem Real. Central DP quando a 5ª base existir; até lá usuários e papéis pelo painel/SQL.

## Segurança

Legado: senhas em migrations, dados reais no Margem Real, rotas de depuração no CRM — não publicar nada de `_legado-pocketbase/` sem saneamento. Bases novas: achados B-01 a B-04 em `00-Contexto/BANCO_UNICO_SKIP.md`.
