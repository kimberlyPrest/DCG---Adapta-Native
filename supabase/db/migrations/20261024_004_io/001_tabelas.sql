-- Migration 20261024_004_io — GERADA por scripts/unificacao/gerar_migrations.py. Não editar à mão:
-- ajuste o gerador e gere de novo. Origem: schema.json de produção (2026-10-21/22).

INSERT INTO public.modulos (system_id, chave, nome)
SELECT s.id, m.chave, m.nome FROM public.systems s
CROSS JOIN (VALUES ('cadastros', 'Cadastros'), ('configuracoes', 'Configurações'), ('devolucoes', 'Devoluções'), ('industrias', 'Indústrias'), ('integracoes', 'Integrações'), ('rupturas', 'Rupturas'), ('validades', 'Validades'), ('visitas', 'Visitas')) AS m(chave, nome)
WHERE s.slug = 'io'
ON CONFLICT (system_id, chave) DO UPDATE SET nome = EXCLUDED.nome;

INSERT INTO public.modulo_acoes (modulo_id, chave)
SELECT m.id, a.chave FROM public.modulos m JOIN public.systems s ON s.id = m.system_id
CROSS JOIN (VALUES ('visualizar'), ('criar'), ('editar'), ('deletar')) AS a(chave)
WHERE s.slug = 'io'
ON CONFLICT (modulo_id, chave) DO NOTHING;

-- io.cadastros_pendencias
CREATE TABLE public.io_cadastros_pendencias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  tipo_entidade text,
  valor_identificador text,
  codigo_externo text,
  nome_identificado text,
  contexto_adicional jsonb,
  origem_fonte text,
  status text,
  volume_ocorrencias numeric,
  entidade_resolvida_id text,
  entidade_resolvida_nome text,
  resolvido_por text,
  resolvido_em text,
  observacao_resolucao text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_cadastros_pendencias IS 'Origem: io.cadastros_pendencias (PocketBase). Dono: io/cadastros.';
COMMENT ON COLUMN public.io_cadastros_pendencias.tipo_entidade IS 'Valores: industria | rede | loja | produto | promotor | supervisor';
COMMENT ON COLUMN public.io_cadastros_pendencias.status IS 'Valores: pendente | vinculado | ignorado';
CREATE TRIGGER trg_io_cadastros_pendencias_atualizado_em BEFORE UPDATE ON public.io_cadastros_pendencias FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_cadastros_pendencias_tipo_entidade_status_idx ON public.io_cadastros_pendencias (tipo_entidade, status);
CREATE INDEX io_cadastros_pendencias_valor_identificador_idx ON public.io_cadastros_pendencias (valor_identificador);
ALTER TABLE public.io_cadastros_pendencias ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_cadastros_pendencias_select ON public.io_cadastros_pendencias FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'visualizar')));
CREATE POLICY io_cadastros_pendencias_insert ON public.io_cadastros_pendencias FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'criar')));
CREATE POLICY io_cadastros_pendencias_update ON public.io_cadastros_pendencias FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar')));
CREATE POLICY io_cadastros_pendencias_delete ON public.io_cadastros_pendencias FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'deletar')));
REVOKE ALL ON TABLE public.io_cadastros_pendencias FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_cadastros_pendencias TO authenticated;

-- io.devolucoes_casos
CREATE TABLE public.io_devolucoes_casos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  codigo_caso text,
  data_solicitacao text,
  industry_id text,
  industry_name text,
  store_id text,
  store_code text,
  store_name text,
  promotor_nome text,
  promotor_cod text,
  motivo_geral text,
  observacoes text,
  status text,
  responsavel_nome text,
  proxima_acao text,
  total_itens numeric,
  total_unidades_solicitadas numeric,
  total_unidades_autorizadas numeric,
  total_unidades_devolvidas numeric,
  valor_solicitado numeric,
  valor_autorizado numeric,
  valor_devolvido numeric,
  nf_numero text,
  nf_data text,
  nf_valor numeric,
  nf_anexo_nome text,
  nf_assinada_anexo_nome text,
  evidencia_descarte_anexo_nome text,
  autorizacao_protocolo text,
  autorizacao_data text,
  resultado_auditoria_geral text,
  resumo_auditoria_json jsonb,
  created_by uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  tipo_autorizacao_industria text,
  autorizacao_observacao text,
  autorizacao_registrada_por text,
  descarte_registrado_por text,
  descarte_data text,
  conclusao_data text,
  conclusao_usuario_nome text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_devolucoes_casos IS 'Origem: io.devolucoes_casos (PocketBase). Dono: io/devolucoes.';
COMMENT ON COLUMN public.io_devolucoes_casos.status IS 'Valores: solicitacao_recebida | em_analise | aguardando_informacao | pronta_para_envio | aguardando_autorizacao_industria | industria_autorizou | aguardando_nf_descarte | concluido | divergencia_encontrada | nao_autorizado | cancelado';
COMMENT ON COLUMN public.io_devolucoes_casos.created_by IS 'Relação legada → users';
COMMENT ON COLUMN public.io_devolucoes_casos.tipo_autorizacao_industria IS 'Valores: total | parcial | nao_autorizado';
CREATE TRIGGER trg_io_devolucoes_casos_atualizado_em BEFORE UPDATE ON public.io_devolucoes_casos FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX io_devolucoes_casos_codigo_caso_uk ON public.io_devolucoes_casos (codigo_caso);
CREATE INDEX io_devolucoes_casos_status_idx ON public.io_devolucoes_casos (status);
CREATE INDEX io_devolucoes_casos_industry_name_idx ON public.io_devolucoes_casos (industry_name);
CREATE INDEX io_devolucoes_casos_store_code_idx ON public.io_devolucoes_casos (store_code);
CREATE INDEX io_devolucoes_casos_promotor_nome_idx ON public.io_devolucoes_casos (promotor_nome);
CREATE INDEX io_devolucoes_casos_data_solicitacao_idx ON public.io_devolucoes_casos (data_solicitacao DESC);
ALTER TABLE public.io_devolucoes_casos ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_devolucoes_casos_select ON public.io_devolucoes_casos FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'visualizar')));
CREATE POLICY io_devolucoes_casos_insert ON public.io_devolucoes_casos FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'criar')));
CREATE POLICY io_devolucoes_casos_update ON public.io_devolucoes_casos FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar')));
CREATE POLICY io_devolucoes_casos_delete ON public.io_devolucoes_casos FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'deletar')));
REVOKE ALL ON TABLE public.io_devolucoes_casos FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_devolucoes_casos TO authenticated;

-- io.devolucoes_evidencias
CREATE TABLE public.io_devolucoes_evidencias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  caso_id uuid REFERENCES public.io_devolucoes_casos(id) ON DELETE SET NULL,
  item_id text,
  timeline_id text,
  tipo text,
  titulo text,
  descricao text,
  url_arquivo text,
  arquivo text,
  usuario_nome text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_devolucoes_evidencias IS 'Origem: io.devolucoes_evidencias (PocketBase). Dono: io/devolucoes.';
COMMENT ON COLUMN public.io_devolucoes_evidencias.caso_id IS 'Relação legada → devolucoes_casos';
COMMENT ON COLUMN public.io_devolucoes_evidencias.tipo IS 'Valores: foto_produto | foto_validade | foto_lote | nf_documento | nf_assinada | comprovante_descarte | outro';
CREATE TRIGGER trg_io_devolucoes_evidencias_atualizado_em BEFORE UPDATE ON public.io_devolucoes_evidencias FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_devolucoes_evidencias_caso_id_idx ON public.io_devolucoes_evidencias (caso_id);
CREATE INDEX io_devolucoes_evidencias_item_id_idx ON public.io_devolucoes_evidencias (item_id);
ALTER TABLE public.io_devolucoes_evidencias ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_devolucoes_evidencias_select ON public.io_devolucoes_evidencias FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'visualizar')));
CREATE POLICY io_devolucoes_evidencias_insert ON public.io_devolucoes_evidencias FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'criar')));
CREATE POLICY io_devolucoes_evidencias_update ON public.io_devolucoes_evidencias FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar')));
CREATE POLICY io_devolucoes_evidencias_delete ON public.io_devolucoes_evidencias FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'deletar')));
REVOKE ALL ON TABLE public.io_devolucoes_evidencias FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_devolucoes_evidencias TO authenticated;

-- io.devolucoes_import_batches
CREATE TABLE public.io_devolucoes_import_batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  file_name text,
  file_hash text,
  origem_canal text,
  total_mensagens numeric,
  mensagens_conhecidas numeric,
  mensagens_novas numeric,
  solicitacoes_identificadas numeric,
  solicitacoes_revisadas numeric,
  solicitacoes_importadas numeric,
  solicitacoes_ignoradas numeric,
  solicitacoes_incompletas numeric,
  usuario_nome text,
  resumo_processamento_json jsonb,
  hashes_mensagens_json jsonb,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_devolucoes_import_batches IS 'Origem: io.devolucoes_import_batches (PocketBase). Dono: io/devolucoes.';
CREATE TRIGGER trg_io_devolucoes_import_batches_atualizado_em BEFORE UPDATE ON public.io_devolucoes_import_batches FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_devolucoes_import_batches_file_hash_idx ON public.io_devolucoes_import_batches (file_hash);
CREATE INDEX io_devolucoes_import_batches_criado_em_idx ON public.io_devolucoes_import_batches (criado_em DESC);
ALTER TABLE public.io_devolucoes_import_batches ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_devolucoes_import_batches_select ON public.io_devolucoes_import_batches FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'visualizar')));
CREATE POLICY io_devolucoes_import_batches_insert ON public.io_devolucoes_import_batches FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'criar')));
CREATE POLICY io_devolucoes_import_batches_update ON public.io_devolucoes_import_batches FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar')));
CREATE POLICY io_devolucoes_import_batches_delete ON public.io_devolucoes_import_batches FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'deletar')));
REVOKE ALL ON TABLE public.io_devolucoes_import_batches FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_devolucoes_import_batches TO authenticated;

-- io.devolucoes_itens
CREATE TABLE public.io_devolucoes_itens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  caso_id uuid REFERENCES public.io_devolucoes_casos(id) ON DELETE SET NULL,
  codigo_caso text,
  produto_nome_informado text,
  produto_id text,
  produto_codigo text,
  produto_nome_oficial text,
  precisa_identificacao boolean DEFAULT false,
  quantidade_solicitada numeric,
  quantidade_autorizada numeric,
  quantidade_devolvida numeric,
  valor_unitario numeric,
  validade_informada text,
  validade_ausente boolean DEFAULT false,
  motivo_item text,
  observacao text,
  evidencia_foto_url text,
  classificacao_auditoria text,
  auditoria_explicacao text,
  auditoria_detalhes_json jsonb,
  decisao_humana text,
  decisao_observacao text,
  decisao_usuario_nome text,
  decisao_data text,
  situacao_autorizacao text,
  motivo_nao_autorizado text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_devolucoes_itens IS 'Origem: io.devolucoes_itens (PocketBase). Dono: io/devolucoes.';
COMMENT ON COLUMN public.io_devolucoes_itens.caso_id IS 'Relação legada → devolucoes_casos';
COMMENT ON COLUMN public.io_devolucoes_itens.classificacao_auditoria IS 'Valores: acompanhamento_consistente | atencao | divergencia | dados_insuficientes | nao_auditado';
COMMENT ON COLUMN public.io_devolucoes_itens.decisao_humana IS 'Valores: pendente | aprovado_para_industria | solicitar_informacao_promotor | registrar_divergencia | manter_em_analise | rejeitado';
COMMENT ON COLUMN public.io_devolucoes_itens.situacao_autorizacao IS 'Valores: pendente | autorizado | nao_autorizado';
CREATE TRIGGER trg_io_devolucoes_itens_atualizado_em BEFORE UPDATE ON public.io_devolucoes_itens FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_devolucoes_itens_caso_id_idx ON public.io_devolucoes_itens (caso_id);
CREATE INDEX io_devolucoes_itens_classificacao_auditoria_idx ON public.io_devolucoes_itens (classificacao_auditoria);
CREATE INDEX io_devolucoes_itens_decisao_humana_idx ON public.io_devolucoes_itens (decisao_humana);
ALTER TABLE public.io_devolucoes_itens ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_devolucoes_itens_select ON public.io_devolucoes_itens FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'visualizar')));
CREATE POLICY io_devolucoes_itens_insert ON public.io_devolucoes_itens FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'criar')));
CREATE POLICY io_devolucoes_itens_update ON public.io_devolucoes_itens FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar')));
CREATE POLICY io_devolucoes_itens_delete ON public.io_devolucoes_itens FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'deletar')));
REVOKE ALL ON TABLE public.io_devolucoes_itens FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_devolucoes_itens TO authenticated;

-- io.devolucoes_mensagens_importadas
CREATE TABLE public.io_devolucoes_mensagens_importadas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  hash_mensagem text,
  batch_id uuid REFERENCES public.io_devolucoes_import_batches(id) ON DELETE SET NULL,
  file_hash text,
  origem_canal text,
  data_hora_msg text,
  autor text,
  solicitacao_id text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_devolucoes_mensagens_importadas IS 'Origem: io.devolucoes_mensagens_importadas (PocketBase). Dono: io/devolucoes.';
COMMENT ON COLUMN public.io_devolucoes_mensagens_importadas.batch_id IS 'Relação legada → devolucoes_import_batches';
CREATE TRIGGER trg_io_devolucoes_mensagens_importadas_atualizado_em BEFORE UPDATE ON public.io_devolucoes_mensagens_importadas FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX io_devolucoes_mensagens_importadas_hash_mensagem_uk ON public.io_devolucoes_mensagens_importadas (hash_mensagem);
CREATE INDEX io_devolucoes_mensagens_importadas_batch_id_idx ON public.io_devolucoes_mensagens_importadas (batch_id);
CREATE INDEX io_devolucoes_mensagens_importadas_file_hash_idx ON public.io_devolucoes_mensagens_importadas (file_hash);
ALTER TABLE public.io_devolucoes_mensagens_importadas ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_devolucoes_mensagens_importadas_select ON public.io_devolucoes_mensagens_importadas FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'visualizar')));
CREATE POLICY io_devolucoes_mensagens_importadas_insert ON public.io_devolucoes_mensagens_importadas FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'criar')));
CREATE POLICY io_devolucoes_mensagens_importadas_update ON public.io_devolucoes_mensagens_importadas FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar')));
CREATE POLICY io_devolucoes_mensagens_importadas_delete ON public.io_devolucoes_mensagens_importadas FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'deletar')));
REVOKE ALL ON TABLE public.io_devolucoes_mensagens_importadas FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_devolucoes_mensagens_importadas TO authenticated;

-- io.devolucoes_solicitacoes_importadas
CREATE TABLE public.io_devolucoes_solicitacoes_importadas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  solicitacao_id text,
  raw_mensagem_id text,
  batch_id text,
  data_hora_msg text,
  autor text,
  loja_informada text,
  loja_codigo text,
  industria_informada text,
  industria_id text,
  estado_operacional text,
  caso_criado_id text,
  caso_criado_codigo text,
  ignorado_por text,
  ignorado_em text,
  ignorado_motivo text,
  processado_por text,
  processado_em text,
  trecho_original text,
  produtos_json jsonb,
  evidencias_json jsonb,
  reconciliacao_json jsonb,
  ajustes_operador_json jsonb,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_devolucoes_solicitacoes_importadas IS 'Origem: io.devolucoes_solicitacoes_importadas (PocketBase). Dono: io/devolucoes.';
COMMENT ON COLUMN public.io_devolucoes_solicitacoes_importadas.estado_operacional IS 'Valores: nova | pendente_revisao | processada | ignorada';
CREATE TRIGGER trg_io_devolucoes_solicitacoes_importadas_atualizado_em BEFORE UPDATE ON public.io_devolucoes_solicitacoes_importadas FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX io_devolucoes_solicitacoes_importadas_solicitacao_id_uk ON public.io_devolucoes_solicitacoes_importadas (solicitacao_id);
CREATE INDEX io_devolucoes_solicitacoes_importadas_estado_operacional_idx ON public.io_devolucoes_solicitacoes_importadas (estado_operacional);
CREATE INDEX io_devolucoes_solicitacoes_importadas_raw_mensagem_id_idx ON public.io_devolucoes_solicitacoes_importadas (raw_mensagem_id);
CREATE INDEX io_devolucoes_solicitacoes_importadas_caso_criado_id_idx ON public.io_devolucoes_solicitacoes_importadas (caso_criado_id);
ALTER TABLE public.io_devolucoes_solicitacoes_importadas ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_devolucoes_solicitacoes_importadas_select ON public.io_devolucoes_solicitacoes_importadas FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'visualizar')));
CREATE POLICY io_devolucoes_solicitacoes_importadas_insert ON public.io_devolucoes_solicitacoes_importadas FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'criar')));
CREATE POLICY io_devolucoes_solicitacoes_importadas_update ON public.io_devolucoes_solicitacoes_importadas FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar')));
CREATE POLICY io_devolucoes_solicitacoes_importadas_delete ON public.io_devolucoes_solicitacoes_importadas FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'deletar')));
REVOKE ALL ON TABLE public.io_devolucoes_solicitacoes_importadas FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_devolucoes_solicitacoes_importadas TO authenticated;

-- io.devolucoes_timeline
CREATE TABLE public.io_devolucoes_timeline (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  caso_id uuid REFERENCES public.io_devolucoes_casos(id) ON DELETE SET NULL,
  codigo_caso text,
  tipo_evento text,
  titulo text,
  descricao text,
  usuario_nome text,
  usuario_id text,
  item_id text,
  item_nome text,
  status_anterior text,
  status_novo text,
  dados_extras_json jsonb,
  data_evento text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_devolucoes_timeline IS 'Origem: io.devolucoes_timeline (PocketBase). Dono: io/devolucoes.';
COMMENT ON COLUMN public.io_devolucoes_timeline.caso_id IS 'Relação legada → devolucoes_casos';
COMMENT ON COLUMN public.io_devolucoes_timeline.tipo_evento IS 'Valores: criacao_solicitacao | edicao_dados | inclusao_item | remocao_item | edicao_item | auditoria_executada | decisao_humana | mudanca_status | informacao_solicitada | resposta_recebida | evidencia_anexada | autorizacao_industria | nf_registrada | descarte_registrado | caso_concluido | outro';
CREATE TRIGGER trg_io_devolucoes_timeline_atualizado_em BEFORE UPDATE ON public.io_devolucoes_timeline FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_devolucoes_timeline_caso_id_criado_em_idx ON public.io_devolucoes_timeline (caso_id, criado_em DESC);
CREATE INDEX io_devolucoes_timeline_tipo_evento_idx ON public.io_devolucoes_timeline (tipo_evento);
ALTER TABLE public.io_devolucoes_timeline ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_devolucoes_timeline_select ON public.io_devolucoes_timeline FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'visualizar')));
CREATE POLICY io_devolucoes_timeline_insert ON public.io_devolucoes_timeline FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'criar')));
CREATE POLICY io_devolucoes_timeline_update ON public.io_devolucoes_timeline FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar')));
CREATE POLICY io_devolucoes_timeline_delete ON public.io_devolucoes_timeline FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'deletar')));
REVOKE ALL ON TABLE public.io_devolucoes_timeline FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_devolucoes_timeline TO authenticated;

-- io.fotos_sync_jobs
CREATE TABLE public.io_fotos_sync_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  status text,
  dia_alvo text,
  pagina_atual numeric,
  requested_by text,
  origem text,
  started_at text,
  finished_at text,
  registros_lidos numeric,
  registros_inseridos numeric,
  registros_duplicados numeric,
  fotos_sem_tag numeric,
  tags_nao_mapeadas numeric,
  error_code text,
  message text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_fotos_sync_jobs IS 'Origem: io.fotos_sync_jobs (PocketBase). Dono: io/integracoes.';
COMMENT ON COLUMN public.io_fotos_sync_jobs.status IS 'Valores: pending | syncing | success | error';
CREATE TRIGGER trg_io_fotos_sync_jobs_atualizado_em BEFORE UPDATE ON public.io_fotos_sync_jobs FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.io_fotos_sync_jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_fotos_sync_jobs_select ON public.io_fotos_sync_jobs FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'visualizar')));
CREATE POLICY io_fotos_sync_jobs_insert ON public.io_fotos_sync_jobs FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'integracoes', 'criar')));
CREATE POLICY io_fotos_sync_jobs_update ON public.io_fotos_sync_jobs FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'integracoes', 'editar')));
CREATE POLICY io_fotos_sync_jobs_delete ON public.io_fotos_sync_jobs FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'deletar')));
REVOKE ALL ON TABLE public.io_fotos_sync_jobs FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_fotos_sync_jobs TO authenticated;

-- io.fotos_tag_base
CREATE TABLE public.io_fotos_tag_base (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  foto_id text,
  data_hora_recebimento text,
  dia_foto text,
  tag_raw text,
  tags_canonicas jsonb,
  tem_tag boolean DEFAULT false,
  mapeada boolean DEFAULT false,
  produto text,
  produto_id_fonte text,
  familia text,
  grupo text,
  categoria text,
  codigo_loja text,
  nome_loja text,
  rede text,
  cidade text,
  estado text,
  promotor_id_fonte text,
  promotor_nome text,
  supervisor_nome text,
  fornecedor text,
  obs_promotor text,
  obs_supervisor text,
  source_job_id text,
  dados_brutos_json jsonb,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_fotos_tag_base IS 'Origem: io.fotos_tag_base (PocketBase). Dono: io/integracoes.';
CREATE TRIGGER trg_io_fotos_tag_base_atualizado_em BEFORE UPDATE ON public.io_fotos_tag_base FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX io_fotos_tag_base_foto_id_uk ON public.io_fotos_tag_base (foto_id);
CREATE INDEX io_fotos_tag_base_codigo_loja_idx ON public.io_fotos_tag_base (codigo_loja);
CREATE INDEX io_fotos_tag_base_dia_foto_idx ON public.io_fotos_tag_base (dia_foto);
CREATE INDEX io_fotos_tag_base_promotor_id_fonte_idx ON public.io_fotos_tag_base (promotor_id_fonte);
ALTER TABLE public.io_fotos_tag_base ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_fotos_tag_base_select ON public.io_fotos_tag_base FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'visualizar')));
CREATE POLICY io_fotos_tag_base_insert ON public.io_fotos_tag_base FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'integracoes', 'criar')));
CREATE POLICY io_fotos_tag_base_update ON public.io_fotos_tag_base FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'integracoes', 'editar')));
CREATE POLICY io_fotos_tag_base_delete ON public.io_fotos_tag_base FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'deletar')));
REVOKE ALL ON TABLE public.io_fotos_tag_base FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_fotos_tag_base TO authenticated;

-- io.import_history
CREATE TABLE public.io_import_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  file_name text,
  file_size numeric,
  total_rows numeric,
  imported_rows numeric,
  skipped_rows numeric,
  error_rows numeric,
  status text,
  errors_json jsonb,
  source text,
  created_by uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  file_hash text,
  arquivo_tipo text,
  raw_count numeric,
  filtered_count numeric,
  base_count numeric,
  data_arquivo timestamptz,
  data_importacao text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_import_history IS 'Origem: io.import_history (PocketBase). Dono: io/integracoes.';
COMMENT ON COLUMN public.io_import_history.status IS 'Valores: pending | processing | completed | failed';
COMMENT ON COLUMN public.io_import_history.created_by IS 'Relação legada → users';
CREATE TRIGGER trg_io_import_history_atualizado_em BEFORE UPDATE ON public.io_import_history FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_import_history_criado_em_idx ON public.io_import_history (criado_em DESC);
CREATE INDEX io_import_history_file_hash_idx ON public.io_import_history (file_hash);
ALTER TABLE public.io_import_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_import_history_select ON public.io_import_history FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'visualizar')));
CREATE POLICY io_import_history_insert ON public.io_import_history FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'integracoes', 'criar')));
CREATE POLICY io_import_history_update ON public.io_import_history FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'integracoes', 'editar')));
CREATE POLICY io_import_history_delete ON public.io_import_history FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'deletar')));
REVOKE ALL ON TABLE public.io_import_history FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_import_history TO authenticated;

-- io.industry_config_audit
CREATE TABLE public.io_industry_config_audit (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  industry_id uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  modulo text,
  acao text,
  usuario_nome text,
  detalhes_json jsonb,
  data_alteracao text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_industry_config_audit IS 'Origem: io.industry_config_audit (PocketBase). Dono: io/industrias.';
COMMENT ON COLUMN public.io_industry_config_audit.industry_id IS 'Relação legada → industry_registry';
COMMENT ON COLUMN public.io_industry_config_audit.modulo IS 'Valores: identificacao | cobertura | mix | pesquisas | politica_validade | integracao_tradepro';
CREATE TRIGGER trg_io_industry_config_audit_atualizado_em BEFORE UPDATE ON public.io_industry_config_audit FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_industry_config_audit_industry_id_criado_em_idx ON public.io_industry_config_audit (industry_id, criado_em DESC);
ALTER TABLE public.io_industry_config_audit ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_industry_config_audit_select ON public.io_industry_config_audit FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'visualizar')) AND public.pode_ver_industria(industry_id));
CREATE POLICY io_industry_config_audit_insert ON public.io_industry_config_audit FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'industrias', 'criar')));
CREATE POLICY io_industry_config_audit_update ON public.io_industry_config_audit FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'industrias', 'editar')));
CREATE POLICY io_industry_config_audit_delete ON public.io_industry_config_audit FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'deletar')));
REVOKE ALL ON TABLE public.io_industry_config_audit FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_industry_config_audit TO authenticated;

-- io.industry_product_mix (identidade em produtos)
CREATE TABLE public.io_industry_product_mix (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
  industry_name text,
  tipo_mix text,
  status text,
  store_code_restrito text,
  codigo_interno text,
  app_diretoria_product_id text,
  foto text,
  foto_confirmada boolean DEFAULT false,
  foto_nota text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (produto_id)
);
COMMENT ON TABLE public.io_industry_product_mix IS 'Origem: io.industry_product_mix (PocketBase). Dono: io/industrias.';
COMMENT ON COLUMN public.io_industry_product_mix.tipo_mix IS 'Valores: oficial_industria | observado_operacional | fora_mix_oficial';
COMMENT ON COLUMN public.io_industry_product_mix.status IS 'Valores: ativo | descontinuado | em_avaliacao';
CREATE TRIGGER trg_io_industry_product_mix_atualizado_em BEFORE UPDATE ON public.io_industry_product_mix FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.io_industry_product_mix ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_industry_product_mix_select ON public.io_industry_product_mix FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'visualizar')));
CREATE POLICY io_industry_product_mix_insert ON public.io_industry_product_mix FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'industrias', 'criar')));
CREATE POLICY io_industry_product_mix_update ON public.io_industry_product_mix FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'industrias', 'editar')));
CREATE POLICY io_industry_product_mix_delete ON public.io_industry_product_mix FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'deletar')));
REVOKE ALL ON TABLE public.io_industry_product_mix FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_industry_product_mix TO authenticated;

-- io.industry_registry (identidade em industrias)
CREATE TABLE public.io_industry_registry (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  industria_id uuid NOT NULL REFERENCES public.industrias(id) ON DELETE CASCADE,
  nome_chave text,
  contato_nome text,
  contato_email text,
  contato_telefone text,
  observacoes text,
  tradepro_client_name text,
  app_diretoria_industry_id text,
  edicao_manual boolean DEFAULT false,
  origem_fonte text,
  ultima_observacao_fonte text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (industria_id)
);
COMMENT ON TABLE public.io_industry_registry IS 'Origem: io.industry_registry (PocketBase). Dono: io/industrias.';
CREATE TRIGGER trg_io_industry_registry_atualizado_em BEFORE UPDATE ON public.io_industry_registry FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX io_industry_registry_nome_chave_uk ON public.io_industry_registry (nome_chave);
ALTER TABLE public.io_industry_registry ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_industry_registry_select ON public.io_industry_registry FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'visualizar')));
CREATE POLICY io_industry_registry_insert ON public.io_industry_registry FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'industrias', 'criar')));
CREATE POLICY io_industry_registry_update ON public.io_industry_registry FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'industrias', 'editar')));
CREATE POLICY io_industry_registry_delete ON public.io_industry_registry FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'deletar')));
REVOKE ALL ON TABLE public.io_industry_registry FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_industry_registry TO authenticated;

-- io.industry_research_config
CREATE TABLE public.io_industry_research_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  industry_id uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  tipo_pesquisa text,
  ativo boolean DEFAULT false,
  frequencia text,
  dia_esperado text,
  horario_limite text,
  tolerancia_dias numeric,
  instrucoes text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_industry_research_config IS 'Origem: io.industry_research_config (PocketBase). Dono: io/industrias.';
COMMENT ON COLUMN public.io_industry_research_config.industry_id IS 'Relação legada → industry_registry';
COMMENT ON COLUMN public.io_industry_research_config.tipo_pesquisa IS 'Valores: validades | rupturas';
COMMENT ON COLUMN public.io_industry_research_config.frequencia IS 'Valores: diaria | semanal | quinzenal | mensal';
COMMENT ON COLUMN public.io_industry_research_config.dia_esperado IS 'Valores: segunda | terca | quarta | quinta | sexta | sabado | domingo | qualquer';
CREATE TRIGGER trg_io_industry_research_config_atualizado_em BEFORE UPDATE ON public.io_industry_research_config FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX io_industry_research_config_industry_id_tipo_pesquisa_uk ON public.io_industry_research_config (industry_id, tipo_pesquisa);
ALTER TABLE public.io_industry_research_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_industry_research_config_select ON public.io_industry_research_config FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'visualizar')) AND public.pode_ver_industria(industry_id));
CREATE POLICY io_industry_research_config_insert ON public.io_industry_research_config FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'industrias', 'criar')));
CREATE POLICY io_industry_research_config_update ON public.io_industry_research_config FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'industrias', 'editar')));
CREATE POLICY io_industry_research_config_delete ON public.io_industry_research_config FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'deletar')));
REVOKE ALL ON TABLE public.io_industry_research_config FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_industry_research_config TO authenticated;

-- io.industry_store_coverage
CREATE TABLE public.io_industry_store_coverage (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  industry_id uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  industry_name text,
  store_code text,
  store_name text,
  network_name text,
  city text,
  state text,
  status_relacao text,
  observacao text,
  origem_deteccao text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_industry_store_coverage IS 'Origem: io.industry_store_coverage (PocketBase). Dono: io/industrias.';
COMMENT ON COLUMN public.io_industry_store_coverage.industry_id IS 'Relação legada → industry_registry';
COMMENT ON COLUMN public.io_industry_store_coverage.status_relacao IS 'Valores: detectada | confirmada | ativa | inativa';
CREATE TRIGGER trg_io_industry_store_coverage_atualizado_em BEFORE UPDATE ON public.io_industry_store_coverage FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_industry_store_coverage_industry_id_store_code_idx ON public.io_industry_store_coverage (industry_id, store_code);
ALTER TABLE public.io_industry_store_coverage ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_industry_store_coverage_select ON public.io_industry_store_coverage FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'visualizar')) AND public.pode_ver_industria(industry_id));
CREATE POLICY io_industry_store_coverage_insert ON public.io_industry_store_coverage FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'industrias', 'criar')));
CREATE POLICY io_industry_store_coverage_update ON public.io_industry_store_coverage FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'industrias', 'editar')));
CREATE POLICY io_industry_store_coverage_delete ON public.io_industry_store_coverage FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'deletar')));
REVOKE ALL ON TABLE public.io_industry_store_coverage FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_industry_store_coverage TO authenticated;

-- io.industry_store_product_mix
CREATE TABLE public.io_industry_store_product_mix (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  industry_id uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  store_code text,
  store_name text,
  codigo_produto text,
  cod_barras text,
  nome_produto text,
  status text,
  origem_inclusao text,
  observacao text,
  tipo_presenca text,
  ultima_observacao text,
  evidencia_origem text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_industry_store_product_mix IS 'Origem: io.industry_store_product_mix (PocketBase). Dono: io/industrias.';
COMMENT ON COLUMN public.io_industry_store_product_mix.industry_id IS 'Relação legada → industry_registry';
COMMENT ON COLUMN public.io_industry_store_product_mix.status IS 'Valores: ativo | inativo | em_avaliacao';
COMMENT ON COLUMN public.io_industry_store_product_mix.tipo_presenca IS 'Valores: definido_loja | observado_operacional';
CREATE TRIGGER trg_io_industry_store_product_mix_atualizado_em BEFORE UPDATE ON public.io_industry_store_product_mix FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_industry_store_product_mix_industry_id_store_name_idx ON public.io_industry_store_product_mix (industry_id, store_name);
CREATE INDEX io_industry_store_product_mix_industry_id_nome_produto_idx ON public.io_industry_store_product_mix (industry_id, nome_produto);
ALTER TABLE public.io_industry_store_product_mix ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_industry_store_product_mix_select ON public.io_industry_store_product_mix FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'visualizar')) AND public.pode_ver_industria(industry_id));
CREATE POLICY io_industry_store_product_mix_insert ON public.io_industry_store_product_mix FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'industrias', 'criar')));
CREATE POLICY io_industry_store_product_mix_update ON public.io_industry_store_product_mix FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'industrias', 'editar')));
CREATE POLICY io_industry_store_product_mix_delete ON public.io_industry_store_product_mix FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'deletar')));
REVOKE ALL ON TABLE public.io_industry_store_product_mix FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_industry_store_product_mix TO authenticated;

-- io.industry_tracking_tratativas
CREATE TABLE public.io_industry_tracking_tratativas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  industry_id text,
  industry_name text,
  store_code text,
  store_name text,
  product_name text,
  product_code text,
  resultado text,
  usuario_nome text,
  observacao text,
  resposta text,
  motivo_identificacao text,
  ultimo_estado_conhecido_json jsonb,
  data_identificacao text,
  data_regularizacao text,
  status_tratativa text,
  sugestao_mix_loja boolean DEFAULT false,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_industry_tracking_tratativas IS 'Origem: io.industry_tracking_tratativas (PocketBase). Dono: io/industrias.';
COMMENT ON COLUMN public.io_industry_tracking_tratativas.resultado IS 'Valores: atualizacao_solicitada | aguardando_retorno | produto_vendido_zerado | ruptura_confirmada | produto_nao_trabalha_mais | mix_loja_precisa_atualizar | pesquisa_inconsistente | situacao_regularizada | observacao_manual';
COMMENT ON COLUMN public.io_industry_tracking_tratativas.status_tratativa IS 'Valores: aberto | em_andamento | regularizado | cancelado';
CREATE TRIGGER trg_io_industry_tracking_tratativas_atualizado_em BEFORE UPDATE ON public.io_industry_tracking_tratativas FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_industry_tracking_tratativas_industry_name_store_name_idx ON public.io_industry_tracking_tratativas (industry_name, store_name);
CREATE INDEX io_industry_tracking_tratativas_product_name_idx ON public.io_industry_tracking_tratativas (product_name);
CREATE INDEX io_industry_tracking_tratativas_status_tratativa_idx ON public.io_industry_tracking_tratativas (status_tratativa);
ALTER TABLE public.io_industry_tracking_tratativas ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_industry_tracking_tratativas_select ON public.io_industry_tracking_tratativas FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'visualizar')));
CREATE POLICY io_industry_tracking_tratativas_insert ON public.io_industry_tracking_tratativas FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'industrias', 'criar')));
CREATE POLICY io_industry_tracking_tratativas_update ON public.io_industry_tracking_tratativas FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'industrias', 'editar')));
CREATE POLICY io_industry_tracking_tratativas_delete ON public.io_industry_tracking_tratativas FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'deletar')));
REVOKE ALL ON TABLE public.io_industry_tracking_tratativas FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_industry_tracking_tratativas TO authenticated;

-- io.industry_validity_policy
CREATE TABLE public.io_industry_validity_policy (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  industry_id uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  nivel_regra text,
  produto_nome text,
  codigo_produto text,
  dias_critico numeric,
  dias_atencao numeric,
  dias_moderado numeric,
  shelf_life_padrao_dias numeric,
  justificativa text,
  ativo boolean DEFAULT false,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_industry_validity_policy IS 'Origem: io.industry_validity_policy (PocketBase). Dono: io/industrias.';
COMMENT ON COLUMN public.io_industry_validity_policy.industry_id IS 'Relação legada → industry_registry';
COMMENT ON COLUMN public.io_industry_validity_policy.nivel_regra IS 'Valores: sistema | industria | produto_excecao';
CREATE TRIGGER trg_io_industry_validity_policy_atualizado_em BEFORE UPDATE ON public.io_industry_validity_policy FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_industry_validity_policy_industry_id_nivel_regra_idx ON public.io_industry_validity_policy (industry_id, nivel_regra);
ALTER TABLE public.io_industry_validity_policy ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_industry_validity_policy_select ON public.io_industry_validity_policy FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'visualizar')) AND public.pode_ver_industria(industry_id));
CREATE POLICY io_industry_validity_policy_insert ON public.io_industry_validity_policy FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'industrias', 'criar')));
CREATE POLICY io_industry_validity_policy_update ON public.io_industry_validity_policy FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'industrias', 'editar')));
CREATE POLICY io_industry_validity_policy_delete ON public.io_industry_validity_policy FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'industrias', 'deletar')));
REVOKE ALL ON TABLE public.io_industry_validity_policy FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_industry_validity_policy TO authenticated;

-- io.manual_corrections
CREATE TABLE public.io_manual_corrections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  entidade text,
  chave_operacional text,
  store_code text,
  product_id text,
  industry_id text,
  acao text,
  tipo_ruptura_manual text,
  quantidade numeric,
  motivo text,
  observacao text,
  editado_por_id text,
  editado_por_nome text,
  editado_em timestamptz,
  valor_anterior_json jsonb,
  divergencia_status text,
  divergencia_desde timestamptz,
  ativo boolean DEFAULT false,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_manual_corrections IS 'Origem: io.manual_corrections (PocketBase). Dono: io/validades.';
COMMENT ON COLUMN public.io_manual_corrections.entidade IS 'Valores: validade | ruptura';
COMMENT ON COLUMN public.io_manual_corrections.acao IS 'Valores: editar | zerar | inserir_ruptura';
COMMENT ON COLUMN public.io_manual_corrections.tipo_ruptura_manual IS 'Valores: ruptura_total | zerado_estoque | estoque_virtual';
COMMENT ON COLUMN public.io_manual_corrections.motivo IS 'Valores: conferencia_confirmada | produto_saiu_de_linha | erro_de_digitacao | estoque_virtual | outro';
COMMENT ON COLUMN public.io_manual_corrections.divergencia_status IS 'Valores: vigente | fonte_atualizou';
CREATE TRIGGER trg_io_manual_corrections_atualizado_em BEFORE UPDATE ON public.io_manual_corrections FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_manual_corrections_chave_operacional_idx ON public.io_manual_corrections (chave_operacional);
CREATE INDEX io_manual_corrections_store_code_idx ON public.io_manual_corrections (store_code);
CREATE INDEX io_manual_corrections_ativo_divergencia_status_idx ON public.io_manual_corrections (ativo, divergencia_status);
ALTER TABLE public.io_manual_corrections ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_manual_corrections_select ON public.io_manual_corrections FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'visualizar')));
CREATE POLICY io_manual_corrections_insert ON public.io_manual_corrections FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'validades', 'criar')));
CREATE POLICY io_manual_corrections_update ON public.io_manual_corrections FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'validades', 'editar')));
CREATE POLICY io_manual_corrections_delete ON public.io_manual_corrections FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'deletar')));
REVOKE ALL ON TABLE public.io_manual_corrections FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_manual_corrections TO authenticated;

-- io.networks (identidade em redes)
CREATE TABLE public.io_networks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  rede_id uuid NOT NULL REFERENCES public.redes(id) ON DELETE CASCADE,
  created_by uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (rede_id)
);
COMMENT ON TABLE public.io_networks IS 'Origem: io.networks (PocketBase). Dono: io/cadastros.';
COMMENT ON COLUMN public.io_networks.created_by IS 'Relação legada → users';
CREATE TRIGGER trg_io_networks_atualizado_em BEFORE UPDATE ON public.io_networks FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.io_networks ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_networks_select ON public.io_networks FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'visualizar')));
CREATE POLICY io_networks_insert ON public.io_networks FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'criar')));
CREATE POLICY io_networks_update ON public.io_networks FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar')));
CREATE POLICY io_networks_delete ON public.io_networks FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'deletar')));
REVOKE ALL ON TABLE public.io_networks FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_networks TO authenticated;

-- io.operacional_promotor_dia
CREATE TABLE public.io_operacional_promotor_dia (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  data text,
  promotor_cod numeric,
  promotor_nome text,
  supervisor_nome text,
  filial text,
  online boolean DEFAULT false,
  bateria_primeira numeric,
  hora_final_trabalho text,
  roteiro_cadastrado numeric,
  roteiro_executado numeric,
  atividades_previstas numeric,
  atividades_executadas numeric,
  percentual_atividades text,
  roteiros_programados numeric,
  roteiros_visitados numeric,
  percentual_roteiros text,
  tempo_produtivo text,
  percentual_tempo_produtivo text,
  distancia_total text,
  primeira_atividade_hora text,
  ultima_atividade_hora text,
  eventos_total numeric,
  eventos_foto numeric,
  eventos_pesquisa_produto numeric,
  eventos_pesquisa_estoque numeric,
  eventos_entrada numeric,
  eventos_saida numeric,
  lojas_previstas numeric,
  lojas_finalizadas numeric,
  payload_completo boolean DEFAULT false,
  dados_brutos_json jsonb,
  origem_fonte text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_operacional_promotor_dia IS 'Origem: io.operacional_promotor_dia (PocketBase). Dono: io/visitas.';
CREATE TRIGGER trg_io_operacional_promotor_dia_atualizado_em BEFORE UPDATE ON public.io_operacional_promotor_dia FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX io_operacional_promotor_dia_promotor_cod_data_uk ON public.io_operacional_promotor_dia (promotor_cod, data);
CREATE INDEX io_operacional_promotor_dia_data_idx ON public.io_operacional_promotor_dia (data);
ALTER TABLE public.io_operacional_promotor_dia ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_operacional_promotor_dia_select ON public.io_operacional_promotor_dia FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'visitas', 'visualizar')));
CREATE POLICY io_operacional_promotor_dia_insert ON public.io_operacional_promotor_dia FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'visitas', 'criar')));
CREATE POLICY io_operacional_promotor_dia_update ON public.io_operacional_promotor_dia FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'visitas', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'visitas', 'editar')));
CREATE POLICY io_operacional_promotor_dia_delete ON public.io_operacional_promotor_dia FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'visitas', 'deletar')));
REVOKE ALL ON TABLE public.io_operacional_promotor_dia FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_operacional_promotor_dia TO authenticated;

-- io.operacional_visitas
CREATE TABLE public.io_operacional_visitas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  data text,
  promoter_id uuid REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  promoter_cod text,
  promoter_nome text,
  store_id uuid REFERENCES public.lojas(id) ON DELETE SET NULL,
  store_code text,
  store_name text,
  industry_name text,
  hora_inicio text,
  hora_fim text,
  duracao_minutos numeric,
  status_roteiro text,
  sequencia numeric,
  origem_fonte text,
  observacao text,
  dados_brutos_json jsonb,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_operacional_visitas IS 'Origem: io.operacional_visitas (PocketBase). Dono: io/visitas.';
COMMENT ON COLUMN public.io_operacional_visitas.promoter_id IS 'Relação legada → promoters';
COMMENT ON COLUMN public.io_operacional_visitas.store_id IS 'Relação legada → stores';
CREATE TRIGGER trg_io_operacional_visitas_atualizado_em BEFORE UPDATE ON public.io_operacional_visitas FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_operacional_visitas_data_idx ON public.io_operacional_visitas (data);
CREATE INDEX io_operacional_visitas_promoter_id_data_idx ON public.io_operacional_visitas (promoter_id, data);
CREATE INDEX io_operacional_visitas_store_code_data_idx ON public.io_operacional_visitas (store_code, data);
CREATE INDEX io_operacional_visitas_promoter_cod_store_code_data_idx ON public.io_operacional_visitas (promoter_cod, store_code, data);
ALTER TABLE public.io_operacional_visitas ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_operacional_visitas_select ON public.io_operacional_visitas FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'visitas', 'visualizar')));
CREATE POLICY io_operacional_visitas_insert ON public.io_operacional_visitas FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'visitas', 'criar')));
CREATE POLICY io_operacional_visitas_update ON public.io_operacional_visitas FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'visitas', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'visitas', 'editar')));
CREATE POLICY io_operacional_visitas_delete ON public.io_operacional_visitas FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'visitas', 'deletar')));
REVOKE ALL ON TABLE public.io_operacional_visitas FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_operacional_visitas TO authenticated;

-- io.product_aliases
CREATE TABLE public.io_product_aliases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  alias text,
  alias_normalizado text,
  produto_oficial_nome text,
  produto_oficial_codigo text,
  industria_id text,
  industria_nome text,
  familia text,
  sabor text,
  gramatura text,
  tipo_alias text,
  confirmado_por text,
  origem text,
  status text,
  quantidade_utilizacoes numeric,
  ultima_utilizacao text,
  observacao text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_product_aliases IS 'Origem: io.product_aliases (PocketBase). Dono: io/devolucoes.';
COMMENT ON COLUMN public.io_product_aliases.status IS 'Valores: ativo | inativo';
CREATE TRIGGER trg_io_product_aliases_atualizado_em BEFORE UPDATE ON public.io_product_aliases FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_product_aliases_alias_normalizado_idx ON public.io_product_aliases (alias_normalizado);
CREATE INDEX io_product_aliases_industria_nome_idx ON public.io_product_aliases (industria_nome);
CREATE INDEX io_product_aliases_status_idx ON public.io_product_aliases (status);
ALTER TABLE public.io_product_aliases ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_product_aliases_select ON public.io_product_aliases FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'visualizar')));
CREATE POLICY io_product_aliases_insert ON public.io_product_aliases FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'criar')));
CREATE POLICY io_product_aliases_update ON public.io_product_aliases FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar')));
CREATE POLICY io_product_aliases_delete ON public.io_product_aliases FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'deletar')));
REVOKE ALL ON TABLE public.io_product_aliases FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_product_aliases TO authenticated;

-- io.promoters (identidade em colaboradores)
CREATE TABLE public.io_promoters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  colaborador_id uuid NOT NULL REFERENCES public.colaboradores(id) ON DELETE CASCADE,
  cpf text,
  supervisor_nome text,
  status text,
  observacoes text,
  app_diretoria_promoter_id text,
  edicao_manual boolean DEFAULT false,
  origem_fonte text,
  ultima_observacao_fonte text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (colaborador_id)
);
COMMENT ON TABLE public.io_promoters IS 'Origem: io.promoters (PocketBase). Dono: io/cadastros.';
COMMENT ON COLUMN public.io_promoters.status IS 'Valores: ativo | inativo';
CREATE TRIGGER trg_io_promoters_atualizado_em BEFORE UPDATE ON public.io_promoters FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.io_promoters ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_promoters_select ON public.io_promoters FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'visualizar')));
CREATE POLICY io_promoters_insert ON public.io_promoters FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'criar')));
CREATE POLICY io_promoters_update ON public.io_promoters FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar')));
CREATE POLICY io_promoters_delete ON public.io_promoters FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'deletar')));
REVOKE ALL ON TABLE public.io_promoters FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_promoters TO authenticated;

-- io.retention_policy
CREATE TABLE public.io_retention_policy (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  politica text,
  entidade text,
  dias_retencao numeric,
  ativo boolean DEFAULT false,
  origem text,
  nota text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_retention_policy IS 'Origem: io.retention_policy (PocketBase). Dono: io/configuracoes.';
COMMENT ON COLUMN public.io_retention_policy.entidade IS 'Valores: validades | rupturas | ambas';
COMMENT ON COLUMN public.io_retention_policy.origem IS 'Valores: decisao_owner | sistema';
CREATE TRIGGER trg_io_retention_policy_atualizado_em BEFORE UPDATE ON public.io_retention_policy FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX io_retention_policy_politica_uk ON public.io_retention_policy (politica);
ALTER TABLE public.io_retention_policy ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_retention_policy_select ON public.io_retention_policy FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'configuracoes', 'visualizar')));
CREATE POLICY io_retention_policy_insert ON public.io_retention_policy FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'configuracoes', 'criar')));
CREATE POLICY io_retention_policy_update ON public.io_retention_policy FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'configuracoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'configuracoes', 'editar')));
CREATE POLICY io_retention_policy_delete ON public.io_retention_policy FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'configuracoes', 'deletar')));
REVOKE ALL ON TABLE public.io_retention_policy FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_retention_policy TO authenticated;

-- io.rupturas_imports
CREATE TABLE public.io_rupturas_imports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  tenant_id text,
  file_name text,
  file_hash text,
  total_rows_read numeric,
  total_rows_valid numeric,
  total_rows_invalid numeric,
  total_raw_rows_saved numeric,
  total_rows_processed numeric,
  total_occurrences_generated numeric,
  total_audit_records numeric,
  total_historical_records numeric,
  status text,
  error_message text,
  batch_config jsonb,
  created_at text,
  completed_at text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_rupturas_imports IS 'Origem: io.rupturas_imports (PocketBase). Dono: io/rupturas.';
COMMENT ON COLUMN public.io_rupturas_imports.status IS 'Valores: Recebida | Validando | Processando | Consolidando | Concluída | Concluída com rejeições | Falhou | Cancelada';
CREATE TRIGGER trg_io_rupturas_imports_atualizado_em BEFORE UPDATE ON public.io_rupturas_imports FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_rupturas_imports_file_hash_idx ON public.io_rupturas_imports (file_hash);
CREATE INDEX io_rupturas_imports_status_idx ON public.io_rupturas_imports (status);
CREATE INDEX io_rupturas_imports_tenant_id_idx ON public.io_rupturas_imports (tenant_id);
ALTER TABLE public.io_rupturas_imports ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_rupturas_imports_select ON public.io_rupturas_imports FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'rupturas', 'visualizar')));
CREATE POLICY io_rupturas_imports_insert ON public.io_rupturas_imports FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'rupturas', 'criar')));
CREATE POLICY io_rupturas_imports_update ON public.io_rupturas_imports FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'rupturas', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'rupturas', 'editar')));
CREATE POLICY io_rupturas_imports_delete ON public.io_rupturas_imports FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'rupturas', 'deletar')));
REVOKE ALL ON TABLE public.io_rupturas_imports FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_rupturas_imports TO authenticated;

-- io.store_promoter_assignments
CREATE TABLE public.io_store_promoter_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  promoter_id uuid REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  promoter_nome text,
  store_id uuid REFERENCES public.lojas(id) ON DELETE SET NULL,
  store_code text,
  store_name text,
  industry_id uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  industry_name text,
  status text,
  data_inicio text,
  data_fim text,
  observacao text,
  tipo_vinculo text,
  origem_vinculo text,
  ultima_observacao_fonte text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_store_promoter_assignments IS 'Origem: io.store_promoter_assignments (PocketBase). Dono: io/cadastros.';
COMMENT ON COLUMN public.io_store_promoter_assignments.promoter_id IS 'Relação legada → promoters';
COMMENT ON COLUMN public.io_store_promoter_assignments.store_id IS 'Relação legada → stores';
COMMENT ON COLUMN public.io_store_promoter_assignments.industry_id IS 'Relação legada → industry_registry';
COMMENT ON COLUMN public.io_store_promoter_assignments.status IS 'Valores: ativo | encerrado';
COMMENT ON COLUMN public.io_store_promoter_assignments.tipo_vinculo IS 'Valores: confirmado | observado_visita | observado_operacao';
CREATE TRIGGER trg_io_store_promoter_assignments_atualizado_em BEFORE UPDATE ON public.io_store_promoter_assignments FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_store_promoter_assignments_promoter_id_idx ON public.io_store_promoter_assignments (promoter_id);
CREATE INDEX io_store_promoter_assignments_store_code_idx ON public.io_store_promoter_assignments (store_code);
CREATE INDEX io_store_promoter_assignments_industry_id_idx ON public.io_store_promoter_assignments (industry_id);
ALTER TABLE public.io_store_promoter_assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_store_promoter_assignments_select ON public.io_store_promoter_assignments FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'visualizar')) AND public.pode_ver_industria(industry_id));
CREATE POLICY io_store_promoter_assignments_insert ON public.io_store_promoter_assignments FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'criar')));
CREATE POLICY io_store_promoter_assignments_update ON public.io_store_promoter_assignments FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar')));
CREATE POLICY io_store_promoter_assignments_delete ON public.io_store_promoter_assignments FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'deletar')));
REVOKE ALL ON TABLE public.io_store_promoter_assignments FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_store_promoter_assignments TO authenticated;

-- io.stores (identidade em lojas)
CREATE TABLE public.io_stores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  loja_id uuid NOT NULL REFERENCES public.lojas(id) ON DELETE CASCADE,
  created_by uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  codigo_loja text,
  nome_loja text,
  rede_nome text,
  app_diretoria_store_id text,
  edicao_manual boolean DEFAULT false,
  origem_fonte text,
  ultima_observacao_fonte text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (loja_id)
);
COMMENT ON TABLE public.io_stores IS 'Origem: io.stores (PocketBase). Dono: io/cadastros.';
COMMENT ON COLUMN public.io_stores.created_by IS 'Relação legada → users';
CREATE TRIGGER trg_io_stores_atualizado_em BEFORE UPDATE ON public.io_stores FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.io_stores ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_stores_select ON public.io_stores FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'visualizar')));
CREATE POLICY io_stores_insert ON public.io_stores FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'criar')));
CREATE POLICY io_stores_update ON public.io_stores FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar')));
CREATE POLICY io_stores_delete ON public.io_stores FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'deletar')));
REVOKE ALL ON TABLE public.io_stores FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_stores TO authenticated;

-- io.supervisors (identidade em colaboradores)
CREATE TABLE public.io_supervisors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  colaborador_id uuid NOT NULL REFERENCES public.colaboradores(id) ON DELETE CASCADE,
  email text,
  status text,
  observacoes text,
  app_diretoria_supervisor_id text,
  edicao_manual boolean DEFAULT false,
  origem_fonte text,
  ultima_observacao_fonte text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (colaborador_id)
);
COMMENT ON TABLE public.io_supervisors IS 'Origem: io.supervisors (PocketBase). Dono: io/cadastros.';
COMMENT ON COLUMN public.io_supervisors.status IS 'Valores: ativo | inativo';
CREATE TRIGGER trg_io_supervisors_atualizado_em BEFORE UPDATE ON public.io_supervisors FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.io_supervisors ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_supervisors_select ON public.io_supervisors FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'visualizar')));
CREATE POLICY io_supervisors_insert ON public.io_supervisors FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'criar')));
CREATE POLICY io_supervisors_update ON public.io_supervisors FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar')));
CREATE POLICY io_supervisors_delete ON public.io_supervisors FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'deletar')));
REVOKE ALL ON TABLE public.io_supervisors FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_supervisors TO authenticated;

-- io.sync_logs
CREATE TABLE public.io_sync_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  tipo text,
  status text,
  total_rows numeric,
  new_rows numeric,
  updated_rows numeric,
  errors jsonb,
  duration_ms numeric,
  created_by uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_sync_logs IS 'Origem: io.sync_logs (PocketBase). Dono: io/integracoes.';
COMMENT ON COLUMN public.io_sync_logs.status IS 'Valores: success | partial | error';
COMMENT ON COLUMN public.io_sync_logs.created_by IS 'Relação legada → users';
CREATE TRIGGER trg_io_sync_logs_atualizado_em BEFORE UPDATE ON public.io_sync_logs FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_sync_logs_tipo_idx ON public.io_sync_logs (tipo);
CREATE INDEX io_sync_logs_status_idx ON public.io_sync_logs (status);
CREATE INDEX io_sync_logs_criado_em_idx ON public.io_sync_logs (criado_em DESC);
ALTER TABLE public.io_sync_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_sync_logs_select ON public.io_sync_logs FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'visualizar')));
CREATE POLICY io_sync_logs_insert ON public.io_sync_logs FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'integracoes', 'criar')));
CREATE POLICY io_sync_logs_update ON public.io_sync_logs FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'integracoes', 'editar')));
CREATE POLICY io_sync_logs_delete ON public.io_sync_logs FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'deletar')));
REVOKE ALL ON TABLE public.io_sync_logs FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_sync_logs TO authenticated;

-- io.sync_schedule_config
CREATE TABLE public.io_sync_schedule_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  ativo boolean DEFAULT false,
  intervalo_minutos numeric,
  janela_inicio text,
  janela_fim text,
  rupturas_janela_dias numeric,
  validades_horizonte_dias numeric,
  sync_noturno_hora text,
  sync_noturno_ultimo_dia text,
  ultimo_disparo_agendado text,
  ultimo_tick text,
  ultimo_evento text,
  promotores_ativo boolean DEFAULT false,
  promotores_por_tick numeric,
  promotores_ultimo_sync text,
  promotores_ultimo_evento text,
  fotos_sync_hora text,
  fotos_sync_ultimo_dia text,
  fotos_sync_ativo boolean DEFAULT false,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_sync_schedule_config IS 'Origem: io.sync_schedule_config (PocketBase). Dono: io/integracoes.';
CREATE TRIGGER trg_io_sync_schedule_config_atualizado_em BEFORE UPDATE ON public.io_sync_schedule_config FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.io_sync_schedule_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_sync_schedule_config_select ON public.io_sync_schedule_config FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'visualizar')));
CREATE POLICY io_sync_schedule_config_insert ON public.io_sync_schedule_config FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'integracoes', 'criar')));
CREATE POLICY io_sync_schedule_config_update ON public.io_sync_schedule_config FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'integracoes', 'editar')));
CREATE POLICY io_sync_schedule_config_delete ON public.io_sync_schedule_config FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'deletar')));
REVOKE ALL ON TABLE public.io_sync_schedule_config FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_sync_schedule_config TO authenticated;

-- io.tag_mapa_canonico
CREATE TABLE public.io_tag_mapa_canonico (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  valor_fonte text,
  tag_canonica text,
  ativo boolean DEFAULT false,
  criado_por text,
  criado_em_origem text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_tag_mapa_canonico IS 'Origem: io.tag_mapa_canonico (PocketBase). Dono: io/integracoes.';
CREATE TRIGGER trg_io_tag_mapa_canonico_atualizado_em BEFORE UPDATE ON public.io_tag_mapa_canonico FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX io_tag_mapa_canonico_valor_fonte_uk ON public.io_tag_mapa_canonico (valor_fonte);
ALTER TABLE public.io_tag_mapa_canonico ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_tag_mapa_canonico_select ON public.io_tag_mapa_canonico FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'visualizar')));
CREATE POLICY io_tag_mapa_canonico_insert ON public.io_tag_mapa_canonico FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'integracoes', 'criar')));
CREATE POLICY io_tag_mapa_canonico_update ON public.io_tag_mapa_canonico FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'integracoes', 'editar')));
CREATE POLICY io_tag_mapa_canonico_delete ON public.io_tag_mapa_canonico FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'deletar')));
REVOKE ALL ON TABLE public.io_tag_mapa_canonico FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_tag_mapa_canonico TO authenticated;

-- io.tradepro_connection_jobs
CREATE TABLE public.io_tradepro_connection_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  action text,
  requested_by uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  date_start timestamptz,
  date_end timestamptz,
  status text,
  connected boolean DEFAULT false,
  http_status numeric,
  has_data boolean DEFAULT false,
  records_received numeric,
  total_records_reported numeric,
  latency_ms numeric,
  message text,
  error_code text,
  started_at timestamptz,
  finished_at timestamptz,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_tradepro_connection_jobs IS 'Origem: io.tradepro_connection_jobs (PocketBase). Dono: io/integracoes.';
COMMENT ON COLUMN public.io_tradepro_connection_jobs.action IS 'Valores: test_connection';
COMMENT ON COLUMN public.io_tradepro_connection_jobs.requested_by IS 'Relação legada → users';
COMMENT ON COLUMN public.io_tradepro_connection_jobs.status IS 'Valores: pending | processing | success | error';
COMMENT ON COLUMN public.io_tradepro_connection_jobs.error_code IS 'Valores: not_configured | invalid_period | unauthorized | forbidden | precondition_failed | rate_limited | timeout | tradepro_unavailable | internal_error';
CREATE TRIGGER trg_io_tradepro_connection_jobs_atualizado_em BEFORE UPDATE ON public.io_tradepro_connection_jobs FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_tradepro_connection_jobs_requested_by_criado_em_idx ON public.io_tradepro_connection_jobs (requested_by, criado_em DESC);
CREATE INDEX io_tradepro_connection_jobs_status_idx ON public.io_tradepro_connection_jobs (status);
ALTER TABLE public.io_tradepro_connection_jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_tradepro_connection_jobs_select ON public.io_tradepro_connection_jobs FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'visualizar')));
CREATE POLICY io_tradepro_connection_jobs_insert ON public.io_tradepro_connection_jobs FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'integracoes', 'criar')));
CREATE POLICY io_tradepro_connection_jobs_update ON public.io_tradepro_connection_jobs FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'integracoes', 'editar')));
CREATE POLICY io_tradepro_connection_jobs_delete ON public.io_tradepro_connection_jobs FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'deletar')));
REVOKE ALL ON TABLE public.io_tradepro_connection_jobs FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_tradepro_connection_jobs TO authenticated;

-- io.tradepro_sync_jobs
CREATE TABLE public.io_tradepro_sync_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  action text,
  requested_by uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  date_start text,
  date_end text,
  status text,
  total_informado numeric,
  paginas_total numeric,
  paginas_processadas numeric,
  registros_lidos numeric,
  registros_validos numeric,
  registros_rejeitados numeric,
  registros_deduplicados numeric,
  registros_consolidados numeric,
  error_code text,
  message text,
  started_at timestamptz,
  finished_at timestamptz,
  amostra_estrutura_json jsonb,
  origem text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_tradepro_sync_jobs IS 'Origem: io.tradepro_sync_jobs (PocketBase). Dono: io/integracoes.';
COMMENT ON COLUMN public.io_tradepro_sync_jobs.action IS 'Valores: sync_rupturas | sync_validades | sync_visitas';
COMMENT ON COLUMN public.io_tradepro_sync_jobs.requested_by IS 'Relação legada → users';
COMMENT ON COLUMN public.io_tradepro_sync_jobs.status IS 'Valores: pending | preview | syncing | success | error | paused | cancelled';
COMMENT ON COLUMN public.io_tradepro_sync_jobs.error_code IS 'Valores: not_configured | invalid_period | unauthorized | forbidden | precondition_failed | rate_limited | timeout | tradepro_unavailable | internal_error';
COMMENT ON COLUMN public.io_tradepro_sync_jobs.origem IS 'Valores: manual | agendado';
CREATE TRIGGER trg_io_tradepro_sync_jobs_atualizado_em BEFORE UPDATE ON public.io_tradepro_sync_jobs FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_tradepro_sync_jobs_requested_by_criado_em_idx ON public.io_tradepro_sync_jobs (requested_by, criado_em DESC);
CREATE INDEX io_tradepro_sync_jobs_status_idx ON public.io_tradepro_sync_jobs (status);
ALTER TABLE public.io_tradepro_sync_jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_tradepro_sync_jobs_select ON public.io_tradepro_sync_jobs FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'visualizar')));
CREATE POLICY io_tradepro_sync_jobs_insert ON public.io_tradepro_sync_jobs FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'integracoes', 'criar')));
CREATE POLICY io_tradepro_sync_jobs_update ON public.io_tradepro_sync_jobs FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'integracoes', 'editar')));
CREATE POLICY io_tradepro_sync_jobs_delete ON public.io_tradepro_sync_jobs FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'integracoes', 'deletar')));
REVOKE ALL ON TABLE public.io_tradepro_sync_jobs FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_tradepro_sync_jobs TO authenticated;

-- io.validades_base
CREATE TABLE public.io_validades_base (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  fornecedor text,
  razao_social text,
  produto text,
  cliente text,
  cod_cliente text,
  cod_produto text,
  cod_barras text,
  cpf_cnpj text,
  cnpj text,
  codigo_loja text,
  nome_loja text,
  rede text,
  cidade text,
  estado text,
  colaborador text,
  cod_colaborador text,
  supervisor text,
  cod_supervisor text,
  fantasia text,
  representante text,
  numero_lote text,
  realizado timestamptz,
  validade_original timestamptz,
  validade_efetiva timestamptz,
  data_arquivo timestamptz,
  data_importacao text,
  data_entrada timestamptz,
  ultima_aparicao timestamptz,
  quantidade numeric,
  is_base_atual boolean DEFAULT false,
  chave_operacional text,
  chave_dedup text,
  correcao_aplicada boolean DEFAULT false,
  regra_correcao text,
  dias_vencimento_atual numeric,
  dias_vencimento_arquivo numeric,
  dias_vencimento_entrada numeric,
  status_operacional text,
  status_na_entrada text,
  situacao_atual text,
  import_id uuid REFERENCES public.io_import_history(id) ON DELETE SET NULL,
  store_id uuid REFERENCES public.lojas(id) ON DELETE SET NULL,
  network_id uuid REFERENCES public.redes(id) ON DELETE SET NULL,
  created_by uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  sinalizado_correcao boolean DEFAULT false,
  status_auditoria text,
  industry_id uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  source_type text,
  source_job_id text,
  source_endpoint text,
  source_synced_at text,
  dados_brutos_json jsonb,
  data_fabricacao timestamptz,
  status_normalizacao text,
  product_id uuid REFERENCES public.produtos(id) ON DELETE SET NULL,
  promoter_id uuid REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  supervisor_id uuid REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_validades_base IS 'Origem: io.validades_base (PocketBase). Dono: io/validades.';
COMMENT ON COLUMN public.io_validades_base.status_operacional IS 'Valores: Vencido | Crítico | Atenção | Moderado | Normal';
COMMENT ON COLUMN public.io_validades_base.status_na_entrada IS 'Valores: Vencido | Crítico | Atenção | Moderado | Normal';
COMMENT ON COLUMN public.io_validades_base.situacao_atual IS 'Valores: Ativo | Encerrado/Não Reportado';
COMMENT ON COLUMN public.io_validades_base.import_id IS 'Relação legada → import_history';
COMMENT ON COLUMN public.io_validades_base.store_id IS 'Relação legada → stores';
COMMENT ON COLUMN public.io_validades_base.network_id IS 'Relação legada → networks';
COMMENT ON COLUMN public.io_validades_base.created_by IS 'Relação legada → users';
COMMENT ON COLUMN public.io_validades_base.status_auditoria IS 'Valores: pendente | corrigido | confirmado';
COMMENT ON COLUMN public.io_validades_base.industry_id IS 'Relação legada → industry_registry';
COMMENT ON COLUMN public.io_validades_base.status_normalizacao IS 'Valores: completo | parcial | pendente | conflito';
COMMENT ON COLUMN public.io_validades_base.product_id IS 'Relação legada → industry_product_mix';
COMMENT ON COLUMN public.io_validades_base.promoter_id IS 'Relação legada → promoters';
COMMENT ON COLUMN public.io_validades_base.supervisor_id IS 'Relação legada → supervisors';
CREATE TRIGGER trg_io_validades_base_atualizado_em BEFORE UPDATE ON public.io_validades_base FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_validades_base_chave_operacional_idx ON public.io_validades_base (chave_operacional);
CREATE INDEX io_validades_base_validade_efetiva_idx ON public.io_validades_base (validade_efetiva);
CREATE INDEX io_validades_base_realizado_idx ON public.io_validades_base (realizado);
CREATE INDEX io_validades_base_import_id_idx ON public.io_validades_base (import_id);
CREATE INDEX io_validades_base_nome_loja_idx ON public.io_validades_base (nome_loja);
CREATE INDEX io_validades_base_sinalizado_correcao_idx ON public.io_validades_base (sinalizado_correcao);
CREATE INDEX io_validades_base_is_base_atual_idx ON public.io_validades_base (is_base_atual);
CREATE INDEX io_validades_base_source_job_id_idx ON public.io_validades_base (source_job_id);
CREATE INDEX io_validades_base_status_normalizacao_idx ON public.io_validades_base (status_normalizacao);
CREATE INDEX io_validades_base_product_id_idx ON public.io_validades_base (product_id);
CREATE INDEX io_validades_base_promoter_id_idx ON public.io_validades_base (promoter_id);
CREATE INDEX io_validades_base_supervisor_id_idx ON public.io_validades_base (supervisor_id);
CREATE INDEX io_validades_base_is_base_atual_criado_em_idx ON public.io_validades_base (is_base_atual, criado_em);
ALTER TABLE public.io_validades_base ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_validades_base_select ON public.io_validades_base FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'visualizar')) AND public.pode_ver_industria(industry_id));
CREATE POLICY io_validades_base_insert ON public.io_validades_base FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'validades', 'criar')));
CREATE POLICY io_validades_base_update ON public.io_validades_base FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'validades', 'editar')));
CREATE POLICY io_validades_base_delete ON public.io_validades_base FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'deletar')));
REVOKE ALL ON TABLE public.io_validades_base FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_validades_base TO authenticated;

-- io.validades_corrections
CREATE TABLE public.io_validades_corrections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  fornecedor text,
  razao_social text,
  produto text,
  validade_errada timestamptz,
  validade_correta timestamptz,
  regra text,
  usuario text,
  data_correcao timestamptz,
  created_by uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_validades_corrections IS 'Origem: io.validades_corrections (PocketBase). Dono: io/validades.';
COMMENT ON COLUMN public.io_validades_corrections.created_by IS 'Relação legada → users';
CREATE TRIGGER trg_io_validades_corrections_atualizado_em BEFORE UPDATE ON public.io_validades_corrections FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX io_validades_corrections_fornecedor_razao_social_produto_valida ON public.io_validades_corrections (fornecedor, razao_social, produto, validade_errada);
ALTER TABLE public.io_validades_corrections ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_validades_corrections_select ON public.io_validades_corrections FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'visualizar')));
CREATE POLICY io_validades_corrections_insert ON public.io_validades_corrections FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'validades', 'criar')));
CREATE POLICY io_validades_corrections_update ON public.io_validades_corrections FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'validades', 'editar')));
CREATE POLICY io_validades_corrections_delete ON public.io_validades_corrections FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'deletar')));
REVOKE ALL ON TABLE public.io_validades_corrections FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_validades_corrections TO authenticated;

-- io.validades_imported
CREATE TABLE public.io_validades_imported (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  product text,
  sku text,
  lote text,
  category text,
  validade timestamptz,
  "diasRestantes" numeric,
  status text,
  unidade text,
  estoque numeric,
  cliente text,
  industria text,
  rede text,
  loja text,
  cidade text,
  uf text,
  promotor text,
  supervisor text,
  quantidade numeric,
  "precoUnitario" numeric,
  "ultimaAtualizacao" timestamptz,
  import_id uuid REFERENCES public.io_import_history(id) ON DELETE SET NULL,
  created_by uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_validades_imported IS 'Origem: io.validades_imported (PocketBase). Dono: io/validades.';
COMMENT ON COLUMN public.io_validades_imported.category IS 'Valores: Mercearia | Laticínios | Bebidas | Limpeza | Higiene';
COMMENT ON COLUMN public.io_validades_imported.status IS 'Valores: Crítico | Próximo | OK';
COMMENT ON COLUMN public.io_validades_imported.import_id IS 'Relação legada → import_history';
COMMENT ON COLUMN public.io_validades_imported.created_by IS 'Relação legada → users';
CREATE TRIGGER trg_io_validades_imported_atualizado_em BEFORE UPDATE ON public.io_validades_imported FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_validades_imported_sku_idx ON public.io_validades_imported (sku);
CREATE INDEX io_validades_imported_validade_idx ON public.io_validades_imported (validade);
CREATE INDEX io_validades_imported_import_id_idx ON public.io_validades_imported (import_id);
CREATE INDEX io_validades_imported_loja_idx ON public.io_validades_imported (loja);
ALTER TABLE public.io_validades_imported ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_validades_imported_select ON public.io_validades_imported FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'visualizar')));
CREATE POLICY io_validades_imported_insert ON public.io_validades_imported FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'validades', 'criar')));
CREATE POLICY io_validades_imported_update ON public.io_validades_imported FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'validades', 'editar')));
CREATE POLICY io_validades_imported_delete ON public.io_validades_imported FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'deletar')));
REVOKE ALL ON TABLE public.io_validades_imported FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_validades_imported TO authenticated;

-- io.validades_raw
CREATE TABLE public.io_validades_raw (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  cod_colaborador text,
  colaborador text,
  cod_supervisor text,
  supervisor text,
  cpf_cnpj text,
  razao_social text,
  fantasia text,
  cidade text,
  estado text,
  cod_cliente text,
  cliente text,
  cod_produto text,
  produto text,
  cod_barras text,
  data_fabricacao timestamptz,
  realizado timestamptz,
  quantidade numeric,
  dias_vencimento_arquivo numeric,
  validade timestamptz,
  numero_lote text,
  representante text,
  cnpj text,
  fornecedor text,
  numero_linha numeric,
  data_arquivo timestamptz,
  data_importacao text,
  import_id uuid REFERENCES public.io_import_history(id) ON DELETE SET NULL,
  created_by uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_validades_raw IS 'Origem: io.validades_raw (PocketBase). Dono: io/validades.';
COMMENT ON COLUMN public.io_validades_raw.import_id IS 'Relação legada → import_history';
COMMENT ON COLUMN public.io_validades_raw.created_by IS 'Relação legada → users';
CREATE TRIGGER trg_io_validades_raw_atualizado_em BEFORE UPDATE ON public.io_validades_raw FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_validades_raw_import_id_idx ON public.io_validades_raw (import_id);
CREATE INDEX io_validades_raw_realizado_idx ON public.io_validades_raw (realizado);
ALTER TABLE public.io_validades_raw ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_validades_raw_select ON public.io_validades_raw FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'visualizar')));
CREATE POLICY io_validades_raw_insert ON public.io_validades_raw FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'validades', 'criar')));
CREATE POLICY io_validades_raw_update ON public.io_validades_raw FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'validades', 'editar')));
CREATE POLICY io_validades_raw_delete ON public.io_validades_raw FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'deletar')));
REVOKE ALL ON TABLE public.io_validades_raw FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_validades_raw TO authenticated;

-- io.validity_manual_updates
CREATE TABLE public.io_validity_manual_updates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  validade_base_id text,
  source_key text,
  produto text,
  codigo_loja text,
  nome_loja text,
  cliente_industria text,
  quantidade_anterior numeric,
  quantidade_nova numeric,
  validade_efetiva text,
  realizado text,
  motivo text,
  observacao text,
  atualizado_por_id text,
  atualizado_por_nome text,
  atualizado_em_origem text,
  divergencia_status text,
  divergencia_quantidade numeric,
  divergencia_detectada_em text,
  anexo text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_validity_manual_updates IS 'Origem: io.validity_manual_updates (PocketBase). Dono: io/validades.';
COMMENT ON COLUMN public.io_validity_manual_updates.divergencia_status IS 'Valores: vigente | divergencia | encerrado';
CREATE TRIGGER trg_io_validity_manual_updates_atualizado_em BEFORE UPDATE ON public.io_validity_manual_updates FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_validity_manual_updates_source_key_idx ON public.io_validity_manual_updates (source_key);
ALTER TABLE public.io_validity_manual_updates ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_validity_manual_updates_select ON public.io_validity_manual_updates FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'visualizar')));
CREATE POLICY io_validity_manual_updates_insert ON public.io_validity_manual_updates FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'validades', 'criar')));
CREATE POLICY io_validity_manual_updates_update ON public.io_validity_manual_updates FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'validades', 'editar')));
CREATE POLICY io_validity_manual_updates_delete ON public.io_validity_manual_updates FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'deletar')));
REVOKE ALL ON TABLE public.io_validity_manual_updates FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_validity_manual_updates TO authenticated;

-- io.validity_zeroing_records
CREATE TABLE public.io_validity_zeroing_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  validade_base_id text,
  source_key text,
  produto text,
  codigo_loja text,
  nome_loja text,
  cliente_industria text,
  quantidade_zerada numeric,
  validade_efetiva text,
  realizado text,
  motivo text,
  observacao text,
  zerado_por_id text,
  zerado_por_nome text,
  zerado_em text,
  divergencia_status text,
  divergencia_quantidade numeric,
  divergencia_detectada_em text,
  anexo text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_validity_zeroing_records IS 'Origem: io.validity_zeroing_records (PocketBase). Dono: io/validades.';
COMMENT ON COLUMN public.io_validity_zeroing_records.motivo IS 'Valores: conferencia_confirmada | vencido_descartado | venda_sem_registro | erro_de_lancamento | outro';
COMMENT ON COLUMN public.io_validity_zeroing_records.divergencia_status IS 'Valores: vigente | divergencia | encerrado';
CREATE TRIGGER trg_io_validity_zeroing_records_atualizado_em BEFORE UPDATE ON public.io_validity_zeroing_records FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_validity_zeroing_records_source_key_idx ON public.io_validity_zeroing_records (source_key);
CREATE INDEX io_validity_zeroing_records_divergencia_status_idx ON public.io_validity_zeroing_records (divergencia_status);
CREATE INDEX io_validity_zeroing_records_zerado_em_idx ON public.io_validity_zeroing_records (zerado_em DESC);
ALTER TABLE public.io_validity_zeroing_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_validity_zeroing_records_select ON public.io_validity_zeroing_records FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'visualizar')));
CREATE POLICY io_validity_zeroing_records_insert ON public.io_validity_zeroing_records FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'validades', 'criar')));
CREATE POLICY io_validity_zeroing_records_update ON public.io_validity_zeroing_records FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'validades', 'editar')));
CREATE POLICY io_validity_zeroing_records_delete ON public.io_validity_zeroing_records FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'deletar')));
REVOKE ALL ON TABLE public.io_validity_zeroing_records FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_validity_zeroing_records TO authenticated;

-- io.auditoria_pendencias
CREATE TABLE public.io_auditoria_pendencias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  validade_base_id uuid REFERENCES public.io_validades_base(id) ON DELETE SET NULL,
  chave_operacional text,
  produto text,
  loja text,
  codigo_loja text,
  quantidade numeric,
  validade_efetiva timestamptz,
  dias_vencido numeric,
  data_entrada timestamptz,
  promotor text,
  supervisor text,
  motivo_sinalizacao text,
  sinalizado_por text,
  sinalizado_em timestamptz,
  status_auditoria text,
  import_id uuid REFERENCES public.io_import_history(id) ON DELETE SET NULL,
  created_by uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_auditoria_pendencias IS 'Origem: io.auditoria_pendencias (PocketBase). Dono: io/validades.';
COMMENT ON COLUMN public.io_auditoria_pendencias.validade_base_id IS 'Relação legada → validades_base';
COMMENT ON COLUMN public.io_auditoria_pendencias.status_auditoria IS 'Valores: pendente | corrigido | confirmado';
COMMENT ON COLUMN public.io_auditoria_pendencias.import_id IS 'Relação legada → import_history';
COMMENT ON COLUMN public.io_auditoria_pendencias.created_by IS 'Relação legada → users';
CREATE TRIGGER trg_io_auditoria_pendencias_atualizado_em BEFORE UPDATE ON public.io_auditoria_pendencias FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_auditoria_pendencias_status_auditoria_idx ON public.io_auditoria_pendencias (status_auditoria);
CREATE INDEX io_auditoria_pendencias_validade_base_id_idx ON public.io_auditoria_pendencias (validade_base_id);
CREATE INDEX io_auditoria_pendencias_chave_operacional_idx ON public.io_auditoria_pendencias (chave_operacional);
ALTER TABLE public.io_auditoria_pendencias ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_auditoria_pendencias_select ON public.io_auditoria_pendencias FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'visualizar')));
CREATE POLICY io_auditoria_pendencias_insert ON public.io_auditoria_pendencias FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'validades', 'criar')));
CREATE POLICY io_auditoria_pendencias_update ON public.io_auditoria_pendencias FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'validades', 'editar')));
CREATE POLICY io_auditoria_pendencias_delete ON public.io_auditoria_pendencias FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'validades', 'deletar')));
REVOKE ALL ON TABLE public.io_auditoria_pendencias FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_auditoria_pendencias TO authenticated;

-- io.devolucoes_audit
CREATE TABLE public.io_devolucoes_audit (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  caso_id uuid REFERENCES public.io_devolucoes_casos(id) ON DELETE SET NULL,
  acao text,
  usuario_nome text,
  usuario_id text,
  detalhes_json jsonb,
  data_acao text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_devolucoes_audit IS 'Origem: io.devolucoes_audit (PocketBase). Dono: io/devolucoes.';
COMMENT ON COLUMN public.io_devolucoes_audit.caso_id IS 'Relação legada → devolucoes_casos';
CREATE TRIGGER trg_io_devolucoes_audit_atualizado_em BEFORE UPDATE ON public.io_devolucoes_audit FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_devolucoes_audit_caso_id_criado_em_idx ON public.io_devolucoes_audit (caso_id, criado_em DESC);
CREATE INDEX io_devolucoes_audit_acao_idx ON public.io_devolucoes_audit (acao);
ALTER TABLE public.io_devolucoes_audit ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_devolucoes_audit_select ON public.io_devolucoes_audit FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'visualizar')));
CREATE POLICY io_devolucoes_audit_insert ON public.io_devolucoes_audit FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'criar')));
CREATE POLICY io_devolucoes_audit_update ON public.io_devolucoes_audit FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'devolucoes', 'editar')));
CREATE POLICY io_devolucoes_audit_delete ON public.io_devolucoes_audit FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'devolucoes', 'deletar')));
REVOKE ALL ON TABLE public.io_devolucoes_audit FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_devolucoes_audit TO authenticated;

-- io.rupturas_base
CREATE TABLE public.io_rupturas_base (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  tenant_id text,
  produto text,
  motivo text,
  codigo_loja text,
  nome_loja text,
  cnpj_loja text,
  cidade text,
  estado text,
  codigo_cliente text,
  cliente text,
  colaborador text,
  categoria text,
  observacao text,
  data_visita text,
  data_entrada text,
  ultima_aparicao text,
  situacao_atual text,
  operational_key text,
  dedup_key text,
  source_import_id uuid REFERENCES public.io_rupturas_imports(id) ON DELETE SET NULL,
  source_row numeric,
  is_base_atual boolean DEFAULT false,
  created_by uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  rede text,
  fantasia text,
  razao_social text,
  tradepro_cliente_nome text,
  source_type text,
  source_job_id text,
  source_endpoint text,
  source_synced_at text,
  dados_brutos_json jsonb,
  id_promotor text,
  id_supervisor text,
  nome_supervisor text,
  id_cliente text,
  id_atividade text,
  id_atividade_ruptura text,
  status_roteiro text,
  id_roteiro_padrao text,
  descricao_roteiro_padrao text,
  hora_inicio_execucao_roteiro text,
  hora_final_execucao_roteiro text,
  data_hora_execucao_atividade text,
  cnpj_fornecedor text,
  descricao_fornecedor text,
  codigo_familia text,
  descricao_familia text,
  status_normalizacao text,
  industry_id uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  store_id uuid REFERENCES public.lojas(id) ON DELETE SET NULL,
  product_id uuid REFERENCES public.produtos(id) ON DELETE SET NULL,
  promoter_id uuid REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  supervisor_id uuid REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_rupturas_base IS 'Origem: io.rupturas_base (PocketBase). Dono: io/rupturas.';
COMMENT ON COLUMN public.io_rupturas_base.motivo IS 'Valores: Ruptura Total | Sem Estoque Mínimo | Estoque Virtual';
COMMENT ON COLUMN public.io_rupturas_base.situacao_atual IS 'Valores: Ativo | Resolvido';
COMMENT ON COLUMN public.io_rupturas_base.source_import_id IS 'Relação legada → rupturas_imports';
COMMENT ON COLUMN public.io_rupturas_base.created_by IS 'Relação legada → users';
COMMENT ON COLUMN public.io_rupturas_base.status_normalizacao IS 'Valores: completo | parcial | pendente | conflito';
COMMENT ON COLUMN public.io_rupturas_base.industry_id IS 'Relação legada → industry_registry';
COMMENT ON COLUMN public.io_rupturas_base.store_id IS 'Relação legada → stores';
COMMENT ON COLUMN public.io_rupturas_base.product_id IS 'Relação legada → industry_product_mix';
COMMENT ON COLUMN public.io_rupturas_base.promoter_id IS 'Relação legada → promoters';
COMMENT ON COLUMN public.io_rupturas_base.supervisor_id IS 'Relação legada → supervisors';
CREATE TRIGGER trg_io_rupturas_base_atualizado_em BEFORE UPDATE ON public.io_rupturas_base FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_rupturas_base_operational_key_idx ON public.io_rupturas_base (operational_key);
CREATE INDEX io_rupturas_base_dedup_key_idx ON public.io_rupturas_base (dedup_key);
CREATE INDEX io_rupturas_base_situacao_atual_idx ON public.io_rupturas_base (situacao_atual);
CREATE INDEX io_rupturas_base_codigo_loja_idx ON public.io_rupturas_base (codigo_loja);
CREATE INDEX io_rupturas_base_cliente_idx ON public.io_rupturas_base (cliente);
CREATE INDEX io_rupturas_base_data_visita_idx ON public.io_rupturas_base (data_visita);
CREATE INDEX io_rupturas_base_source_import_id_idx ON public.io_rupturas_base (source_import_id);
CREATE INDEX io_rupturas_base_is_base_atual_idx ON public.io_rupturas_base (is_base_atual);
CREATE INDEX io_rupturas_base_rede_idx ON public.io_rupturas_base (rede);
CREATE INDEX io_rupturas_base_source_job_id_idx ON public.io_rupturas_base (source_job_id);
CREATE INDEX io_rupturas_base_status_normalizacao_idx ON public.io_rupturas_base (status_normalizacao);
CREATE INDEX io_rupturas_base_product_id_idx ON public.io_rupturas_base (product_id);
CREATE INDEX io_rupturas_base_promoter_id_idx ON public.io_rupturas_base (promoter_id);
CREATE INDEX io_rupturas_base_supervisor_id_idx ON public.io_rupturas_base (supervisor_id);
CREATE INDEX io_rupturas_base_is_base_atual_criado_em_idx ON public.io_rupturas_base (is_base_atual, criado_em);
ALTER TABLE public.io_rupturas_base ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_rupturas_base_select ON public.io_rupturas_base FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'rupturas', 'visualizar')) AND public.pode_ver_industria(industry_id));
CREATE POLICY io_rupturas_base_insert ON public.io_rupturas_base FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'rupturas', 'criar')));
CREATE POLICY io_rupturas_base_update ON public.io_rupturas_base FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'rupturas', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'rupturas', 'editar')));
CREATE POLICY io_rupturas_base_delete ON public.io_rupturas_base FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'rupturas', 'deletar')));
REVOKE ALL ON TABLE public.io_rupturas_base FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_rupturas_base TO authenticated;

-- io.rupturas_historico
CREATE TABLE public.io_rupturas_historico (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  ruptura_base_id uuid REFERENCES public.io_rupturas_base(id) ON DELETE SET NULL,
  tenant_id text,
  evento text,
  dados_anteriores jsonb,
  dados_novos jsonb,
  data_evento text,
  source_import_id uuid REFERENCES public.io_rupturas_imports(id) ON DELETE SET NULL,
  created_by uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_rupturas_historico IS 'Origem: io.rupturas_historico (PocketBase). Dono: io/rupturas.';
COMMENT ON COLUMN public.io_rupturas_historico.ruptura_base_id IS 'Relação legada → rupturas_base';
COMMENT ON COLUMN public.io_rupturas_historico.evento IS 'Valores: criacao | atualizacao | resolucao | encerramento';
COMMENT ON COLUMN public.io_rupturas_historico.source_import_id IS 'Relação legada → rupturas_imports';
COMMENT ON COLUMN public.io_rupturas_historico.created_by IS 'Relação legada → users';
CREATE TRIGGER trg_io_rupturas_historico_atualizado_em BEFORE UPDATE ON public.io_rupturas_historico FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX io_rupturas_historico_ruptura_base_id_idx ON public.io_rupturas_historico (ruptura_base_id);
CREATE INDEX io_rupturas_historico_evento_idx ON public.io_rupturas_historico (evento);
CREATE INDEX io_rupturas_historico_source_import_id_idx ON public.io_rupturas_historico (source_import_id);
ALTER TABLE public.io_rupturas_historico ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_rupturas_historico_select ON public.io_rupturas_historico FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'rupturas', 'visualizar')));
CREATE POLICY io_rupturas_historico_insert ON public.io_rupturas_historico FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'rupturas', 'criar')));
CREATE POLICY io_rupturas_historico_update ON public.io_rupturas_historico FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'rupturas', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'rupturas', 'editar')));
CREATE POLICY io_rupturas_historico_delete ON public.io_rupturas_historico FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'rupturas', 'deletar')));
REVOKE ALL ON TABLE public.io_rupturas_historico FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_rupturas_historico TO authenticated;

-- io.operational_cross_evidence
CREATE TABLE public.io_operational_cross_evidence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  rupture_record_id uuid REFERENCES public.io_rupturas_base(id) ON DELETE SET NULL,
  validity_record_id uuid REFERENCES public.io_validades_base(id) ON DELETE SET NULL,
  store_code text,
  store_name text,
  store_key text,
  product_code text,
  product_name text,
  product_key text,
  client_or_brand text,
  rupture_detected_at text,
  stock_evidence_at text,
  quantity_found numeric,
  product_expiry_date text,
  resolution_days numeric,
  match_method text,
  confidence text,
  proposed_status text,
  review_status text,
  reviewed_at text,
  reviewed_by text,
  rejection_reason text,
  engine_version text,
  evidence_key text,
  created_at text,
  updated_at text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.io_operational_cross_evidence IS 'Origem: io.operational_cross_evidence (PocketBase). Dono: io/rupturas.';
COMMENT ON COLUMN public.io_operational_cross_evidence.rupture_record_id IS 'Relação legada → rupturas_base';
COMMENT ON COLUMN public.io_operational_cross_evidence.validity_record_id IS 'Relação legada → validades_base';
COMMENT ON COLUMN public.io_operational_cross_evidence.match_method IS 'Valores: high_code_product | medium_exact_name | inconclusive';
COMMENT ON COLUMN public.io_operational_cross_evidence.confidence IS 'Valores: high | medium | inconclusive';
COMMENT ON COLUMN public.io_operational_cross_evidence.proposed_status IS 'Valores: inferred_resolved | awaiting_review | inconclusive | reopened';
COMMENT ON COLUMN public.io_operational_cross_evidence.review_status IS 'Valores: pending | confirmed | rejected';
CREATE TRIGGER trg_io_operational_cross_evidence_atualizado_em BEFORE UPDATE ON public.io_operational_cross_evidence FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX io_operational_cross_evidence_evidence_key_uk ON public.io_operational_cross_evidence (evidence_key);
CREATE INDEX io_operational_cross_evidence_review_status_idx ON public.io_operational_cross_evidence (review_status);
CREATE INDEX io_operational_cross_evidence_store_code_idx ON public.io_operational_cross_evidence (store_code);
CREATE INDEX io_operational_cross_evidence_confidence_idx ON public.io_operational_cross_evidence (confidence);
CREATE INDEX io_operational_cross_evidence_proposed_status_idx ON public.io_operational_cross_evidence (proposed_status);
ALTER TABLE public.io_operational_cross_evidence ENABLE ROW LEVEL SECURITY;
CREATE POLICY io_operational_cross_evidence_select ON public.io_operational_cross_evidence FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('io', 'rupturas', 'visualizar')));
CREATE POLICY io_operational_cross_evidence_insert ON public.io_operational_cross_evidence FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('io', 'rupturas', 'criar')));
CREATE POLICY io_operational_cross_evidence_update ON public.io_operational_cross_evidence FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'rupturas', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('io', 'rupturas', 'editar')));
CREATE POLICY io_operational_cross_evidence_delete ON public.io_operational_cross_evidence FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('io', 'rupturas', 'deletar')));
REVOKE ALL ON TABLE public.io_operational_cross_evidence FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.io_operational_cross_evidence TO authenticated;
