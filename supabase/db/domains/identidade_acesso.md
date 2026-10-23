# Domínio: Identidade e acesso (Central DP)

## Papel

Camada de controle do ecossistema: quem é o usuário, que sistemas abre, o que pode fazer em cada módulo, com trilha de quem mudou o quê.

## Objetos

Ver SPEC-001 e `supabase/docs/permissoes_e_login.md`. Tabelas: `usuarios`, `systems`, `modulos`, `modulo_acoes`, `papeis`, `papel_permissoes`, `usuario_papeis`, `usuario_permissao_excecoes`, `auditoria_permissoes`, `cross_system_session_codes`, `usuario_industrias`.

## Regras

- Sem cadastro público. Convite pela Central DP (`admin-convidar-usuario`).
- Desativar usuário (`ativo = false`) bloqueia tudo na hora.
- Papéis e atribuições mudam pela UI, nunca por migration.
- Sistemas consomem por RPC (`hub_*`), não lendo a matriz direto.
- Todo módulo novo é registrado em `modulos`/`modulo_acoes` na migration que cria suas tabelas.

## Perfis atuais nos sistemas antigos (insumo para PD-01)

| Sistema | Perfis |
|---|---|
| IO | `admin` + demais, `allowed_industries`, `custom_permissions` |
| Books | `administrator`, `gestor`, `analista_books`, `supervisor` |
| Ocorrências | `admin`, `supervisao`, `promotor` |
| CRM | `admin`, `supervisao`, qualquer logado |
| Margem Real | `dono`, `equipe` |
