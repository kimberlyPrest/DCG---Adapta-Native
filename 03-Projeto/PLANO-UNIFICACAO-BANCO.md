# Plano de implementação — 4 bancos PocketBase → 1 Supabase

- **Data:** 2026-10-23
- **Escopo:** bancos de produção da Inteligência Operacional (Skip 50244), Auditoria de Books (50046), CRM (50497) e Margem Real (59928) → Supabase único do `.env` (`pnpuyxjxkbxnlwnbopcd`), consumido pelas bases Skip Sistema 1–4 e pela futura Central DP.
- **Base:** `schema.json` dos repositórios legados, leitura das coleções, hooks e migrations **em produção** no Skip (somente leitura), e as SPEC-001/002 já escritas.
- **Anexo:** [mapa coleção → destino](PLANO-UNIFICACAO-BANCO_anexo-mapa.md) (135 coleções, nenhuma sem destino).

---

## 1. Diagnóstico

### 1.1 Tamanho

| Sistema | Coleções em produção | No git | Hooks em produção | No git | Crons conhecidos |
|---|---|---|---|---|---|
| Inteligência Operacional | 51 | 51 ² | 21 | 21 ² | 3 (a cada 5 min: agendador Trade Pro, promotores, fotos) |
| Auditoria de Books | 14 | 14 | 5 | 5 | — |
| CRM | **53** | 41 | **42** | 30 | 2+ (SLA 20 min, cobrança 30 min) |
| Margem Real | **17** | 12 | **25** | 1 | a levantar (alertas, Open Finance) |
| **Total** | **135** | 118 | **93** | 57 | |

² iguais só porque as 156 alterações da IO que estão em staging (nunca commitadas) já estão em produção.

### 1.2 Achados que mudam o plano

**A. A produção está à frente do git.** O CRM tem 12 coleções e 12 hooks que não existem no repositório: RH, gamificação, ponto por QR, trocas, IA Thèo, versões de orçamento, onboarding/implantação. A Margem Real tem 5 coleções e 24 hooks a mais: pagamentos, Open Finance, faturamento mensal, documentos, alertas, folha. **A fonte para a migração é o projeto Skip em produção, não o GitHub.** A análise de 15/10 também está parcialmente desatualizada: várias coleções públicas já foram fechadas em produção (ex.: `homologacao_modelos_operacao`; o cadastro público do CRM e da Margem Real já foi desligado).

**B. Os sistemas já trocam dados entre si, e casam pessoas pelo nome.** A Margem Real é a fonte do "acordado" de cada promotor (salário + bonificação, decisão do Daniel em 14/10). O CRM puxa esses valores por HTTP, com login de um usuário de serviço (secrets `MR_*`), e casa promotor "por contenção de nome". No sentido inverso, a Margem Real consulta KPIs da gamificação do CRM do mesmo jeito (`CRM_*`). Com banco único, essas duas pontes viram uma FK e uma view. É o ganho mais concreto da unificação.

**C. A mesma pessoa existe em até 6 formas.** IO (`promoters`, `supervisors`), Books (`promoters`), CRM (`promotores` com `participant_jid` do WhatsApp, `capacidade_operacional`, `gamificacao` com chave no JID), Margem Real (`promotores` com salário/PIX). Hoje elas são ligadas por nome, código Trade Pro ou JID, conforme o sistema.

**D. Sobreposições que a análise de 15/10 não tinha:**

| Mesmo conceito | Onde | Decisão |
|---|---|---|
| CNPJ da DCG | `cnpjs` (MR) e `entidades_juridicas` (CRM) | D-U1 |
| Contrato com cliente | `contratos` (MR, valor mensal) e `contracts` (CRM) | D-U2 |
| Troca/devolução de produto | `trocas` (CRM, via WhatsApp) e `devolucoes_*` (IO) | D-U3 |
| Visita planejada/realizada | `visit_schedules` (Books), `alocacoes_operacao` (CRM), `operacional_visitas` (IO) | D-U4 |
| Sortimento/mix por loja | `assortment_matrix` (Books) e `industry_store_product_mix` (IO) | D-U5 |

**E. Quatro modelos de usuário e permissão.**

| Sistema | Modelo atual | Vira |
|---|---|---|
| IO | `role` (admin, gestao, operacao, supervisao, desenvolvedor, industria) + `allowed_industries` + `custom_permissions` | papéis + `usuario_industrias` + exceções |
| Books | `role` (administrator, gestor, analista_books, supervisor) | papéis |
| CRM | `role` (admin, supervisao, promotor) + `modulo` (comercial, trade, books, rh, repositor, mei) | papéis por combinação role × módulo |
| Margem Real | `papel` (dono, equipe) + `permissoes` (json) | papéis + exceções |

O mesmo e-mail pode existir nos 4 bancos com senhas diferentes. Na unificação ele vira **um** usuário com a soma dos papéis.

**F. Dados que não são de produção.** O CRM tem 20 coleções com campo `ambiente` (`producao` | `demonstracao`) e há migrations de piloto/demonstração no Books. Só `ambiente = producao` migra (achado T-24).

**G. Texto no lugar de chave.** Boa parte das tabelas guarda o nome em vez do id (`store_name`, `promotor_nome`, `industria_nome`, `loja_nome`). A carga precisa resolver cada nome contra o cadastro mestre (com `cadastro_aliases`); o que não resolver vira pendência cadastral, não registro novo.

**H. Arquivos.** Há campos de arquivo em 20 coleções, sem contar avatar: fotos de produto e de book, evidências de devolução, NFs, contratos, propostas, mídia de WhatsApp, documentos financeiros. Eles migram do storage do PocketBase para buckets do Supabase Storage, com policies por módulo. O volume ainda não foi medido.

**I. Dados sensíveis abertos a "qualquer logado".** Na Margem Real: `pagamentos`, `documentos` (folha, guias, extratos), `promotores` (salário, PIX, banco) e `of_conexoes`. No CRM: `rh_registros` (faltas/atestados) e `gamificacao.pendencias_desconto`. No banco único, essas tabelas só abrem para os papéis financeiro, RH e admin.

**J. Ainda existem em produção:** `tmp_debug.js`, `tmp_debug_envio.js`, `whatsapp_debug_peek.js` e `limpar_testes.js` no CRM (achado T-04), e várias migrations de reset de senha nos dois sistemas. Nada disso é portado.

---

## 2. Princípios da unificação

1. **Um schema `public`, prefixo por domínio** (`io_`, `books_`, `crm_`, `mr_`, `dp_`, `wa_`, `trade_`, `rh_`). É o schema que o Skip lê para gerar `types.ts` e o que a API do Supabase expõe.
2. **Cadastro mestre primeiro.** Nenhuma tabela de domínio é carregada antes dos mestres (SPEC-002) estarem carregados e deduplicados. Toda FK de pessoa, loja, indústria ou produto aponta para o mestre.
3. **Dono por tabela.** Quem escreve é definido pela matriz (`hub_pode_executar`); os outros sistemas leem. Exemplos: o acordado do promotor é escrito pela Margem Real e lido pelo CRM; o cadastro de loja é escrito pela IO e lido por todos.
4. **Sem pontes HTTP entre sistemas.** O que hoje é login de serviço + chamada REST vira view ou função SQL.
5. **Migração repetível.** O ETL roda quantas vezes for preciso (em homologação e na virada), é idempotente e guarda o de-para de ids.
6. **Nada sensível em migration.** Dado real entra pelo ETL, a partir de exportação controlada, nunca versionado no git.
7. **Migration só pelo repo central** (`scripts/aplicar-migrations.sh`). As bases Skip não criam tabela.

---

## 3. Modelo alvo (resumo)

| Bloco | Tabelas principais | Dono | Origem |
|---|---|---|---|
| Identidade e acesso | `usuarios`, `papeis`, `papel_permissoes`, `usuario_papeis`, `usuario_industrias`… | hub | 4 × `users` |
| Cadastros mestres | `empresas_dcg`, `redes`, `lojas`, `industrias`, `produtos`, `colaboradores`, `cadastro_aliases` | io (mr: empresas) | 24 coleções (IO 9, Books 4, CRM 7, MR 4) |
| IO | `io_validades`, `io_rupturas`, `io_devolucoes`, `io_visitas`, `io_mix_loja`, `io_sync_execucoes`… | io | 38 da IO + 3 em decisão (D-U3/4/5) |
| Books | `books`, `books_fotos`, `books_classificacoes`, `books_regras`, `books_precos`, `books_marcas`, `books_produto_referencia` | books | 5 + extensões de 2 mestres |
| CRM | `crm_clientes`, `crm_oportunidades`, `crm_propostas`, `crm_contratos`, `crm_regras_operacionais`, `crm_tabela_comercial`, `crm_capacidade`, `crm_alocacoes`… | crm | 23 (+1 do MR em decisão, D-U2) |
| Margem Real | `mr_lancamentos`, `mr_contas_*`, `mr_plano_contas`, `mr_fechamentos`, `mr_faturamento`, `mr_pagamentos`, `mr_contratacao`, `mr_documentos`… | margem-real | 11 + extensões de 2 mestres |
| Central DP | `dp_ocorrencias`, `dp_tratativas`, `dp_representantes`, `dp_lembretes`, `dp_regras_direcionamento`, `dp_ia_exemplos`, `dp_ocorrencia_mensagens` | hub | 7 do CRM + base do sistema de Ocorrências |
| WhatsApp | `wa_instancias`, `wa_conversas`, `wa_mensagens`, `wa_grupos`, `wa_bot_sessoes`, `wa_bot_conhecimento` | hub (D-02) | 6 do CRM |
| Trade / RH | `trade_gamificacao`, `trade_conquistas`, `trade_metricas_pdv`, `trade_acompanhamentos`, `rh_registros`, `rh_ponto` | D-U6 | 6 do CRM |
| Migração | `migracao.id_map`, `migracao.pendencias`, `migracao.legado_*` | service_role | — |

Campos que o mestre ganha em relação à SPEC-002, a partir de produção: `colaboradores.whatsapp_jid`, `colaboradores.regiao`; `industrias.tradepro_client_id`, `industrias.segmento`; `produtos.codigo_barras`, `produtos.familia`, `produtos.shelf_life_dias`, `produtos.foto_path`; `lojas.codigo_rede`, `lojas.bairro`, `lojas.cep`, `lojas.regiao`. Entram numa migration `003_mestres_ajustes` antes das tabelas de domínio.

---

## 4. Fases

| Fase | Entrega | Depende de | Porte |
|---|---|---|---|
| **U0** Congelar a verdade | Snapshot de produção: esquema, hooks e dados dos 4 | acesso admin ao PocketBase | P |
| **U1** Fundação | SPEC-001/002 aplicadas + ajustes de mestres | U0 (esquema) | P |
| **U2** Esquema por domínio | Migrations 004–009 + RLS + testes | U1, decisões D-U* | G |
| **U3** ETL | Pipeline idempotente de carga, com relatório de reconciliação | U2 | G |
| **U4** Backend | Hooks → Edge Functions / SQL / `pg_cron` | U2 | G |
| **U5** Ensaio | Carga completa em homologação + conferência com os donos | U3, U4 | M |
| **U6** Virada por sistema | Congela legado → carga delta → troca → legado só leitura 60 dias | U5 + telas portadas | M por sistema |

O frontend (portar as telas para as bases Skip) corre em paralelo a partir da U2, sistema por sistema, e é o que define a data de cada virada na U6.

### U0 — Congelar a verdade

1. **Código:** exportar os arquivos de cada projeto Skip em produção (hooks, migrations, `schema.json`, `src/`) para `04-Sistemas/_legado-pocketbase/<sistema>/` e commitar como "snapshot de produção AAAA-MM-DD". Feito isso, o git volta a refletir a produção.
2. **Esquema:** gerar `schema.json` de produção dos 4 (via admin API) e rodar de novo o mapa do anexo. Qualquer coleção nova precisa de destino antes de seguir.
3. **Dados:** exportação completa de cada PocketBase (backup do SQLite + `pb_data/storage`) feita pelo admin do Skip, guardada **fora do git e do Drive compartilhado** (há CPF, PIX e extratos).
4. **Volumes:** contagem de registros por coleção e tamanho do storage, para dimensionar o ETL e o plano do Supabase.
5. **Higiene imediata:** remover em produção `tmp_debug*`, `whatsapp_debug_peek`, `limpar_testes` (CRM); trocar as credenciais de serviço `CRM_*`/`MR_*` por usuários sem privilégio administrativo até a unificação.

**Pronto quando:** snapshot commitado, backup íntegro restaurado num PocketBase local e contagens registradas no anexo.

### U1 — Fundação

1. Aplicar `20261023_001` e `20261023_002` (`scripts/aplicar-migrations.sh --confirmar`).
2. Migration `20261024_003_mestres_ajustes`: campos de produção no mestre (seção 3) e schema `migracao` (`id_map(sistema, colecao, pb_id, tabela, uuid)`, `pendencias`).
3. Registrar módulos e ações de cada sistema na matriz, a partir das telas de produção (ex.: CRM: comercial, trade, rh, books, ocorrências).
4. Criar os papéis de transição que reproduzem o acesso atual (D-U7): `io_admin`, `io_gestao`, `io_operacao`, `io_supervisao`, `io_industria`, `books_admin`, `books_gestor`, `books_analista`, `books_supervisor`, `crm_admin`, `crm_comercial`, `crm_trade`, `crm_rh`, `crm_books`, `crm_repositor`, `crm_mei`, `mr_dono`, `mr_equipe`. Depois da virada, a Central DP os consolida.

### U2 — Esquema por domínio

Uma migration por domínio, cada uma com tabelas, índices, RLS, módulos/ações e casos novos em `supabase/tests/`:

| Migration | Conteúdo | Destaques |
|---|---|---|
| `004_io` | 38 coleções → ~30 tabelas `io_*` | `io_sync_execucoes` unifica 4 coleções de jobs; ajustes de validade unificados; `dados_brutos_json` vira `jsonb` |
| `005_books` | 10 tabelas | imagem de referência e preço fora do mestre |
| `006_crm` | ~22 tabelas `crm_*` | versionamento de regras/tabela comercial preservado; `ambiente` não existe (homologação é outro projeto) |
| `007_margem_real` | ~13 tabelas `mr_*` | `owner` some (RLS por módulo); `mr_contratacao` é a fonte do acordado; tabelas sensíveis só `margem-real/financeiro` |
| `008_central_dp` | ocorrências, tratativas, representantes, lembretes, regras, exemplos de IA | regras de direcionamento por `usuario_id`; SLA em tabela de configuração |
| `009_whatsapp_trade_rh` | `wa_*`, `trade_*`, `rh_*` | chave `colaborador_id` no lugar de `participant_jid`/nome |
| `010_storage` | buckets e policies | `privado-financeiro`, `privado-rh`, `evidencias`, `books`, `wa-midia` |
| `011_views_integracao` | `vw_acordado_promotor`, `vw_kpis_bonificacao` | substituem as pontes HTTP MR↔CRM |

**Pronto quando:** `npm test` verde com casos de cada domínio, incluindo "usuário comercial não lê `mr_pagamentos`" e "RH lê `rh_registros`, trade não edita".

### U3 — ETL

Script único (Node, fora das bases Skip, em `scripts/migracao/`) que lê o backup exportado e grava via `SUPABASE_DB_URL`:

1. **Extrair:** ler o SQLite de cada backup, coleção por coleção, filtrando `ambiente = demonstracao` e dados de teste conhecidos.
2. **Mestres, nesta ordem:** empresas_dcg (MR + CRM) → redes → lojas (IO como base; Books/CRM/MR casam por código, CNPJ, nome normalizado e alias) → indústrias (IO + Books + CRM + MR) → produtos (IO + Books) → colaboradores (IO + Books + CRM + MR, casando por código Trade Pro, telefone/JID e nome normalizado). Cada casamento grava `migracao.id_map`; empate ou dúvida grava `migracao.pendencias` para revisão humana. Nada é criado por chute.
3. **Usuários:** um `auth.users` por e-mail distinto nos 4 bancos, criado por convite (sem copiar hash de senha); `usuario_papeis` com a soma dos papéis de transição; `usuario_industrias` a partir de `allowed_industries`.
4. **Domínios:** na ordem das FKs, trocando ids PocketBase por uuid via `id_map` e textos por FK via mestres.
5. **Arquivos:** copiar de `pb_data/storage` para o bucket correto, gravando o caminho na coluna.
6. **Reconciliar:** relatório por tabela (lidos × gravados × descartados × pendentes) e conferências de negócio: total de lançamentos por mês e por CNPJ, saldo de contas, total de contas a pagar/receber em aberto, número de ocorrências abertas, validades na base atual e rupturas ativas.

Idempotência: upsert por `(sistema, colecao, pb_id)`; rodar duas vezes não duplica.

### U4 — Backend (93 hooks)

| Tipo de hook | Exemplos | Destino |
|---|---|---|
| Regra em gravação | `owner_team`, `user_permissions_guard`, `pagamentos_regras`, `promotor_pix_regra`, guardas de status de ocorrência | trigger/constraint SQL ou RLS |
| Cron | sync Trade Pro, promotores, fotos (5 min); SLA e cobrança (20/30 min); alertas de contas e documentos | `pg_cron` chamando função SQL ou Edge Function |
| Integração externa | Trade Pro (4,8 mil linhas), Evolution/WhatsApp, Open Finance, geocodificação | Edge Functions com segredo no cofre; Trade Pro dividido por relatório |
| IA | assistentes do CRM, Thèo, classificação de ocorrência, IA financeira (usam `$ai.chat` do Skip) | Edge Function com provedor de IA próprio (D-U8) |
| Ponte entre sistemas | `sincronizar_acordado`, `promotor_sync_crm`, `kpis_crm`, `acordado_fonte` | **removidos**: viram as views da migration 011 |
| Depuração/limpeza/reset | `tmp_debug*`, `wx_cleanup`, `limpar_teste*`, `inspect_deep`, `probe_*`, `temp_admin_reset` | **não portados** |

### U5 — Ensaio

Carga completa num projeto Supabase de homologação (branch ou projeto separado), com as bases Skip apontadas para ele. Cada dono confere o seu recorte: Carol/Daniel (financeiro), Rhuan (IO), comercial (CRM), analistas (Books). A reconciliação da U3 precisa fechar sem diferença nos totais financeiros.

### U6 — Virada por sistema

Ordem sugerida: **IO → CRM (com Central DP para ocorrências) → Books → Margem Real**. A IO vai primeiro porque é dona dos mestres; a Margem Real por último porque é a mais sensível e a que mais depende de conferência.

Para cada sistema:

1. Avisar os usuários e congelar o PocketBase (regras de escrita = admin).
2. Rodar a carga delta do ETL.
3. Conferir a reconciliação.
4. Publicar a base Skip nova e enviar os convites de acesso.
5. Deixar o legado só leitura por 60 dias e então desligar. Desligar também as credenciais de serviço `CRM_*`/`MR_*`.

**Volta atrás:** até o passo 4, basta reabrir a escrita no PocketBase. Depois do passo 4, o que for gravado no Supabase precisa ser reaplicado manualmente no legado. Por isso, quem decide se vai ou não é o dono de cada sistema, no fim do passo 3.

---

## 5. Decisões necessárias antes da U2

| # | Decisão | Recomendação |
|---|---|---|
| D-U1 | `cnpjs` (MR) e `entidades_juridicas` (CRM) são a mesma coisa? | Sim: ambos viram `empresas_dcg`, com dono Margem Real |
| D-U2 | Contrato do MR (valor mensal para rateio) × contrato do CRM | Um `crm_contratos`; o MR lê valor mensal e CNPJ faturante |
| D-U3 | Trocas via WhatsApp (CRM) × devoluções (IO) | Mesmo processo: `io_devolucoes` com `origem = whatsapp`; o fluxo do bot passa a criar o caso |
| D-U4 | Agenda/visitas: planejado (Books, CRM) × realizado (IO) | `agenda_visitas` única (planejado) + `io_visitas` (realizado, Trade Pro) |
| D-U5 | Sortimento do Books × mix por loja da IO | `io_mix_loja` única, com status de sortimento |
| D-U6 | RH, gamificação e ponto: ficam no CRM (base 3) ou ganham base/módulo próprio? | Módulos `trade` e `rh` dentro da base 3 por agora; tabelas já separadas por prefixo |
| D-U7 | Papéis de transição espelhando os atuais × papéis novos já na virada | Transição (seção U1.4), para ninguém perder acesso na virada |
| D-U8 | Provedor de IA fora do Skip (`$ai.chat` não existe no Supabase) | Escolher provedor e chave no cofre antes da U4 |
| D-U9 | Retenção de dados brutos (`validades_raw`, históricos, mensagens de WhatsApp) | Seguir `retention_policy` da IO; mensagens antigas arquivadas |
| D-U10 | Quem exporta os backups de produção e onde ficam | Admin do Skip; armazenamento cifrado fora do Drive compartilhado |

Somam-se às pendências já registradas em `supabase/docs/pending_decisions.md` (PD-01 a PD-09) e a D-01/D-02 do escopo.

---

## 6. Riscos

| Risco | Efeito | Mitigação |
|---|---|---|
| Produção continua mudando durante o projeto | Esquema e hooks novos sem destino | Rodar U0.2 de novo antes de cada fase; acordar com o Daniel que mudança estrutural nos legados passa pelo repo central |
| Casamento errado de pessoas e lojas | Pagamento, nota ou bonificação no colaborador errado | Casamento só por chave forte; o resto vira pendência revisada; conferência financeira na U5 |
| Volume de WhatsApp/fotos | ETL lento, custo de storage | Medir na U0; carregar mídia antiga sob demanda ou só por período |
| Dependência do `$ai.chat` do Skip | IA para de funcionar na virada | D-U8 antes da U4 |
| Credenciais e dados sensíveis expostos | LGPD | Backups fora do Drive; RLS restrita antes da carga; nada real no git |
| Virada parcial (um sistema no Supabase, outro no PocketBase) | Dado de mestre em dois lugares | IO primeiro; durante a transição, os legados leem mestres do Supabase (somente leitura) |

---

## 7. Próximos passos imediatos

1. Decisões D-U1 a D-U10 com o Daniel (é a reunião que destrava a U2).
2. Acesso admin aos 4 PocketBase de produção para a U0 (exportação e contagem).
3. OK para aplicar `20261023_001`/`002` no Supabase (U1).
4. Higiene da U0.5 em produção (remover rotas de depuração do CRM).
