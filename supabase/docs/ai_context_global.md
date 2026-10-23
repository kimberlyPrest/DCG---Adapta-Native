# Contexto global para IA — Banco DCG

Leia antes de alterar qualquer sistema DCG.

## Fonte de verdade

O banco Supabase único e a documentação central em `/supabase`. Os sistemas antigos em PocketBase (`../Plano — 3a0e27a1/05 - sistemas/`) servem para entender regras de negócio e telas, nunca como modelo de dados a copiar.

## Direções arquiteturais

- Um Supabase para os 5 sistemas. Nenhum sistema tem banco, auth ou tabela de usuário própria.
- Central DP (`hub`) governa usuários, permissões, catálogo de sistemas e a gestão de trabalho. Ocorrências deixam de ser sistema e viram tipo de item da Central DP (decisão D-01 do escopo).
- IO é dona dos cadastros de campo: redes, lojas, indústrias atendidas, produtos, colaboradores, aliases.
- CRM é dono do relacionamento comercial e pode criar indústria como `prospect`.
- Margem Real é dona dos CNPJs da DCG, plano de contas, contas bancárias e dados de pagamento de colaborador. É restrito: só papéis financeiros e diretoria.
- Books guarda o que é dele (books, fotos, classificações, imagem de referência e preço por produto) com FK para os mestres.
- Tabela de um sistema usa prefixo do domínio quando o nome for ambíguo (`books_fotos`, `mr_lancamentos`). Ver `naming_conventions.md`.
- Usuário de indústria (`usuarios.tipo = 'industria'`) só vê as indústrias de `usuario_industrias`. Isso é aplicado no banco (`pode_ver_industria`), não na tela.
- Regras que o cliente muda (SLA, responsáveis, áreas de direcionamento, política de validade, papéis) ficam em tabela de configuração editável pela UI, nunca em código ou prompt.
- Integração entre sistemas é pelo banco compartilhado (FK e views). Eventos para a Central DP (EV-IO, EV-BK, EV-CRM, EV-MR do escopo) usam uma tabela de outbox central, a ser desenhada na SPEC da Central DP.
- Segredos de integração (Trade Pro, WhatsApp, IA) só no cofre de segredos do Supabase. Nunca em coluna de tabela.
- Homologação em projeto Supabase separado (branch ou projeto). Nada de campo `ambiente` misturando teste e produção (achado T-24).

## Lições do Lucenera já incorporadas

| Lá | Aqui |
|---|---|
| `hub_pode_executar` errava com `acao NULL` (SPEC-085 de lá) | Semântica de NULL definida e testada desde o início |
| Satélites só checavam sessão; qualquer login abria qualquer sistema (SPEC-063) | Gate `hub_pode_executar(slug)` obrigatório no pacote de auth |
| RLS `USING (true)` corrigida meses depois (SPEC-069) | Proibido desde a primeira tabela |
| `usuarios.role` legado convivendo com `papeis` | Só `papeis` |
| Coluna `valido_até` com acento | `valido_ate` |
| Ações fixas no CHECK; `aprovar` veio depois | Ações livres, validadas por formato |

## Pendências globais

Ver `pending_decisions.md`.
