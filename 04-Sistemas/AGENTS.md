# Instrucao da Pasta 04-Sistemas

Cada subpasta e o repositorio proprio de um sistema (submodule). O codigo e commitado no repo do sistema; o repo central guarda so o ponteiro.

## Antes de mexer em um sistema

1. Ler `00 - Sumario Sistemas.md`.
2. Ler `<sistema>/supabase/README.md` e `AI_DB_CONTEXT.md` (quando existirem).
3. Ler `../supabase/docs/permissoes_e_login.md`.

## Regras

- Banco, login e permissao vem do Supabase central. Nada de PocketBase novo, tabela de usuario propria ou cadastro de loja/industria/produto/promotor proprio.
- Todo sistema usa `_template-sistema/src-auth/` com o seu slug.
- Nao commitar `.env`, senha, token ou dado real. As copias atuais herdam esses problemas: sanear antes de qualquer push.
- `_template-sistema/` nao e sistema: e o modelo de pacote local.
- `sistema-N-*` sao as bases Skip. Nao criar `supabase/migrations/` novas nelas: ver `../00-Contexto/BANCO_UNICO_SKIP.md`.
- `_legado-pocketbase/` e so leitura: codigo antigo para portar, nunca para publicar.
