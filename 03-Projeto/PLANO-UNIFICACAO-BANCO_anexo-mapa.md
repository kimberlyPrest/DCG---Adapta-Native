# Anexo — Mapa coleção → destino (unificação do banco)

Gerado em 2026-10-23 a partir do `schema.json` de cada sistema legado e das coleções lidas da produção no Skip (projetos 50244, 50046, 50497, 59928). Toda coleção de produção tem um destino; o script falha se alguma ficar de fora.

¹ existe em produção mas não no repositório git.

Ações: **MESTRE** vai para cadastro compartilhado (SPEC-002) · **MIGRAR** vira tabela do domínio · **MESCLAR** junta com outra tabela · **DECIDIR** depende de decisão (D-U*) · **ARQUIVAR** exporta para `migracao.*`, não recria · **DESCARTAR** não migra.

Prefixos: `io_`, `books_`/`books`, `crm_`, `mr_` (Margem Real), `dp_` (Central DP), `wa_` (WhatsApp compartilhado), `trade_` (gamificação/PDV), `rh_`. Sem prefixo = cadastro mestre ou tabela comum.

| Sistema | Coleção (produção) | Destino no Supabase | Ação | Observação |
|---|---|---|---|---|
| IO | `users` | auth.users + usuarios + usuario_papeis + usuario_industrias | MESTRE | role → papel; allowed_industries → usuario_industrias; custom_permissions → exceções |
| IO | `import_history` | io_importacoes | MESCLAR | tipo = validades |
| IO | `validades_imported` | — | DESCARTAR | pipeline anterior a validades_base; confirmar se vazio/obsoleto |
| IO | `validades_raw` | io_validades_brutas | MIGRAR | aplicar retention_policy na carga |
| IO | `networks` | redes | MESTRE | fonte de verdade |
| IO | `stores` | lojas | MESTRE | fonte de verdade; codigo_externo → codigo_tradepro |
| IO | `validades_base` | io_validades | MIGRAR | textos de loja/produto/promotor viram FK |
| IO | `validades_corrections` | io_validades_correcoes | MIGRAR |  |
| IO | `store_aliases` | cadastro_aliases | MESTRE | entidade = loja |
| IO | `network_aliases` | cadastro_aliases | MESTRE | entidade = rede |
| IO | `auditoria_pendencias` | io_auditoria_pendencias | MIGRAR |  |
| IO | `rupturas_imports` | io_importacoes | MESCLAR | tipo = rupturas |
| IO | `rupturas_base` | io_rupturas | MIGRAR | tenant_id descartado |
| IO | `rupturas_historico` | io_rupturas_historico | MIGRAR | aplicar retenção |
| IO | `sync_logs` | io_sync_execucoes | MESCLAR |  |
| IO | `operational_cross_evidence` | io_evidencias_cruzadas | MIGRAR | era público; RLS por io |
| IO | `tradepro_connection_jobs` | io_sync_execucoes | MESCLAR | tipo = teste_conexao |
| IO | `tradepro_sync_jobs` | io_sync_execucoes | MESCLAR | tipo = sync_* |
| IO | `industry_registry` | industrias | MESTRE | fonte de verdade; tradepro_client_id no mestre |
| IO | `industry_store_coverage` | io_industria_lojas | MIGRAR | store_code → loja_id |
| IO | `industry_product_mix` | produtos | MESTRE | fonte de verdade; foto → Storage |
| IO | `industry_research_config` | io_industria_pesquisas | MIGRAR |  |
| IO | `industry_validity_policy` | io_politica_validade | MIGRAR |  |
| IO | `industry_config_audit` | io_industria_auditoria | MIGRAR |  |
| IO | `industry_store_product_mix` | io_mix_loja | MIGRAR | ver D-U5 (sortimento do Books) |
| IO | `industry_tracking_tratativas` | io_tratativas | MIGRAR | candidata a item de trabalho da Central DP |
| IO | `devolucoes_casos` | io_devolucoes | MIGRAR | ver D-U3 (trocas do CRM) |
| IO | `devolucoes_itens` | io_devolucao_itens | MIGRAR |  |
| IO | `devolucoes_timeline` | io_devolucao_eventos | MIGRAR |  |
| IO | `devolucoes_evidencias` | io_devolucao_evidencias | MIGRAR | arquivo → Storage |
| IO | `devolucoes_audit` | io_devolucao_eventos | MESCLAR |  |
| IO | `product_aliases` | cadastro_aliases | MESTRE | entidade = produto |
| IO | `devolucoes_import_batches` | io_devolucao_importacoes | MIGRAR |  |
| IO | `devolucoes_mensagens_importadas` | io_devolucao_mensagens | MIGRAR |  |
| IO | `user_audit_log` | migracao.legado_auditoria | ARQUIVAR | novos eventos em auditoria_permissoes |
| IO | `devolucoes_solicitacoes_importadas` | io_devolucao_solicitacoes | MIGRAR |  |
| IO | `operational_data_backups` | — | DESCARTAR | substituído por backup/PITR do Supabase |
| IO | `supervisors` | colaboradores | MESTRE | funcao = supervisor |
| IO | `promoters` | colaboradores | MESTRE | funcao = promotor; CPF: ver PD-03 |
| IO | `store_promoter_assignments` | io_colaborador_lojas | MIGRAR |  |
| IO | `cadastros_pendencias` | io_cadastros_pendencias | MIGRAR |  |
| IO | `operacional_visitas` | io_visitas | MIGRAR | realizado; ver D-U4 |
| IO | `validity_zeroing_records` | io_validade_ajustes | MESCLAR | tipo = zeramento; anexo → Storage |
| IO | `sync_schedule_config` | io_sync_config | MIGRAR | agendamento vira pg_cron |
| IO | `operacional_promotor_dia` | io_promotor_dia | MIGRAR |  |
| IO | `validity_manual_updates` | io_validade_ajustes | MESCLAR | tipo = atualizacao |
| IO | `retention_policy` | io_politica_retencao | MIGRAR |  |
| IO | `manual_corrections` | io_correcoes_manuais | MIGRAR |  |
| IO | `fotos_tag_base` | io_fotos_tags | MIGRAR |  |
| IO | `fotos_sync_jobs` | io_sync_execucoes | MESCLAR | tipo = fotos |
| IO | `tag_mapa_canonico` | io_tags_mapa | MIGRAR |  |
| Books | `users` | auth.users + usuarios + usuario_papeis | MESTRE | role (4 valores) → papéis |
| Books | `stores` | lojas | MESTRE | casar com IO por api_identifier/número; sobra vira pendência |
| Books | `brands` | industrias + books_marcas | MESTRE | frequência, analistas e supervisores em books_marcas |
| Books | `skus` | produtos + books_produto_referencia | MESTRE | imagem, preços, gôndola, splash na tabela do Books |
| Books | `promoters` | colaboradores | MESTRE | relações marca/loja → io_colaborador_lojas |
| Books | `audit_rules` | books_regras | MIGRAR |  |
| Books | `books` | books | MIGRAR | arquivo PPTX → Storage |
| Books | `book_photos` | books_fotos | MIGRAR | imagem → Storage |
| Books | `rupture_reports` | io_rupturas | DECIDIR | D-U4: ruptura declarada pela marca entra em io_rupturas com origem própria? |
| Books | `sku_classifications` | books_classificacoes | MIGRAR |  |
| Books | `integrations` | — | DESCARTAR | segredo vai para o cofre (SEG-09) |
| Books | `price_tables` | books_precos | MIGRAR | rede texto → rede_id |
| Books | `assortment_matrix` | io_mix_loja | DECIDIR | D-U5: sortimento do Books x mix por loja da IO |
| Books | `visit_schedules` | agenda_visitas | DECIDIR | D-U4: agenda única (planejado) para Books, CRM e IO |
| CRM | `users` | auth.users + usuarios + usuario_papeis | MESTRE | role + modulo (comercial/trade/books/rh/repositor/mei) → papéis |
| CRM | `clients` | industrias + crm_clientes | MESTRE | perfil comercial 1:1 com a indústria (PD-02) |
| CRM | `deals` | crm_oportunidades | MIGRAR |  |
| CRM | `proposals` | crm_propostas | MIGRAR | arquivo → Storage |
| CRM | `contracts` | crm_contratos | MIGRAR | fonte de verdade de contrato (D-U2) |
| CRM | `presentations` | crm_apresentacoes | MIGRAR |  |
| CRM | `ai_templates` | crm_ia_templates | MIGRAR |  |
| CRM | `redes` | redes | MESTRE | casar com IO por nome/alias |
| CRM | `lojas` | lojas | MESTRE | lat/long entram no mestre; PD-04 |
| CRM | `regras_operacionais` | crm_regras_operacionais | MIGRAR | versionamento preservado |
| CRM | `tabela_comercial` | crm_tabela_comercial | MIGRAR | versionamento preservado |
| CRM | `capacidade_operacional` | colaboradores + crm_capacidade | MESTRE | jornada/veículo/origem em crm_capacidade |
| CRM | `historico_ia` | crm_historico_ia | MIGRAR |  |
| CRM | `configuracoes_empresa` | crm_configuracoes | MIGRAR | dados de CNPJ → empresas_dcg |
| CRM | `historico_importacoes` | crm_importacoes | MESCLAR |  |
| CRM | `entidades_juridicas` | empresas_dcg | MESTRE | mesma entidade que cnpjs do Margem Real (D-U1) |
| CRM | `metas_comerciais` | crm_metas | MIGRAR |  |
| CRM | `lojas_operacao` | crm_lojas_operacao | MIGRAR | texto de loja → loja_id |
| CRM | `importacoes` | crm_importacoes | MESCLAR |  |
| CRM | `tempo_operacional` | crm_tempo_operacional | MIGRAR |  |
| CRM | `necessidades_contratacao` | crm_necessidades_contratacao | MIGRAR |  |
| CRM | `alocacoes_operacao` | crm_alocacoes | MIGRAR | planejado; D-U4 |
| CRM | `execucoes_operacao` | — | DESCARTAR | coleção sem campos |
| CRM | `homologacao_modelos_operacao` | crm_homologacao_modelos | MIGRAR |  |
| CRM | `auditoria_homologacao_modelos` | crm_homologacao_eventos | MIGRAR |  |
| CRM | `bot_config_grupos` | wa_grupos | MIGRAR | WhatsApp compartilhado; D-02 |
| CRM | `bot_sessoes` | wa_bot_sessoes | MIGRAR | pode recomeçar vazio |
| CRM | `metricas_pdv` | trade_metricas_pdv | MIGRAR |  |
| CRM | `whatsapp_instances` | wa_instancias | MIGRAR | qrcode/hash não migram; reconectar |
| CRM | `conversations` | wa_conversas | MIGRAR |  |
| CRM | `whatsapp_messages` | wa_mensagens | MIGRAR | mídia → Storage; volume a medir |
| CRM | `industrias` | industrias | MESTRE |  |
| CRM | `promotores` | colaboradores | MESTRE | participant_jid → colaboradores.whatsapp_jid; fim do casamento por nome |
| CRM | `ocorrencias` | dp_ocorrencias | MIGRAR | Central DP (D-01); junta com a base do sistema de Ocorrências |
| CRM | `tratativas` | dp_tratativas | MIGRAR |  |
| CRM | `mensagens_whatsapp` | dp_ocorrencia_mensagens | MIGRAR |  |
| CRM | `representantes` | dp_representantes | MIGRAR | FK industria_id |
| CRM | `lembretes` | dp_lembretes | MIGRAR |  |
| CRM | `ia_treino` | dp_ia_exemplos | MIGRAR |  |
| CRM | `regras_direcionamento` | dp_regras_direcionamento | MIGRAR | responsável vira usuario_id, não nome |
| CRM | `wx_debug` | — | DESCARTAR | depuração |
| CRM | `trocas` ¹ | io_devolucoes | DECIDIR | D-U3: troca via WhatsApp (CRM) x devolução (IO) são o mesmo processo? |
| CRM | `rh_registros` ¹ | rh_registros | MIGRAR | sensível: RLS só rh/admin |
| CRM | `conquistas` ¹ | trade_conquistas | MIGRAR |  |
| CRM | `gamificacao` ¹ | trade_gamificacao | MIGRAR | chave participant_jid → colaborador_id; pendencias_desconto sensível |
| CRM | `qr_registros` ¹ | rh_ponto | MIGRAR | entrada/saída por QR |
| CRM | `acompanhamentos` ¹ | trade_acompanhamentos | MIGRAR | promotor_nome → colaborador_id |
| CRM | `theo_ensinamentos` ¹ | wa_bot_conhecimento | MIGRAR |  |
| CRM | `orcamento_versoes` ¹ | crm_proposta_versoes | MIGRAR |  |
| CRM | `onboarding_itens` ¹ | crm_onboarding_itens | MIGRAR |  |
| CRM | `implantacao_plano` ¹ | crm_implantacao_pendencias | MIGRAR |  |
| CRM | `pesquisa_lojas` ¹ | crm_pesquisa_lojas | MIGRAR | lojas candidatas; viram lojas ao fechar |
| CRM | `acessos_log` ¹ | migracao.legado_acessos | ARQUIVAR | Supabase Auth registra logins |
| Margem Real | `users` | auth.users + usuarios + usuario_papeis | MESTRE | papel dono/equipe + permissoes (json) → papéis/exceções |
| Margem Real | `plano_contas` | mr_plano_contas | MIGRAR | owner descartado |
| Margem Real | `clientes` | industrias + mr_cliente_rateio | MESTRE | dias_atendimento e pct_rateio no MR |
| Margem Real | `promotores` | colaboradores + mr_contratacao | MESTRE | salário/bonificação/PIX/banco em mr_contratacao — fonte do acordado (decisão de 14/10) |
| Margem Real | `lancamentos` | mr_lancamentos | MIGRAR |  |
| Margem Real | `contas_receber` | mr_contas_receber | MIGRAR |  |
| Margem Real | `contas_pagar` | mr_contas_pagar | MIGRAR |  |
| Margem Real | `fechamentos` | mr_fechamentos | MIGRAR | DRE congelada (json) preservada |
| Margem Real | `cnpjs` | empresas_dcg | MESTRE | D-U1 |
| Margem Real | `contas_bancarias` | mr_contas_bancarias | MIGRAR |  |
| Margem Real | `contratos` | crm_contratos | DECIDIR | D-U2: contrato do MR (valor mensal) x contrato do CRM |
| Margem Real | `lojas` | lojas + crm_lojas_operacao | MESTRE | visitas/minutos por semana vêm do dimensionamento |
| Margem Real | `pagamentos` ¹ | mr_pagamentos | MIGRAR | sensível; NF → Storage |
| Margem Real | `of_conexoes` ¹ | mr_openfinance_conexoes | MIGRAR | token só no cofre; reconectar |
| Margem Real | `fechamento_mensal` ¹ | mr_faturamento | MIGRAR | faturamento por cliente/mês |
| Margem Real | `documentos` ¹ | mr_documentos | MIGRAR | sensível (folha, guias, extratos) → Storage privado |
| Margem Real | `alertas` ¹ | mr_alertas | MIGRAR | candidato a notificações da Central DP |

Totais: ARQUIVAR 2, DECIDIR 5, DESCARTAR 5, MESCLAR 11, MESTRE 28, MIGRAR 84 — 135 coleções.
