# SPEC-002 — Cadastros mestres compartilhados

- **Status:** escrita e testada localmente; não aplicada
- **Data:** 2026-10-23
- **Sistemas:** io (dono), crm, books, margem-real (consumidores), hub (escopo de usuário)
- **Depende de:** SPEC-001

## Problema

Achado T-20 da análise: loja existe em 6 coleções de 5 sistemas, promotor em 6, indústria/cliente em 6, produto em 2, cada uma com chave diferente. Sem cadastro único não há como cruzar ruptura (IO), nota de book (Books), contrato (CRM) e margem (Margem Real) da mesma loja ou indústria.

## Solução

Uma tabela por entidade, com dono de escrita definido pela matriz de permissões (seção 9 da análise):

| Tabela | Escreve | Lê |
|---|---|---|
| `empresas_dcg` | margem-real/empresa | interno |
| `redes`, `lojas` | io/cadastros | todo usuário ativo |
| `industrias` | io/cadastros ou crm/clientes | escopo por indústria |
| `produtos` | io/cadastros | escopo por indústria |
| `colaboradores` | io/cadastros | interno |
| `cadastro_aliases` | io/cadastros | interno |
| `usuario_industrias` | hub/usuarios | próprio + hub/usuarios |

Usuário `tipo = industria` só vê o que `usuario_industrias` libera (`pode_ver_industria`), no banco. Corrige T-09.

Dado de pagamento de colaborador (salário, PIX, banco) e dado específico de sistema ficam fora do mestre, em tabela do sistema com FK.

## Banco

Migration `supabase/db/migrations/20261023_002_cadastros_mestres/`. Módulos criados: `io/cadastros`, `crm/clientes`, `margem-real/empresa` (visualizar, criar, editar, deletar).

## Critérios de aceite

- [x] Casos de RLS dos mestres verdes em `supabase/tests/permissoes.test.mjs`.
- [ ] Mapeamento coleção PocketBase → mestre para os 4 sistemas (entra no `AI_DB_CONTEXT.md` de cada um).
- [ ] Script de importação com deduplicação via `cadastro_aliases`, a partir da IO (fonte de verdade), com relatório de conflitos.

## Pendências

PD-02 (indústria = cliente?), PD-03 (CPF no mestre?), PD-04 (CRM escreve loja?) em `supabase/docs/pending_decisions.md`.
