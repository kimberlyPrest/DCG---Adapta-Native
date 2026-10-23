# Ecossistema DCG em uma página

Autocontido para quem abre este sistema sem o repositório central.

## Sistemas (um Supabase para todos)

| Slug | Sistema | Dono de |
|---|---|---|
| `hub` | Central DP | usuários, papéis, permissões, catálogo de sistemas, itens de trabalho e ocorrências |
| `io` | Inteligência Operacional | redes, lojas, indústrias atendidas, produtos, colaboradores; validades, rupturas, visitas, devoluções |
| `books` | Auditoria de Books | books, fotos, classificações, notas, ranking |
| `crm` | CRM de Orçamento e Contratos | prospects, propostas, contratos, regras operacionais, capacidade |
| `margem-real` | Margem Real | CNPJs DCG, plano de contas, lançamentos, contas, rateio, fechamento |

## Login e permissão

- Mesmo login em todos (`auth.users` + `public.usuarios`). Sem tela de cadastro: usuário nasce na Central DP.
- Permissão = sistema → módulo → ação, por papel, com exceção individual. Pergunta única: `hub_pode_executar(slug, modulo, acao)`.
- `hub_minhas_permissoes(slug)` devolve o que o usuário pode fazer neste sistema; a UI esconde o resto.
- Usuário de indústria só vê as próprias indústrias (`pode_ver_industria`).
- A proteção real é a RLS no banco. A tela só acompanha.
- Abrir outro sistema logado: `abrirSistema(slug, url)` (SSO por código de 60 s).

## Cadastros compartilhados

`redes`, `lojas`, `industrias`, `produtos`, `colaboradores`, `empresas_dcg`, `cadastro_aliases`. Este sistema referencia por FK. Dado que só este sistema usa fica em tabela própria com FK para o mestre.

## Proibido

Tabela de usuário própria, cópia de cadastro mestre, permissão hardcoded, senha/token/dado real em código ou migration, `USING (true)` em escrita.
