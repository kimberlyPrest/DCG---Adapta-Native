# SPEC-001 — Fundação: login único, matriz de permissões e SSO

- **Status:** escrita e testada localmente; não aplicada (projeto Supabase criado e vazio, aguardando OK)
- **Data:** 2026-10-23
- **Sistemas:** todos (hub, io, books, crm, margem-real)
- **Base:** SPEC-006 e SPEC-007 do Lucenera, com as correções das SPEC-063/069/085 de lá incorporadas desde o início.

## Problema

Os 5 sistemas da DCG têm 5 bancos PocketBase, 5 cadastros de usuário e 5 modelos de permissão diferentes (análise, seção 2.2 e T-05/T-09). Cadastro público aberto no CRM e no Margem Real; escopo por indústria aplicado só na tela da IO. Para reconstruir os sistemas sobre um Supabase único, a primeira coisa a existir é a identidade e o controle de acesso comuns.

## Solução

1. `usuarios` espelha `auth.users`; cadastro público desligado; usuário nasce por convite da Central DP.
2. Matriz sistema → módulo → ação por papel, com exceção individual (conceder/negar, com validade) e auditoria automática.
3. Pergunta única `hub_pode_executar(slug, modulo?, acao?)` usada pela RLS de toda tabela e pelo frontend.
4. SSO por código opaco de 60 s entre sistemas, com revalidação de acesso na troca.
5. Pacote de auth padrão para todo frontend (gate de sistema obrigatório).

Contrato completo: `supabase/docs/permissoes_e_login.md`.

## Banco

Migration `supabase/db/migrations/20261023_001_fundacao_identidade_acesso/`.

| Objeto | Tipo | Dono |
|---|---|---|
| `usuarios` | tabela | hub/usuarios |
| `systems`, `modulos`, `modulo_acoes` | tabelas | hub/sistemas |
| `papeis`, `papel_permissoes`, `usuario_papeis`, `usuario_permissao_excecoes` | tabelas | hub/permissoes |
| `auditoria_permissoes` | tabela | trigger; leitura hub/auditoria |
| `cross_system_session_codes` | tabela | service_role |
| `hub_pode_executar`, `hub_sistemas_permitidos`, `hub_minhas_permissoes`, `is_admin`, `hub_usuario_ativo`, `hub_usuario_interno` | funções | authenticated |
| `hub_pode_executar_usuario` | função | service_role |

Módulos criados: `hub/usuarios`, `hub/permissoes`, `hub/sistemas`, `hub/auditoria`. Papel criado: `admin`.

Edge Functions: `generate-cross-system-code`, `exchange-cross-system-code`, `admin-convidar-usuario`.

Frontend: `04-Sistemas/_template-sistema/src-auth/`.

## Semântica de permissão (decidida)

- `modulo NULL` / `acao NULL` na pergunta = "algum"; no grant = "todos".
- Ordem: inativo nega → admin libera → `negar` que cobre a pergunta nega → papel ou `conceder` vigente libera.
- `negar` estreito (ex.: só `deletar` em `clientes`) não tira o acesso ao sistema nem às outras ações.
- Módulo inexistente nega.

## Implementação (ordem)

1. ~~Criar projeto Supabase e preencher `.env` da raiz.~~ Feito (Postgres 17, vazio em 2026-10-23).
2. Aplicar `20261023_001` e `20261023_002` com `scripts/aplicar-migrations.sh --confirmar` (registra no histórico que o Skip lê).
3. Desligar cadastro público no painel (estava ligado em 2026-10-23).
4. Publicar as 3 Edge Functions.
5. Daniel troca a senha do seed e recebe o papel `admin` (README da migration).
6. Nas 4 bases Skip: regenerar `types.ts`, instalar `src-auth` com o slug (1=io, 2=books, 3=crm, 4=margem-real).
7. Construir a Central DP na 5ª base: cards (`hub_sistemas_permitidos`), usuários, papéis, matriz, exceções e auditoria.

## Critérios de aceite

- [x] 45 casos de `supabase/tests/permissoes.test.mjs` verdes (PGlite, 2026-10-23).
- [ ] Mesmos casos verificados no Supabase real com usuários de teste.
- [ ] `anon` não lê nenhuma tabela (teste de acesso anônimo como evidência, SEG-08).
- [ ] Tentativa de `signUp` pela API pública falha.
- [ ] Usuário convidado entra em 2 sistemas com a mesma senha.
- [ ] SSO: código usado duas vezes falha; código de outro destino falha; usuário sem acesso ao destino recebe 403.
- [ ] Usuário desativado perde acesso imediato em todos os sistemas.
- [ ] Usuário sem acesso ao sistema vê "Acesso negado" mesmo abrindo a URL direta.

## Rollback

Projeto novo e sem dados: rollback = recriar o projeto. Depois que houver dados, toda mudança nesta base exige migration de correção, nunca `DROP`.

## Realizado

- 2026-10-23: migrations 001/002, Edge Functions, pacote src-auth (typecheck strict OK), testes PGlite (45/45).
- 2026-10-23: bases Skip `Sistema-1..4` conferidas: já usam o Supabase do `.env`. Ajustes: carga de usuários pré-existentes em `001_usuarios.sql` (teste 46/46); `src-auth` refeito sobre o template Skip (client gerado, API do `use-auth` mantida, sem chamada ao Supabase dentro do `onAuthStateChange`), `tsc` e build OK dentro da base Sistema-1; `scripts/aplicar-migrations.sh` testado com PGlite.

## Pendências

- PD-01 (papéis iniciais) e PD-06 (domínio) em `supabase/docs/pending_decisions.md`.
- Edge Functions não testadas em runtime (sem Deno local); testar ao publicar.
