# Contrato de login, permissão e SSO

Todo sistema DCG segue este contrato. Ele vale para frontend, RLS e Edge Functions.

## 1. Login

- Um projeto Supabase, um `auth.users`. O mesmo e-mail e senha entram em qualquer sistema.
- `public.usuarios` (id = `auth.users.id`) guarda nome, `tipo` (`interno` | `industria`) e `ativo`.
- Cadastro público desligado. Usuário nasce pela Central DP (`admin-convidar-usuario`), recebe convite por e-mail e define a senha.
- Desativar = `usuarios.ativo = false`. O usuário perde acesso a tudo na hora, porque toda checagem passa por `hub_pode_executar`, que nega para inativo.

## 2. Matriz

```text
systems (slug)  ->  modulos (chave)  ->  modulo_acoes (chave)
papeis  ->  papel_permissoes (system, modulo|NULL, acao|NULL)
usuarios  ->  usuario_papeis  (soma de papéis)
usuarios  ->  usuario_permissao_excecoes (conceder|negar, com validade)
```

- `modulo_id NULL` = todos os módulos; `acao NULL` = todas as ações.
- Papel `admin` = acesso total implícito.
- Ações são texto livre validado por formato. Padrão: `visualizar`, `criar`, `editar`, `deletar`; outras (`aprovar`, `exportar`, `fechar_mes`) quando o módulo precisar.
- Precedência: inativo → nega; admin → libera; `negar` que cobre a pergunta → nega; papel ou `conceder` vigente → libera.

## 3. Funções

| Função | Para quê |
|---|---|
| `hub_pode_executar(slug, modulo?, acao?)` | Pergunta única. `('crm')` = pode abrir o CRM? `('crm','contratos','aprovar')` = pode aprovar contrato? |
| `hub_sistemas_permitidos()` | Cards da Central DP e menu "trocar de sistema". |
| `hub_minhas_permissoes(slug)` | Lista `(modulo, acao)` do usuário no sistema. O front carrega uma vez e esconde abas e botões. |
| `pode_ver_industria(industria_id)` | Escopo de usuário de indústria em todo `SELECT` com `industria_id`. |
| `hub_usuario_ativo()` / `hub_usuario_interno()` / `is_admin()` | Atalhos para RLS. |
| `hub_pode_executar_usuario(usuario, ...)` | Só `service_role` (Edge Functions). |

Testadas em `supabase/tests/permissoes.test.mjs`.

## 4. RLS (padrão obrigatório)

```sql
ALTER TABLE public.contratos ENABLE ROW LEVEL SECURITY;

CREATE POLICY contratos_select ON public.contratos FOR SELECT TO authenticated
  USING (public.pode_ver_industria(industria_id)
         AND (SELECT public.hub_pode_executar('crm', 'contratos', 'visualizar')));
CREATE POLICY contratos_insert ON public.contratos FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.hub_pode_executar('crm', 'contratos', 'criar')));
CREATE POLICY contratos_update ON public.contratos FOR UPDATE TO authenticated
  USING ((SELECT public.hub_pode_executar('crm', 'contratos', 'editar')))
  WITH CHECK ((SELECT public.hub_pode_executar('crm', 'contratos', 'editar')));
CREATE POLICY contratos_delete ON public.contratos FOR DELETE TO authenticated
  USING ((SELECT public.hub_pode_executar('crm', 'contratos', 'deletar')));

REVOKE ALL ON TABLE public.contratos FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.contratos TO authenticated;
```

O `(SELECT ...)` em volta faz o Postgres avaliar a função uma vez por consulta, não uma vez por linha.

## 5. Frontend (todo sistema)

Pacote pronto em `04-Sistemas/_template-sistema/src-auth/`:

1. Ao abrir com `?sso_code=`, chama `exchange-cross-system-code` e faz `setSession` antes de mostrar login.
2. Com sessão, chama `hub_pode_executar(SLUG)`. `false` → tela "Acesso negado" (lição da SPEC-063 do Lucenera: lá os satélites só checavam se havia sessão, e qualquer login abria qualquer sistema).
3. Carrega `hub_minhas_permissoes(SLUG)` e expõe `pode(modulo, acao)` para a UI.
4. Link para outro sistema: `generate-cross-system-code` e abrir `url?sso_code=...`.

Esconder botão é conforto. A proteção é a RLS.

## 6. SSO

```text
Sistema A ── POST generate-cross-system-code {sistema_origem, sistema_destino, redirect_to}
          <── {code, expira_em}                 (só se pode abrir o destino)
          ── abre https://destino/?sso_code=<code>
Sistema B ── POST exchange-cross-system-code {code, sistema_destino}
          <── {access_token, refresh_token, redirect_to}   (uso único, 60 s, revalida acesso)
          ── supabase.auth.setSession(...) e navega para redirect_to
```

Quando todos os sistemas estiverem no mesmo domínio-pai, dá para trocar o SSO por cookie compartilhado. Até lá, este fluxo é o padrão.
