# DCG - Adapta Native

Repositorio central de memoria, contexto, banco consolidado e coordenacao dos sistemas da DCG Consultoria Merchandising e Promocoes (Diretoria Promocoes).

Este repositorio nao substitui os repositorios proprios de cada sistema. Ele e a fonte compartilhada para entender o ecossistema inteiro antes de mexer em codigo, banco, specs ou processos.

## Ecossistema

Todos os sistemas usam **um unico projeto Supabase**: mesmo `auth.users`, mesmo login, mesma matriz de permissoes e mesmos cadastros mestres.

| Sistema | Slug | Base Skip / repo | Papel | Substitui |
|---|---|---|---|---|
| Central DP | `hub` | Sistema 5 / `Daniel-Diretoria/Central-DP` | Hub: catalogo de sistemas, usuarios, permissoes, gestao de trabalho (inclui Ocorrencias) | Gestao de Ocorrencias + login de cada sistema |
| Inteligencia Operacional | `io` | Sistema 1 / `Daniel-Diretoria/Sistema-1` | Fonte de verdade operacional: lojas, redes, promotores, industrias, produtos, validades, rupturas, devolucoes | `intelig-ncia-operacional-mvp` (PocketBase) |
| Auditoria de Books | `books` | Sistema 2 / `Daniel-Diretoria/sistema-2` | Auditoria de execucao por foto | `sistema-de-auditoria-de-books` (PocketBase) |
| CRM de Orcamento e Contratos | `crm` | Sistema 3 / `Daniel-Diretoria/sistema-3` | Comercial: clientes, propostas, contratos, regras operacionais, dimensionamento | `crm-de-or-amento-e-contratos` (PocketBase) |
| Margem Real | `margem-real` | Sistema 4 / `Daniel-Diretoria/sistema-4` | Financeiro gerencial restrito | `margem-real` (PocketBase) |

As 4 bases Skip ja apontam para o Supabase do `.env`. Regras para elas dividirem o banco: `00-Contexto/BANCO_UNICO_SKIP.md`. Codigo legado a portar: `04-Sistemas/_legado-pocketbase/`. Analise: `../Plano — 3a0e27a1/03-Projeto/03-Analise-Sistemas-Existentes.md`.

## Fontes de verdade

- `supabase/`: fonte de verdade do banco, relacionamentos, migrations centrais e contexto tecnico.
- `03-Projeto/SPECs/`: SPECs que cruzam sistemas ou alteram banco.
- `04-Sistemas/`: submodules dos repositorios proprios de cada sistema + template de contexto local.
- `00-Contexto/`: regras de trabalho, inventario de repositorios e instrucoes para manter a memoria compartilhada.
- Escopo, reunioes e mapeamento de processos continuam em `../Plano — 3a0e27a1/`.

## Leitura obrigatoria antes de qualquer mudanca

1. `AGENTS.md`
2. `00-Contexto/FLUXO_DE_TRABALHO.md`
3. `04-Sistemas/00 - Sumario Sistemas.md`
4. `supabase/README.md`
5. `supabase/docs/ai_context_global.md`

Se a mudanca envolver banco, permissao ou relacionamento entre sistemas, ler tambem:

1. `supabase/docs/permissoes_e_login.md`
2. `supabase/docs/relationships.md`
3. `supabase/docs/table_index.md`
4. O dominio afetado em `supabase/db/domains/`

## Regra de ouro

Toda alteracao relevante deixa rastro nos dois lugares certos:

1. Repositorio do sistema afetado: codigo, teste e contexto local.
2. Este repositorio central: SPEC, changelog, banco consolidado ou decisao atualizada.

## Ambiente local

Criar manualmente um `.env` na raiz a partir de `.env.example`. Nunca commitar.

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_DB_URL`

## Estrutura

```text
DCG - Adapta Native/
  00-Contexto/     Regras de trabalho, memoria operacional e inventario.
  01-Documento/    Dados de entrada, planilhas e materiais brutos (sem dados pessoais versionados).
  02-Reunioes/     Decisoes tecnicas vindas de reunioes (atas completas ficam no Plano).
  03-Projeto/      SPECs.
  04-Sistemas/     Submodules dos sistemas + _template-sistema.
  supabase/        Fonte de verdade tecnica do banco e Edge Functions.
  AGENTS.md        Instrucao geral para IA/desenvolvedor.
  CHANGELOG.md     Registro cronologico.
```

## Git

Os sistemas com repositorio proprio entram como submodules em `04-Sistemas/` (ver `00-Contexto/SUBMODULES.md`). Todos os repositorios devem ser **privados** (achado T-01 da analise).
