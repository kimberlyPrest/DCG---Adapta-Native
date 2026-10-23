# Instrucao Geral para IA e Desenvolvedor

Este arquivo define o fluxo padrao para qualquer pessoa ou agente que trabalhe no ecossistema DCG.

## Objetivo

Manter a mesma memoria entre cliente, desenvolvedor, IA, repositorios dos sistemas e repositorio central.

O repositorio central `DCG - Adapta Native` guarda o contexto do ecossistema. Cada sistema (Central DP, IO, Books, CRM, Margem Real) tem seu repositorio proprio para codigo e deploy, carregado como submodule em `04-Sistemas/`.

## Principios do ecossistema

1. **Um Supabase so.** Todos os sistemas apontam para o mesmo projeto. Nenhum sistema cria banco proprio.
2. **Um login so.** `auth.users` + `public.usuarios`. Cadastro publico desligado; usuario so nasce pela Central DP (admin).
3. **Uma matriz de permissoes so.** Sistema -> modulo -> acao, por papel, com excecao individual. Contrato: `hub_pode_executar(slug, modulo, acao)`.
4. **Cadastros mestres compartilhados.** Loja, rede, industria, produto, colaborador e empresa DCG existem uma vez. Cada tabela tem um sistema dono (quem escreve); os outros leem.
5. **Permissao no banco, nao so na tela.** Toda tabela tem RLS que chama `hub_pode_executar`. Esconder botao no front e complemento, nunca a protecao.

## Skip

Os sistemas sao projetos Skip (Sistema 1 a 4) que compartilham o Supabase do `.env`. Ler `00-Contexto/BANCO_UNICO_SKIP.md` antes de pedir qualquer coisa a IA do Skip: base Skip nao cria migration nem usuario; migration so pelo repo central (`scripts/aplicar-migrations.sh`).

## Arquivo .env local

Criado manualmente na raiz do repositorio central a partir de `.env.example`. Nunca commitar, nunca imprimir valores em logs, commits, PRs ou respostas.

## Antes de alterar qualquer coisa

1. Leia `README.md`.
2. Leia `00-Contexto/FLUXO_DE_TRABALHO.md`.
3. Leia `04-Sistemas/00 - Sumario Sistemas.md`.
4. Identifique quais sistemas serao afetados.
5. Leia a SPEC relacionada em `03-Projeto/SPECs/`.
6. Se nao existir SPEC, crie uma antes de implementar usando `03-Projeto/SPECs/_TEMPLATE_SPEC.md` e siga `00-Contexto/COMO_CRIAR_SPEC.md`.

## Antes de alterar banco

1. Leia `supabase/README.md`.
2. Leia `supabase/docs/ai_context_global.md`.
3. Leia `supabase/docs/permissoes_e_login.md`.
4. Leia `supabase/docs/relationships.md`.
5. Leia o dominio afetado em `supabase/db/domains/`.
6. Consulte `supabase/db/current/` para nomes reais de objetos (depois da primeira aplicacao).
7. Crie a alteracao em `supabase/db/migrations/YYYYMMDD_NNN_nome_do_grupo/`.
8. Atualize o `AI_DB_CONTEXT.md` do sistema afetado.

Nunca invente tabela, coluna, funcao ou policy sem verificar o snapshot central.

## Regras obrigatorias para toda tabela nova

- `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` na mesma migration que cria a tabela.
- Policies por acao (`select`, `insert`, `update`, `delete`) chamando `hub_pode_executar`. Proibido `USING (true)` para `authenticated` em escrita.
- Tabela de sistema usa o slug do sistema dono; tabela compartilhada documenta o dono em `supabase/docs/relationships.md`.
- Dado com escopo de industria usa `pode_ver_industria(industria_id)` no `select`.
- Nada de senha, token, CPF, PIX, extrato ou dado real em migration. Dado real entra por importacao dentro do sistema, com trilha.

## Regras obrigatorias para todo sistema (frontend)

- Usar o pacote de auth de `04-Sistemas/_template-sistema/src-auth/`: troca de `sso_code`, `hasAccess` via `hub_pode_executar(slug)` e bloqueio de rota com tela "Acesso negado".
- Login so pela tela padrao; sem tela de cadastro.
- Botoes e abas condicionados a `hub_minhas_permissoes(slug)`.

## Fluxo de implementacao

1. Atualize ou crie a SPEC no repo central.
2. Implemente no repositorio proprio do sistema afetado.
3. Rode as verificacoes do sistema.
4. Atualize o contexto local do sistema, se a mudanca alterar banco, regras ou fluxo.
5. Atualize `CHANGELOG.md` no repo central.
6. Commit e push no repositorio do sistema.
7. Atualize o ponteiro do submodule no repo central.
8. Commit no repositorio central.

## Quando a mudanca envolver varios sistemas

Criar uma SPEC unica no repo central com sistemas afetados, tabelas/funcoes/policies envolvidas, ordem de implementacao, criterio de aceite por sistema, plano de rollback e documentos a atualizar.

## Nao fazer

- Nao criar banco, auth ou tabela de usuarios propria dentro de um sistema.
- Nao duplicar cadastro mestre (loja, rede, industria, produto, colaborador) dentro de um sistema.
- Nao criar permissao hardcoded (`if email === ...`, `role === 'admin'` no front) — usar a matriz.
- Nao usar migration como script operacional (reset de senha, limpeza, correcao de dado).
- Nao atualizar ponteiro de submodule para commit que ainda nao foi enviado ao GitHub.
- Nao commitar `.env` ou qualquer segredo.
