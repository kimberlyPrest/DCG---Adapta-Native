# Banco único com 4 projetos Skip

## Como está (conferido em 2026-10-23)

| Base Skip | Projeto Skip | Repo | Sistema | Pasta |
|---|---|---|---|---|
| Sistema 1 | 69061 | `Daniel-Diretoria/Sistema-1` | Inteligência Operacional (`io`) | `04-Sistemas/sistema-1-io` |
| Sistema 2 | 69056 | `Daniel-Diretoria/sistema-2` | Auditoria de Books (`books`) | `04-Sistemas/sistema-2-books` |
| Sistema 3 | 69058 | `Daniel-Diretoria/sistema-3` | CRM de Orçamento e Contratos (`crm`) | `04-Sistemas/sistema-3-crm` |
| Sistema 4 | 69057 | `Daniel-Diretoria/sistema-4` | Margem Real (`margem-real`) | `04-Sistemas/sistema-4-margem-real` |
| — (a criar) | — | — | Central DP (`hub`) | — |

- **O banco já é um só.** As 4 bases apontam para o projeto Supabase do `.env` da raiz (`pnpuyxjxkbxnlwnbopcd`), com a mesma chave publishable.
- Banco hoje: 0 tabelas em `public`; 1 usuário em `auth.users` (Daniel); 3 migrations no histórico, todas seeds do mesmo usuário, uma de cada base 2, 3 e 4.
- As bases são o template Skip (React + Vite + shadcn + Supabase Auth) só com tela de login. Nenhum código dos sistemas antigos foi portado ainda.
- Código a portar: `04-Sistemas/_legado-pocketbase/` (cópias dos repos PocketBase, com as 156 alterações pendentes da IO e as 6 do Books preservadas).

## O risco de 4 projetos Skip num banco

Cada projeto Skip tem sua pasta `supabase/migrations/` e aplica o que estiver lá **no mesmo banco**. Sem regra, os 4 criam tabelas sozinhos e o resultado é o mesmo problema da análise (cadastro duplicado), só que dentro de um banco. Já aconteceu em pequena escala: 3 bases criaram 3 migrations para o mesmo usuário.

## Regras

1. **Migration só nasce no repo central** (`supabase/db/migrations/`) e é aplicada por `scripts/aplicar-migrations.sh`. O script registra cada grupo em `supabase_migrations.schema_migrations`, o mesmo histórico que o Skip lê. O banco tem uma linha do tempo só.
2. **As bases Skip não criam migration.** Ao pedir algo para a IA do Skip, a instrução é: "o banco já existe, use as tabelas X e Y; não crie migration". Se o Skip gerar uma migration, ela não é publicada antes de virar migration central.
3. **Ninguém cria usuário por migration.** Usuário nasce por convite (`admin-convidar-usuario`) ou pelo painel do Supabase.
4. **`src/lib/supabase/types.ts` é gerado pelo Skip a partir do banco.** Depois de cada migration central aplicada, cada base precisa regenerar os tipos para enxergar as tabelas e funções novas.
5. **Auth:** as 4 bases usam o pacote `04-Sistemas/_template-sistema/src-auth/` (substitui o `use-auth.tsx` do Skip, sem `signUp`, com gate por `hub_pode_executar`).
6. **Variáveis:** `VITE_SUPABASE_URL` e `VITE_SUPABASE_PUBLISHABLE_KEY` iguais nas 4 bases. Nenhuma base recebe `service_role`.

## Pendências de segurança encontradas nas bases

| # | Achado | Ação |
|---|---|---|
| B-01 | Os 4 repos `Sistema-1..4` estão **públicos** no GitHub | Tornar privados |
| B-02 | As migrations de seed das bases 2, 3 e 4 têm a senha do Daniel no código (a da base 3 também em texto, no comentário) e já foram aplicadas no banco | Daniel troca a senha pelo "esqueci a senha"; remover os 3 arquivos dos repos quando as bases forem mexidas |
| B-03 | Cadastro público **ligado** no projeto (`disable_signup = false`): qualquer pessoa cria conta pela API | Painel Supabase > Authentication > Sign In / Providers > desligar "Allow new users to sign up" |
| B-04 | O hook `use-auth.tsx` do template expõe `signUp` | Substituir pelo pacote `src-auth` |

Nada foi alterado no Skip nem no banco. Esta página só registra o estado e as regras.
