# Edge Functions centrais

| Função | JWT | Quem chama | Faz |
|---|---|---|---|
| `generate-cross-system-code` | sim | Sistema de origem (botão "abrir X") | Confere `hub_pode_executar(destino)` e gera código de 60 s, uso único |
| `exchange-cross-system-code` | não | Sistema de destino, ao abrir com `?sso_code=` | Consome o código, revalida acesso e devolve sessão |
| `admin-convidar-usuario` | sim | Central DP, tela de usuários | Exige `hub/usuarios/criar`; envia convite; o trigger cria `usuarios` |

`_shared/cors.ts`: CORS, resposta JSON, sanitização de `redirect_to`, leitura de env.

## Publicar

```bash
supabase link --project-ref <ref>
supabase functions deploy generate-cross-system-code
supabase functions deploy exchange-cross-system-code --no-verify-jwt
supabase functions deploy admin-convidar-usuario
```

Variáveis `SUPABASE_URL`, `SUPABASE_ANON_KEY` e `SUPABASE_SERVICE_ROLE_KEY` são injetadas pelo Supabase. Não criar outras com o mesmo valor.

## Regra

Função nova que usa `service_role` precisa checar a permissão do chamador (`hub_pode_executar` com o client do usuário) antes de qualquer escrita. Erro detalhado vai para `console.error`; o corpo da resposta leva só mensagem amigável.
