# Migration 20261023_001 - SPEC-001 (Fundação: identidade, permissões e SSO)

## Contexto

Ver `03-Projeto/SPECs/SPEC-001_Fundacao_Login_Permissoes_SSO.md`.

## Arquivos

| Arquivo | Função |
|---|---|
| `001_usuarios.sql` | `usuarios` (espelho de `auth.users`), triggers de criação e troca de e-mail, `set_atualizado_em()`, e carga dos usuários que já existiam (Daniel). |
| `002_sistemas_permissoes.sql` | `systems`, `modulos`, `modulo_acoes`, `papeis`, `papel_permissoes`, `usuario_papeis`, `usuario_permissao_excecoes`, `auditoria_permissoes`. |
| `003_funcoes_permissao.sql` | `hub_pode_executar`, `hub_pode_executar_usuario` (service_role), `is_admin`, `hub_usuario_ativo`, `hub_usuario_interno`, `hub_sistemas_permitidos`, `hub_minhas_permissoes`. |
| `004_auditoria.sql` | Trilha automática em usuários, sistemas, papéis, permissões, atribuições e exceções. |
| `005_rls.sql` | RLS de todas as tabelas acima, regida pelos módulos `usuarios`, `permissoes`, `sistemas` e `auditoria` da Central DP. |
| `006_sso_cross_system.sql` | `cross_system_session_codes` (só service_role). |
| `007_seed_estrutura.sql` | 5 sistemas, módulos/ações da Central DP, papel `admin`. Sem pessoas, sem senhas. |

## Estado

Escrita em 2026-10-23. **Ainda não aplicada.** O projeto Supabase existe e está vazio; a aplicação aguarda o OK do responsável.

## Aplicar

Com o `.env` da raiz preenchido:

```bash
scripts/aplicar-migrations.sh              # simulação: lista pendentes
scripts/aplicar-migrations.sh --confirmar  # aplica cada grupo numa transação e registra no histórico do Supabase/Skip
```

Depois publicar as Edge Functions (`supabase/functions/README.md`) e desligar o cadastro público no painel: **Auth > Sign In / Providers > Allow new users to sign up = desligado** (em 2026-10-23 estava ligado).

## Primeiro admin (procedimento operacional, fora de migration)

O Daniel já existe em `auth.users` (seed das bases Skip) e `001_usuarios.sql` o traz para `usuarios`. Basta:

1. Daniel troca a senha (a do seed está publicada nos repos das bases).
2. SQL Editor:

```sql
INSERT INTO public.usuario_papeis (usuario_id, papel_id)
SELECT u.id, p.id
FROM public.usuarios u, public.papeis p
WHERE u.email = lower('daniel@diretoriapromocoes.com.br') AND p.chave = 'admin';
```

3. Registrar no `CHANGELOG.md` quem foi feito admin e quando. A partir daí, todo usuário nasce pela Central DP.

## Verificação pós-aplicação

```sql
-- 1. Anônimo não lê nada
SET ROLE anon; SELECT count(*) FROM public.usuarios; RESET ROLE;            -- erro de permissão

-- 2. Seed
SELECT slug, visivel_no_hub FROM public.systems ORDER BY ordem;            -- 5 linhas, hub invisível
SELECT count(*) FROM public.modulo_acoes;                                  -- 10

-- 3. Semântica (como o admin, via app ou request.jwt.claims)
SELECT public.hub_pode_executar('crm');                                    -- true para admin
SELECT public.hub_pode_executar('crm', 'modulo_inexistente', 'criar');     -- false
SELECT * FROM public.hub_sistemas_permitidos();                            -- 4 sistemas
```

Casos que a SPEC-001 exige testar com um usuário não admin estão na seção "Critérios de aceite" da SPEC.
