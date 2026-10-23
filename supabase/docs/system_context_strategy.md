# Estratégia de contexto por sistema

Igual ao Lucenera: três camadas.

1. Fonte central em `/supabase` (este repositório).
2. Pacote local autocontido em `<sistema>/supabase/`, copiado de `04-Sistemas/_template-sistema/supabase/` e preenchido.
3. Nenhuma migration dentro do sistema. Alteração de banco nasce aqui.

## Pacote local

```text
<sistema>/supabase/
  README.md                       Diz que o banco é central e a ordem de leitura.
  ECOSSISTEMA_DCG.md              Contexto mínimo para quem abre o sistema isolado.
  AI_DB_CONTEXT.md                Recorte real: tabelas que o sistema lê/escreve, módulos e ações.
  DB_CHANGE_REQUEST_TEMPLATE.md   Como pedir mudança de banco sem inventar tabela.
<sistema>/src/auth/               Pacote de auth (src-auth do template).
```

## Ordem de leitura da IA dentro de um sistema

1. `<sistema>/supabase/README.md`
2. `<sistema>/supabase/AI_DB_CONTEXT.md`
3. `/supabase/docs/ai_context_global.md`
4. `/supabase/docs/permissoes_e_login.md`
5. `/supabase/docs/relationships.md`, se tocar em mestre ou em outro sistema
6. `/supabase/db/current/`, só para nomes exatos

Quando faltar estrutura, a IA preenche `DB_CHANGE_REQUEST_TEMPLATE.md`. Não inventa tabela, coluna ou função no código.
