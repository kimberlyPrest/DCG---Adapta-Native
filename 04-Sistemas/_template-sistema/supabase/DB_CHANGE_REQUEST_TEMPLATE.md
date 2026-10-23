# Pedido de mudança de banco

Use quando o schema atual não atende. Não crie a tabela/coluna no código: preencha e leve para uma SPEC no repositório central.

- **Sistema:** `<slug>`
- **Data / autor:**
- **Problema:** o que o usuário não consegue fazer hoje.
- **Mudança proposta:** tabela/coluna/função/policy, com tipos.
- **Dono da escrita:** módulo e ação (`hub_pode_executar('<slug>', '<modulo>', '<acao>')`).
- **Quem lê:** sistemas e perfis; precisa de escopo por indústria?
- **Já existe algo parecido?** conferir `supabase/docs/table_index.md`.
- **Afeta outro sistema?** quais.
- **Dado sensível?** CPF, PIX, salário, extrato → justificar e restringir.
- **Como testar:** casos para `supabase/tests/permissoes.test.mjs`.
