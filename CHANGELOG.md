# CHANGELOG

## 2026-10-23 — Base Skip da Central DP (Sistema 5)

- **Área:** 04-Sistemas.
- **Feito:** `Daniel-Diretoria/Central-DP` clonada em `04-Sistemas/sistema-5-central-dp/` e registrada como submodule (`64fe1b5`). Já aponta para o Supabase único; traz só o login do template e a migration de seed do Skip.
- **Nada alterado** no Skip ou no Supabase.

## 2026-10-23 — Análise dos 4 bancos e plano de unificação

- **Área:** banco, todos os sistemas.
- **Feito:** análise dos esquemas dos 4 PocketBase (git + produção lida no Skip, somente leitura) e `03-Projeto/PLANO-UNIFICACAO-BANCO.md` com anexo de mapa (135 coleções → destino).
- **Achados principais:** produção à frente do git (CRM +12 coleções/+12 hooks; MR +5 coleções/+24 hooks); pontes HTTP MR↔CRM casando promotor por nome; 5 sobreposições novas (CNPJ, contrato, troca/devolução, agenda, sortimento); rotas de depuração ainda em produção no CRM.
- **Decisões abertas:** D-U1 a D-U10 no plano.
- **Nada alterado** em produção, no Skip ou no Supabase.

## 2026-10-23 — Bases Skip e banco único

- **Área:** 04-Sistemas, banco, auth.
- **Contexto:** os 4 sistemas serão reconstruídos em 4 bases Skip novas (`Daniel-Diretoria/Sistema-1..4`, projetos Skip 69061/69056/69058/69057) sobre o Supabase do `.env`. Mapeamento: 1=IO, 2=Books, 3=CRM, 4=Margem Real. Central DP ganha uma 5ª base depois.
- **Conferido:** as 4 bases já apontam para o mesmo projeto Supabase; banco com 0 tabelas, 1 usuário (Daniel, criado pelos seeds das bases 2/3/4) e 3 migrations de seed no histórico. Repos das bases públicos; cadastro público ligado no projeto.
- **Feito:**
  - Bases clonadas em `04-Sistemas/sistema-N-*`; cópias PocketBase movidas para `04-Sistemas/_legado-pocketbase/` (alterações pendentes preservadas).
  - `001_usuarios.sql`: carga de usuários pré-existentes e leitura de `name` no metadata. Teste novo (46/46).
  - `src-auth` refeito para o template Skip; `tsc` e build OK numa cópia da base Sistema-1.
  - `scripts/aplicar-migrations.sh` (simulação por padrão; `--confirmar` aplica e registra em `supabase_migrations.schema_migrations`).
  - `00-Contexto/BANCO_UNICO_SKIP.md` com regras e achados B-01 a B-04.
- **Não feito (por decisão):** nada implementado no Skip; nenhuma migration aplicada; nenhuma configuração do projeto Supabase alterada.
- **Incidente:** ao ler o `.env` com `source`, os valores (incluindo `service_role` e senha do banco) apareceram no log da sessão. Ver PD-09.

## 2026-10-23 — Criação do repositório central

- **Área:** ecossistema inteiro.
- **Decisão:** os 5 sistemas DCG passam a usar um único projeto Supabase, com login, matriz de permissões e cadastros mestres compartilhados, no mesmo modelo do Lucenera - ADAPTA PASS. Ocorrências vira parte da Central DP (D-01).
- **Criado:**
  - Estrutura do repositório central (`README.md`, `AGENTS.md`, `00-Contexto/`, `03-Projeto/`, `04-Sistemas/`, `supabase/`).
  - SPEC-001 (login, permissões, SSO) e SPEC-002 (cadastros mestres).
  - Migrations `20261023_001_fundacao_identidade_acesso` e `20261023_002_cadastros_mestres`.
  - Edge Functions `generate-cross-system-code`, `exchange-cross-system-code`, `admin-convidar-usuario`.
  - Testes de permissão/RLS em PGlite (`supabase/tests`, 45 casos verdes).
  - Pacote de auth padrão (`04-Sistemas/_template-sistema/src-auth/`, typecheck strict OK) e pacote de contexto local.
- **Sistemas copiados para `04-Sistemas/`:** IO, Books, CRM, Margem Real, a partir de `Plano — 3a0e27a1/05 - sistemas/`, com `.git` e alterações locais preservados (IO: 156 em staging; Books: 6). Originais intactos.
- **Banco:** projeto Supabase criado (`.env` preenchido), Postgres 17, vazio. Migrations **não aplicadas**, por decisão de aguardar.
- **Repositórios que precisam de ação:** os 4 sistemas (tornar privados, sanear segredos antes de qualquer push); repo central (criar no GitHub, privado).
