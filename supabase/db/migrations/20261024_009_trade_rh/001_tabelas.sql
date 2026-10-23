-- Migration 20261024_009_trade_rh — GERADA por scripts/unificacao/gerar_migrations.py. Não editar à mão:
-- ajuste o gerador e gere de novo. Origem: schema.json de produção (2026-10-21/22).

-- crm.acompanhamentos
CREATE TABLE public.trade_acompanhamentos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  mes text,
  promotor_nome text,
  realizou boolean DEFAULT false,
  loja_nome text,
  arquivo text,
  origem text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.trade_acompanhamentos IS 'Origem: crm.acompanhamentos (PocketBase). Dono: crm/trade.';
CREATE TRIGGER trg_trade_acompanhamentos_atualizado_em BEFORE UPDATE ON public.trade_acompanhamentos FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX trade_acompanhamentos_promotor_nome_mes_idx ON public.trade_acompanhamentos (promotor_nome, mes);
ALTER TABLE public.trade_acompanhamentos ENABLE ROW LEVEL SECURITY;
CREATE POLICY trade_acompanhamentos_select ON public.trade_acompanhamentos FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'trade', 'visualizar')));
CREATE POLICY trade_acompanhamentos_insert ON public.trade_acompanhamentos FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'trade', 'criar')));
CREATE POLICY trade_acompanhamentos_update ON public.trade_acompanhamentos FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'trade', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'trade', 'editar')));
CREATE POLICY trade_acompanhamentos_delete ON public.trade_acompanhamentos FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'trade', 'deletar')));
REVOKE ALL ON TABLE public.trade_acompanhamentos FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.trade_acompanhamentos TO authenticated;

-- crm.conquistas
CREATE TABLE public.trade_conquistas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  numero numeric,
  data timestamptz,
  tipo text,
  promotor_nome text,
  participant_jid text,
  loja_nome text,
  industria_nome text,
  descricao text,
  foto text[],
  status text,
  analista_nome text,
  autorizado_em timestamptz,
  esmeraldas numeric,
  origem text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.trade_conquistas IS 'Origem: crm.conquistas (PocketBase). Dono: crm/trade.';
COMMENT ON COLUMN public.trade_conquistas.tipo IS 'Valores: ponto_extra | aumento_espaco | splash | aumento_pdv | outro';
COMMENT ON COLUMN public.trade_conquistas.status IS 'Valores: aguardando_analise | autorizado | rejeitado';
CREATE TRIGGER trg_trade_conquistas_atualizado_em BEFORE UPDATE ON public.trade_conquistas FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.trade_conquistas ENABLE ROW LEVEL SECURITY;
CREATE POLICY trade_conquistas_select ON public.trade_conquistas FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'trade', 'visualizar')));
CREATE POLICY trade_conquistas_insert ON public.trade_conquistas FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'trade', 'criar')));
CREATE POLICY trade_conquistas_update ON public.trade_conquistas FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'trade', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'trade', 'editar')));
CREATE POLICY trade_conquistas_delete ON public.trade_conquistas FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'trade', 'deletar')));
REVOKE ALL ON TABLE public.trade_conquistas FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.trade_conquistas TO authenticated;

-- crm.gamificacao
CREATE TABLE public.trade_gamificacao (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  participant_jid text,
  nome text,
  esmeraldas numeric,
  nivel numeric,
  titulo text,
  avatar_json jsonb,
  faltas_mes numeric,
  beneficios_suspensos boolean DEFAULT false,
  trimestre text,
  faltas_trimestre numeric,
  qr_faltas numeric,
  pendencias_desconto jsonb,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.trade_gamificacao IS 'Origem: crm.gamificacao (PocketBase). Dono: crm/trade.';
CREATE TRIGGER trg_trade_gamificacao_atualizado_em BEFORE UPDATE ON public.trade_gamificacao FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX trade_gamificacao_participant_jid_uk ON public.trade_gamificacao (participant_jid);
ALTER TABLE public.trade_gamificacao ENABLE ROW LEVEL SECURITY;
CREATE POLICY trade_gamificacao_select ON public.trade_gamificacao FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'trade', 'visualizar')));
CREATE POLICY trade_gamificacao_insert ON public.trade_gamificacao FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'trade', 'criar')));
CREATE POLICY trade_gamificacao_update ON public.trade_gamificacao FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'trade', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'trade', 'editar')));
CREATE POLICY trade_gamificacao_delete ON public.trade_gamificacao FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'trade', 'deletar')));
REVOKE ALL ON TABLE public.trade_gamificacao FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.trade_gamificacao TO authenticated;

-- crm.metricas_pdv
CREATE TABLE public.trade_metricas_pdv (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  data timestamptz,
  loja_nome text,
  promotor_nome text,
  participant_jid text,
  tipo text,
  descricao text,
  foto_recebida boolean DEFAULT false,
  grupo_jid text,
  origem text,
  foto text,
  numero numeric,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.trade_metricas_pdv IS 'Origem: crm.metricas_pdv (PocketBase). Dono: crm/trade.';
COMMENT ON COLUMN public.trade_metricas_pdv.tipo IS 'Valores: splash | ponto_extra | aumento_espaco | negociacao_pdv';
COMMENT ON COLUMN public.trade_metricas_pdv.origem IS 'Valores: whatsapp | manual';
CREATE TRIGGER trg_trade_metricas_pdv_atualizado_em BEFORE UPDATE ON public.trade_metricas_pdv FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX trade_metricas_pdv_loja_nome_idx ON public.trade_metricas_pdv (loja_nome);
CREATE INDEX trade_metricas_pdv_tipo_idx ON public.trade_metricas_pdv (tipo);
ALTER TABLE public.trade_metricas_pdv ENABLE ROW LEVEL SECURITY;
CREATE POLICY trade_metricas_pdv_select ON public.trade_metricas_pdv FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'trade', 'visualizar')));
CREATE POLICY trade_metricas_pdv_insert ON public.trade_metricas_pdv FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'trade', 'criar')));
CREATE POLICY trade_metricas_pdv_update ON public.trade_metricas_pdv FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'trade', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'trade', 'editar')));
CREATE POLICY trade_metricas_pdv_delete ON public.trade_metricas_pdv FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'trade', 'deletar')));
REVOKE ALL ON TABLE public.trade_metricas_pdv FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.trade_metricas_pdv TO authenticated;

-- crm.qr_registros
CREATE TABLE public.rh_qr_registros (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  participant_jid text,
  participant_nome text,
  data timestamptz,
  tipo text,
  hora_texto text,
  horas_calculadas numeric,
  instance_name text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.rh_qr_registros IS 'Origem: crm.qr_registros (PocketBase). Dono: crm/rh.';
COMMENT ON COLUMN public.rh_qr_registros.tipo IS 'Valores: entrada | saida';
CREATE TRIGGER trg_rh_qr_registros_atualizado_em BEFORE UPDATE ON public.rh_qr_registros FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.rh_qr_registros ENABLE ROW LEVEL SECURITY;
CREATE POLICY rh_qr_registros_select ON public.rh_qr_registros FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'rh', 'visualizar')));
CREATE POLICY rh_qr_registros_insert ON public.rh_qr_registros FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'rh', 'criar')));
CREATE POLICY rh_qr_registros_update ON public.rh_qr_registros FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'rh', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'rh', 'editar')));
CREATE POLICY rh_qr_registros_delete ON public.rh_qr_registros FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'rh', 'deletar')));
REVOKE ALL ON TABLE public.rh_qr_registros FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.rh_qr_registros TO authenticated;

-- crm.rh_registros
CREATE TABLE public.rh_registros (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  tipo text,
  promotor uuid REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  promotor_nome text,
  data timestamptz,
  horas numeric,
  descricao text,
  anexo text[],
  status text,
  ocorrencia uuid REFERENCES public.dp_ocorrencias(id) ON DELETE SET NULL,
  registrado_por text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.rh_registros IS 'Origem: crm.rh_registros (PocketBase). Dono: crm/rh.';
COMMENT ON COLUMN public.rh_registros.tipo IS 'Valores: falta | atestado | atraso | saida_ao_vivo | banco_horas | justificativa | ferias | folga | outro';
COMMENT ON COLUMN public.rh_registros.promotor IS 'Relação legada → promotores';
COMMENT ON COLUMN public.rh_registros.status IS 'Valores: pendente | justificado | aprovado | reprovado';
COMMENT ON COLUMN public.rh_registros.ocorrencia IS 'Relação legada → ocorrencias';
CREATE TRIGGER trg_rh_registros_atualizado_em BEFORE UPDATE ON public.rh_registros FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.rh_registros ENABLE ROW LEVEL SECURITY;
CREATE POLICY rh_registros_select ON public.rh_registros FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'rh', 'visualizar')));
CREATE POLICY rh_registros_insert ON public.rh_registros FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'rh', 'criar')));
CREATE POLICY rh_registros_update ON public.rh_registros FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'rh', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'rh', 'editar')));
CREATE POLICY rh_registros_delete ON public.rh_registros FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'rh', 'deletar')));
REVOKE ALL ON TABLE public.rh_registros FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.rh_registros TO authenticated;

-- crm.trocas
CREATE TABLE public.trade_trocas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  numero numeric,
  data timestamptz,
  chat_jid text,
  instance_name text,
  participant_jid text,
  promotor_nome text,
  loja_nome text,
  industria_nome text,
  tipo text,
  itens_json text,
  situacao text,
  status text,
  conferido_por text,
  conferido_em timestamptz,
  conferencia_json text,
  autorizado_em timestamptz,
  midia text[],
  nf_file text,
  descarte_file text,
  nf_descarte_ok boolean DEFAULT false,
  concluida_em timestamptz,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.trade_trocas IS 'Origem: crm.trocas (PocketBase). Dono: crm/trade.';
COMMENT ON COLUMN public.trade_trocas.tipo IS 'Valores: validade | avaria';
COMMENT ON COLUMN public.trade_trocas.status IS 'Valores: aguardando_conferencia | conferida | autorizada | aguardando_descarte | concluida | recusada';
CREATE TRIGGER trg_trade_trocas_atualizado_em BEFORE UPDATE ON public.trade_trocas FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.trade_trocas ENABLE ROW LEVEL SECURITY;
CREATE POLICY trade_trocas_select ON public.trade_trocas FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'trade', 'visualizar')));
CREATE POLICY trade_trocas_insert ON public.trade_trocas FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'trade', 'criar')));
CREATE POLICY trade_trocas_update ON public.trade_trocas FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'trade', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'trade', 'editar')));
CREATE POLICY trade_trocas_delete ON public.trade_trocas FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'trade', 'deletar')));
REVOKE ALL ON TABLE public.trade_trocas FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.trade_trocas TO authenticated;
