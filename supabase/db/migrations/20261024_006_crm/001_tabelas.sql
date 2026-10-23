-- Migration 20261024_006_crm — GERADA por scripts/unificacao/gerar_migrations.py. Não editar à mão:
-- ajuste o gerador e gere de novo. Origem: schema.json de produção (2026-10-21/22).

INSERT INTO public.modulos (system_id, chave, nome)
SELECT s.id, m.chave, m.nome FROM public.systems s
CROSS JOIN (VALUES ('clientes', 'Clientes'), ('comercial', 'Comercial'), ('configuracoes', 'Configurações'), ('ia', 'Assistentes de IA'), ('inteligencia', 'Inteligência comercial'), ('operacao', 'Operação'), ('rh', 'RH'), ('trade', 'Trade (gamificação, PDV, trocas)')) AS m(chave, nome)
WHERE s.slug = 'crm'
ON CONFLICT (system_id, chave) DO UPDATE SET nome = EXCLUDED.nome;

INSERT INTO public.modulo_acoes (modulo_id, chave)
SELECT m.id, a.chave FROM public.modulos m JOIN public.systems s ON s.id = m.system_id
CROSS JOIN (VALUES ('visualizar'), ('criar'), ('editar'), ('deletar')) AS a(chave)
WHERE s.slug = 'crm'
ON CONFLICT (modulo_id, chave) DO NOTHING;

-- crm.ai_templates
CREATE TABLE public.crm_ai_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  slug text,
  name text,
  template text,
  system_prompt text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_ai_templates IS 'Origem: crm.ai_templates (PocketBase). Dono: crm/ia.';
CREATE TRIGGER trg_crm_ai_templates_atualizado_em BEFORE UPDATE ON public.crm_ai_templates FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX crm_ai_templates_slug_uk ON public.crm_ai_templates (slug);
ALTER TABLE public.crm_ai_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_ai_templates_select ON public.crm_ai_templates FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'ia', 'visualizar')));
CREATE POLICY crm_ai_templates_insert ON public.crm_ai_templates FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'ia', 'criar')));
CREATE POLICY crm_ai_templates_update ON public.crm_ai_templates FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'ia', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'ia', 'editar')));
CREATE POLICY crm_ai_templates_delete ON public.crm_ai_templates FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'ia', 'deletar')));
REVOKE ALL ON TABLE public.crm_ai_templates FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_ai_templates TO authenticated;

-- crm.alocacoes_operacao
CREATE TABLE public.crm_alocacoes_operacao (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  promotor uuid REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  promotor_nome text,
  loja_id text,
  loja_nome text,
  loja_rede text,
  cidade text,
  estado text,
  bairro text,
  latitude numeric,
  longitude numeric,
  cliente_nome text,
  marca text,
  modelo_operacional text,
  dias_semana text,
  seg boolean DEFAULT false,
  ter boolean DEFAULT false,
  qua boolean DEFAULT false,
  qui boolean DEFAULT false,
  sex boolean DEFAULT false,
  sab boolean DEFAULT false,
  minutos_por_atendimento numeric,
  horas_semanais numeric,
  minutos_semanais numeric,
  ordem_visita numeric,
  rota_codigo text,
  data_inicio timestamptz,
  data_fim timestamptz,
  status text,
  oportunidade_id text,
  origem_importacao text,
  observacoes text,
  ambiente text,
  chave_idempotencia text,
  dia_semana text,
  minutos_atendimento numeric,
  hora_inicio text,
  hora_fim text,
  cliente_id text,
  industria_id text,
  marca_id text,
  marca_nome text,
  oportunidade_origem text,
  observacao text,
  loja_cnpj text,
  loja_endereco text,
  lote_importacao text,
  minutos_orcados numeric,
  minutos_operacionais_planejados numeric,
  status_dimensionamento text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_alocacoes_operacao IS 'Origem: crm.alocacoes_operacao (PocketBase). Dono: crm/operacao.';
COMMENT ON COLUMN public.crm_alocacoes_operacao.promotor IS 'Relação legada → capacidade_operacional';
COMMENT ON COLUMN public.crm_alocacoes_operacao.modelo_operacional IS 'Valores: ROTEIRISTA | FIXO_EM_LOJA';
COMMENT ON COLUMN public.crm_alocacoes_operacao.status IS 'Valores: ALOCACAO_ATIVA | CARGA_PROPOSTA | INATIVA';
COMMENT ON COLUMN public.crm_alocacoes_operacao.ambiente IS 'Valores: producao | demonstracao';
CREATE TRIGGER trg_crm_alocacoes_operacao_atualizado_em BEFORE UPDATE ON public.crm_alocacoes_operacao FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX crm_alocacoes_operacao_promotor_idx ON public.crm_alocacoes_operacao (promotor);
CREATE INDEX crm_alocacoes_operacao_loja_nome_idx ON public.crm_alocacoes_operacao (loja_nome);
CREATE INDEX crm_alocacoes_operacao_cliente_nome_idx ON public.crm_alocacoes_operacao (cliente_nome);
CREATE INDEX crm_alocacoes_operacao_status_idx ON public.crm_alocacoes_operacao (status);
CREATE INDEX crm_alocacoes_operacao_ambiente_idx ON public.crm_alocacoes_operacao (ambiente);
CREATE INDEX crm_alocacoes_operacao_chave_idempotencia_idx ON public.crm_alocacoes_operacao (chave_idempotencia);
CREATE INDEX crm_alocacoes_operacao_cliente_id_idx ON public.crm_alocacoes_operacao (cliente_id);
ALTER TABLE public.crm_alocacoes_operacao ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_alocacoes_operacao_select ON public.crm_alocacoes_operacao FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'operacao', 'visualizar')));
CREATE POLICY crm_alocacoes_operacao_insert ON public.crm_alocacoes_operacao FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'operacao', 'criar')));
CREATE POLICY crm_alocacoes_operacao_update ON public.crm_alocacoes_operacao FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'operacao', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'operacao', 'editar')));
CREATE POLICY crm_alocacoes_operacao_delete ON public.crm_alocacoes_operacao FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'operacao', 'deletar')));
REVOKE ALL ON TABLE public.crm_alocacoes_operacao FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_alocacoes_operacao TO authenticated;

-- crm.auditoria_homologacao_modelos
CREATE TABLE public.crm_auditoria_homologacao_modelos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  chave_relacao text,
  promotor_nome text,
  loja_nome text,
  valor_anterior text,
  valor_novo text,
  status_anterior text,
  status_novo text,
  usuario text,
  usuario_id text,
  origem_acao text,
  lote_id text,
  observacao text,
  ambiente text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_auditoria_homologacao_modelos IS 'Origem: crm.auditoria_homologacao_modelos (PocketBase). Dono: crm/inteligencia.';
COMMENT ON COLUMN public.crm_auditoria_homologacao_modelos.origem_acao IS 'Valores: INDIVIDUAL | LOTE | SISTEMA';
COMMENT ON COLUMN public.crm_auditoria_homologacao_modelos.ambiente IS 'Valores: producao | demonstracao';
CREATE TRIGGER trg_crm_auditoria_homologacao_modelos_atualizado_em BEFORE UPDATE ON public.crm_auditoria_homologacao_modelos FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX crm_auditoria_homologacao_modelos_chave_relacao_idx ON public.crm_auditoria_homologacao_modelos (chave_relacao);
CREATE INDEX crm_auditoria_homologacao_modelos_promotor_nome_idx ON public.crm_auditoria_homologacao_modelos (promotor_nome);
CREATE INDEX crm_auditoria_homologacao_modelos_criado_em_idx ON public.crm_auditoria_homologacao_modelos (criado_em DESC);
ALTER TABLE public.crm_auditoria_homologacao_modelos ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_auditoria_homologacao_modelos_select ON public.crm_auditoria_homologacao_modelos FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'visualizar')));
CREATE POLICY crm_auditoria_homologacao_modelos_insert ON public.crm_auditoria_homologacao_modelos FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'criar')));
CREATE POLICY crm_auditoria_homologacao_modelos_update ON public.crm_auditoria_homologacao_modelos FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar')));
CREATE POLICY crm_auditoria_homologacao_modelos_delete ON public.crm_auditoria_homologacao_modelos FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'deletar')));
REVOKE ALL ON TABLE public.crm_auditoria_homologacao_modelos FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_auditoria_homologacao_modelos TO authenticated;

-- crm.capacidade_operacional (identidade em colaboradores)
CREATE TABLE public.crm_capacidade_operacional (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  colaborador_id uuid NOT NULL REFERENCES public.colaboradores(id) ON DELETE CASCADE,
  promotor text,
  modalidade_contratacao text,
  regiao text,
  cidade_base text,
  carga_disponivel text,
  clientes_atuais text,
  redes_atendidas text,
  status text,
  cargo text,
  tipo_profissional text,
  modalidade text,
  estado text,
  regiao_operacional text,
  jornada_semanal_contratada numeric,
  jornada_semanal_disponivel numeric,
  jornada_comprometida numeric,
  jornada_livre numeric,
  qtd_lojas_atendidas numeric,
  possui_veiculo boolean DEFAULT false,
  tipo_veiculo text,
  possui_cnh boolean DEFAULT false,
  observacoes text,
  ambiente text,
  origem text,
  origem_usuario uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  origem_data timestamptz,
  entidade_juridica uuid REFERENCES public.empresas_dcg(id) ON DELETE SET NULL,
  modelo_operacional text,
  vinculo_jornada text,
  jornada_diaria_minutos numeric,
  intervalo_almoco_minutos numeric,
  origem_operacional_latitude numeric,
  origem_operacional_longitude numeric,
  origem_operacional_endereco text,
  origem_operacional_cidade text,
  dias_trabalho text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (colaborador_id)
);
COMMENT ON TABLE public.crm_capacidade_operacional IS 'Origem: crm.capacidade_operacional (PocketBase). Dono: crm/operacao.';
COMMENT ON COLUMN public.crm_capacidade_operacional.status IS 'Valores: ativo | inativo';
COMMENT ON COLUMN public.crm_capacidade_operacional.modalidade IS 'Valores: CLT | MEI | Freelancer | Outro';
COMMENT ON COLUMN public.crm_capacidade_operacional.ambiente IS 'Valores: producao | demonstracao';
COMMENT ON COLUMN public.crm_capacidade_operacional.origem IS 'Valores: cadastro_manual | importacao_excel | importacao_csv | migracao | assistente_ia | sistema | demonstracao';
COMMENT ON COLUMN public.crm_capacidade_operacional.origem_usuario IS 'Relação legada → users';
COMMENT ON COLUMN public.crm_capacidade_operacional.entidade_juridica IS 'Relação legada → entidades_juridicas';
COMMENT ON COLUMN public.crm_capacidade_operacional.modelo_operacional IS 'Valores: ROTEIRISTA | FIXO_EM_LOJA';
COMMENT ON COLUMN public.crm_capacidade_operacional.vinculo_jornada IS 'Valores: CLT_INTEGRAL | CLT_HORISTA | MEI_HOMOLOGADO | TEMPORARIO | OUTRO';
CREATE TRIGGER trg_crm_capacidade_operacional_atualizado_em BEFORE UPDATE ON public.crm_capacidade_operacional FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX crm_capacidade_operacional_regiao_idx ON public.crm_capacidade_operacional (regiao);
ALTER TABLE public.crm_capacidade_operacional ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_capacidade_operacional_select ON public.crm_capacidade_operacional FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'operacao', 'visualizar')));
CREATE POLICY crm_capacidade_operacional_insert ON public.crm_capacidade_operacional FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'operacao', 'criar')));
CREATE POLICY crm_capacidade_operacional_update ON public.crm_capacidade_operacional FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'operacao', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'operacao', 'editar')));
CREATE POLICY crm_capacidade_operacional_delete ON public.crm_capacidade_operacional FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'operacao', 'deletar')));
REVOKE ALL ON TABLE public.crm_capacidade_operacional FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_capacidade_operacional TO authenticated;

-- crm.clients (identidade em industrias)
CREATE TABLE public.crm_clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  industria_id uuid NOT NULL REFERENCES public.industrias(id) ON DELETE CASCADE,
  contact_name text,
  email text,
  phone text,
  whatsapp text,
  address text,
  city text,
  state text,
  website text,
  linkedin text,
  notes text,
  status text,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  cep text,
  neighborhood text,
  lead_source text,
  referred_by text,
  ambiente text,
  origem text,
  origem_usuario uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  origem_data timestamptz,
  analista_nome text,
  analista_jid text,
  grupo_jid text,
  segmento text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (industria_id)
);
COMMENT ON TABLE public.crm_clients IS 'Origem: crm.clients (PocketBase). Dono: crm/clientes.';
COMMENT ON COLUMN public.crm_clients.status IS 'Valores: ativo | potencial | inativo';
COMMENT ON COLUMN public.crm_clients.owner IS 'Relação legada → users';
COMMENT ON COLUMN public.crm_clients.lead_source IS 'Valores: Indicação | Instagram | Google | LinkedIn | Feira/Evento | Outros';
COMMENT ON COLUMN public.crm_clients.ambiente IS 'Valores: producao | demonstracao';
COMMENT ON COLUMN public.crm_clients.origem IS 'Valores: cadastro_manual | importacao_excel | importacao_csv | migracao | assistente_ia | sistema | demonstracao';
COMMENT ON COLUMN public.crm_clients.origem_usuario IS 'Relação legada → users';
COMMENT ON COLUMN public.crm_clients.segmento IS 'Valores: pas | mercearia | outro';
CREATE TRIGGER trg_crm_clients_atualizado_em BEFORE UPDATE ON public.crm_clients FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX crm_clients_status_idx ON public.crm_clients (status);
CREATE INDEX crm_clients_criado_em_idx ON public.crm_clients (criado_em DESC);
ALTER TABLE public.crm_clients ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_clients_select ON public.crm_clients FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'clientes', 'visualizar')));
CREATE POLICY crm_clients_insert ON public.crm_clients FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'clientes', 'criar')));
CREATE POLICY crm_clients_update ON public.crm_clients FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'clientes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'clientes', 'editar')));
CREATE POLICY crm_clients_delete ON public.crm_clients FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'clientes', 'deletar')));
REVOKE ALL ON TABLE public.crm_clients FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_clients TO authenticated;

-- crm.configuracoes_empresa
CREATE TABLE public.crm_configuracoes_empresa (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  chave text,
  razao_social text,
  nome_fantasia text,
  cnpj text,
  endereco text,
  cidade text,
  estado text,
  cep text,
  responsavel_legal text,
  contato_email text,
  contato_telefone text,
  prazo_padrao_proposta text,
  condicao_padrao_pagamento text,
  dia_emissao_nf text,
  prazo_padrao_contrato text,
  percentual_impostos numeric,
  percentual_gerenciamento numeric,
  margem_minima_desejada numeric,
  provisao_decimo_terceiro boolean DEFAULT false,
  percentual_provisao_13 numeric,
  programa_comercial_padrao text,
  observacoes_comerciais text,
  modelo_contratual_padrao text,
  modelo_com_provisao_13 text,
  modelo_sem_provisao_13 text,
  regras_gerais_contrato text,
  observacoes_juridicas text,
  ambiente text,
  origem text,
  origem_usuario uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  origem_data timestamptz,
  validacao text,
  entidade_juridica uuid REFERENCES public.empresas_dcg(id) ON DELETE SET NULL,
  fator_mensal numeric,
  tolerancia_aderencia_fort numeric,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_configuracoes_empresa IS 'Origem: crm.configuracoes_empresa (PocketBase). Dono: crm/configuracoes.';
COMMENT ON COLUMN public.crm_configuracoes_empresa.ambiente IS 'Valores: producao | demonstracao';
COMMENT ON COLUMN public.crm_configuracoes_empresa.origem IS 'Valores: cadastro_manual | importacao_excel | importacao_csv | migracao | assistente_ia | sistema | demonstracao';
COMMENT ON COLUMN public.crm_configuracoes_empresa.origem_usuario IS 'Relação legada → users';
COMMENT ON COLUMN public.crm_configuracoes_empresa.validacao IS 'Valores: nao_validado | validado | arquivado';
COMMENT ON COLUMN public.crm_configuracoes_empresa.entidade_juridica IS 'Relação legada → entidades_juridicas';
CREATE TRIGGER trg_crm_configuracoes_empresa_atualizado_em BEFORE UPDATE ON public.crm_configuracoes_empresa FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX crm_configuracoes_empresa_chave_uk ON public.crm_configuracoes_empresa (chave);
ALTER TABLE public.crm_configuracoes_empresa ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_configuracoes_empresa_select ON public.crm_configuracoes_empresa FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'configuracoes', 'visualizar')));
CREATE POLICY crm_configuracoes_empresa_insert ON public.crm_configuracoes_empresa FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'configuracoes', 'criar')));
CREATE POLICY crm_configuracoes_empresa_update ON public.crm_configuracoes_empresa FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'configuracoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'configuracoes', 'editar')));
CREATE POLICY crm_configuracoes_empresa_delete ON public.crm_configuracoes_empresa FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'configuracoes', 'deletar')));
REVOKE ALL ON TABLE public.crm_configuracoes_empresa FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_configuracoes_empresa TO authenticated;

-- crm.deals
CREATE TABLE public.crm_deals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  title text,
  client uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  stage text,
  value numeric,
  probability numeric,
  expected_close_date timestamptz,
  description text,
  reason_lost text,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  ambiente text,
  origem text,
  origem_usuario uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  origem_data timestamptz,
  entidade_juridica uuid REFERENCES public.empresas_dcg(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_deals IS 'Origem: crm.deals (PocketBase). Dono: crm/comercial.';
COMMENT ON COLUMN public.crm_deals.client IS 'Relação legada → clients';
COMMENT ON COLUMN public.crm_deals.stage IS 'Valores: apresentacao | orcamento | aguardando_aceite | contrato | fechado | perdido';
COMMENT ON COLUMN public.crm_deals.owner IS 'Relação legada → users';
COMMENT ON COLUMN public.crm_deals.ambiente IS 'Valores: producao | demonstracao';
COMMENT ON COLUMN public.crm_deals.origem IS 'Valores: cadastro_manual | importacao_excel | importacao_csv | migracao | assistente_ia | sistema | demonstracao';
COMMENT ON COLUMN public.crm_deals.origem_usuario IS 'Relação legada → users';
COMMENT ON COLUMN public.crm_deals.entidade_juridica IS 'Relação legada → entidades_juridicas';
CREATE TRIGGER trg_crm_deals_atualizado_em BEFORE UPDATE ON public.crm_deals FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX crm_deals_stage_idx ON public.crm_deals (stage);
CREATE INDEX crm_deals_client_idx ON public.crm_deals (client);
CREATE INDEX crm_deals_criado_em_idx ON public.crm_deals (criado_em DESC);
ALTER TABLE public.crm_deals ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_deals_select ON public.crm_deals FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'visualizar')) AND public.pode_ver_industria(client));
CREATE POLICY crm_deals_insert ON public.crm_deals FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'comercial', 'criar')));
CREATE POLICY crm_deals_update ON public.crm_deals FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'comercial', 'editar')));
CREATE POLICY crm_deals_delete ON public.crm_deals FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'deletar')));
REVOKE ALL ON TABLE public.crm_deals FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_deals TO authenticated;

-- crm.entidades_juridicas (identidade em empresas_dcg)
CREATE TABLE public.crm_entidades_juridicas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  empresa_id uuid NOT NULL REFERENCES public.empresas_dcg(id) ON DELETE CASCADE,
  inscricao_estadual text,
  endereco text,
  numero text,
  complemento text,
  bairro text,
  cidade text,
  estado text,
  cep text,
  responsavel_legal text,
  cpf_responsavel_legal text,
  email_comercial text,
  email_financeiro text,
  telefone text,
  status text,
  ambiente text,
  validacao text,
  data_inicio_utilizacao timestamptz,
  data_encerramento timestamptz,
  observacoes text,
  origem text,
  origem_usuario uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  origem_data timestamptz,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (empresa_id)
);
COMMENT ON TABLE public.crm_entidades_juridicas IS 'Origem: crm.entidades_juridicas (PocketBase). Dono: crm/configuracoes.';
COMMENT ON COLUMN public.crm_entidades_juridicas.status IS 'Valores: ativo | inativo';
COMMENT ON COLUMN public.crm_entidades_juridicas.ambiente IS 'Valores: producao | demonstracao';
COMMENT ON COLUMN public.crm_entidades_juridicas.validacao IS 'Valores: nao_validado | validado | arquivado';
COMMENT ON COLUMN public.crm_entidades_juridicas.origem IS 'Valores: cadastro_manual | importacao_excel | importacao_csv | migracao | assistente_ia | sistema | demonstracao';
COMMENT ON COLUMN public.crm_entidades_juridicas.origem_usuario IS 'Relação legada → users';
CREATE TRIGGER trg_crm_entidades_juridicas_atualizado_em BEFORE UPDATE ON public.crm_entidades_juridicas FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.crm_entidades_juridicas ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_entidades_juridicas_select ON public.crm_entidades_juridicas FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'configuracoes', 'visualizar')));
CREATE POLICY crm_entidades_juridicas_insert ON public.crm_entidades_juridicas FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'configuracoes', 'criar')));
CREATE POLICY crm_entidades_juridicas_update ON public.crm_entidades_juridicas FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'configuracoes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'configuracoes', 'editar')));
CREATE POLICY crm_entidades_juridicas_delete ON public.crm_entidades_juridicas FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'configuracoes', 'deletar')));
REVOKE ALL ON TABLE public.crm_entidades_juridicas FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_entidades_juridicas TO authenticated;

-- crm.historico_importacoes
CREATE TABLE public.crm_historico_importacoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  usuario uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  tipo text,
  nome_arquivo text,
  total_registros numeric,
  novos numeric,
  atualizados numeric,
  duplicados numeric,
  erros numeric,
  detalhes jsonb,
  ambiente text,
  origem text,
  origem_usuario uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  origem_data timestamptz,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_historico_importacoes IS 'Origem: crm.historico_importacoes (PocketBase). Dono: crm/inteligencia.';
COMMENT ON COLUMN public.crm_historico_importacoes.usuario IS 'Relação legada → users';
COMMENT ON COLUMN public.crm_historico_importacoes.tipo IS 'Valores: redes | lojas | regras | tabela | capacidade';
COMMENT ON COLUMN public.crm_historico_importacoes.ambiente IS 'Valores: producao | demonstracao';
COMMENT ON COLUMN public.crm_historico_importacoes.origem IS 'Valores: cadastro_manual | importacao_excel | importacao_csv | migracao | assistente_ia | sistema | demonstracao';
COMMENT ON COLUMN public.crm_historico_importacoes.origem_usuario IS 'Relação legada → users';
CREATE TRIGGER trg_crm_historico_importacoes_atualizado_em BEFORE UPDATE ON public.crm_historico_importacoes FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX crm_historico_importacoes_criado_em_idx ON public.crm_historico_importacoes (criado_em DESC);
ALTER TABLE public.crm_historico_importacoes ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_historico_importacoes_select ON public.crm_historico_importacoes FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'visualizar')));
CREATE POLICY crm_historico_importacoes_insert ON public.crm_historico_importacoes FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'criar')));
CREATE POLICY crm_historico_importacoes_update ON public.crm_historico_importacoes FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar')));
CREATE POLICY crm_historico_importacoes_delete ON public.crm_historico_importacoes FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'deletar')));
REVOKE ALL ON TABLE public.crm_historico_importacoes FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_historico_importacoes TO authenticated;

-- crm.homologacao_modelos_operacao
CREATE TABLE public.crm_homologacao_modelos_operacao (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  chave_relacao text,
  promotor_nome text,
  promotor_id text,
  loja_nome text,
  loja_id text,
  loja_rede text,
  codigo_loja text,
  cidade text,
  uf text,
  modelo_operacional text,
  status text,
  modelo_sugerido_planilha text,
  observacao text,
  qtd_industrias numeric,
  dias_atendimento text,
  minutos_semanais numeric,
  ambiente text,
  homologado_por text,
  homologado_em timestamptz,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_homologacao_modelos_operacao IS 'Origem: crm.homologacao_modelos_operacao (PocketBase). Dono: crm/inteligencia.';
COMMENT ON COLUMN public.crm_homologacao_modelos_operacao.modelo_operacional IS 'Valores: ROTEIRISTA | FIXO_EM_LOJA | PENDENTE_HOMOLOGACAO';
COMMENT ON COLUMN public.crm_homologacao_modelos_operacao.status IS 'Valores: PENDENTE_HOMOLOGACAO | HOMOLOGADO';
COMMENT ON COLUMN public.crm_homologacao_modelos_operacao.ambiente IS 'Valores: producao | demonstracao';
CREATE TRIGGER trg_crm_homologacao_modelos_operacao_atualizado_em BEFORE UPDATE ON public.crm_homologacao_modelos_operacao FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX crm_homologacao_modelos_operacao_chave_relacao_uk ON public.crm_homologacao_modelos_operacao (chave_relacao);
CREATE INDEX crm_homologacao_modelos_operacao_promotor_nome_idx ON public.crm_homologacao_modelos_operacao (promotor_nome);
CREATE INDEX crm_homologacao_modelos_operacao_loja_nome_idx ON public.crm_homologacao_modelos_operacao (loja_nome);
CREATE INDEX crm_homologacao_modelos_operacao_status_idx ON public.crm_homologacao_modelos_operacao (status);
ALTER TABLE public.crm_homologacao_modelos_operacao ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_homologacao_modelos_operacao_select ON public.crm_homologacao_modelos_operacao FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'visualizar')));
CREATE POLICY crm_homologacao_modelos_operacao_insert ON public.crm_homologacao_modelos_operacao FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'criar')));
CREATE POLICY crm_homologacao_modelos_operacao_update ON public.crm_homologacao_modelos_operacao FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar')));
CREATE POLICY crm_homologacao_modelos_operacao_delete ON public.crm_homologacao_modelos_operacao FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'deletar')));
REVOKE ALL ON TABLE public.crm_homologacao_modelos_operacao FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_homologacao_modelos_operacao TO authenticated;

-- crm.implantacao_plano
CREATE TABLE public.crm_implantacao_plano (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  pendencia text,
  descricao text,
  responsavel text,
  prazo timestamptz,
  status text,
  dependencia text,
  data_concluida timestamptz,
  evidencia text,
  critico boolean DEFAULT false,
  client uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  deal uuid REFERENCES public.crm_deals(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_implantacao_plano IS 'Origem: crm.implantacao_plano (PocketBase). Dono: crm/clientes.';
COMMENT ON COLUMN public.crm_implantacao_plano.status IS 'Valores: pendente | em_andamento | concluido | bloqueado';
COMMENT ON COLUMN public.crm_implantacao_plano.client IS 'Relação legada → clients';
COMMENT ON COLUMN public.crm_implantacao_plano.deal IS 'Relação legada → deals';
CREATE TRIGGER trg_crm_implantacao_plano_atualizado_em BEFORE UPDATE ON public.crm_implantacao_plano FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.crm_implantacao_plano ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_implantacao_plano_select ON public.crm_implantacao_plano FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'clientes', 'visualizar')) AND public.pode_ver_industria(client));
CREATE POLICY crm_implantacao_plano_insert ON public.crm_implantacao_plano FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'clientes', 'criar')));
CREATE POLICY crm_implantacao_plano_update ON public.crm_implantacao_plano FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'clientes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'clientes', 'editar')));
CREATE POLICY crm_implantacao_plano_delete ON public.crm_implantacao_plano FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'clientes', 'deletar')));
REVOKE ALL ON TABLE public.crm_implantacao_plano FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_implantacao_plano TO authenticated;

-- crm.importacoes
CREATE TABLE public.crm_importacoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  nome_arquivo text,
  data_importacao timestamptz,
  usuario uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  oportunidade uuid REFERENCES public.crm_deals(id) ON DELETE SET NULL,
  cliente uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  quantidade_registros numeric,
  quantidade_novos numeric,
  quantidade_duplicados numeric,
  quantidade_incompletos numeric,
  status text,
  ambiente text,
  observacoes text,
  resumo_json jsonb,
  orcamento_original_json jsonb,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_importacoes IS 'Origem: crm.importacoes (PocketBase). Dono: crm/inteligencia.';
COMMENT ON COLUMN public.crm_importacoes.usuario IS 'Relação legada → users';
COMMENT ON COLUMN public.crm_importacoes.oportunidade IS 'Relação legada → deals';
COMMENT ON COLUMN public.crm_importacoes.cliente IS 'Relação legada → clients';
COMMENT ON COLUMN public.crm_importacoes.status IS 'Valores: pendente | validado';
COMMENT ON COLUMN public.crm_importacoes.ambiente IS 'Valores: producao | demonstracao';
CREATE TRIGGER trg_crm_importacoes_atualizado_em BEFORE UPDATE ON public.crm_importacoes FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX crm_importacoes_oportunidade_idx ON public.crm_importacoes (oportunidade);
ALTER TABLE public.crm_importacoes ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_importacoes_select ON public.crm_importacoes FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'visualizar')) AND public.pode_ver_industria(cliente));
CREATE POLICY crm_importacoes_insert ON public.crm_importacoes FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'criar')));
CREATE POLICY crm_importacoes_update ON public.crm_importacoes FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar')));
CREATE POLICY crm_importacoes_delete ON public.crm_importacoes FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'deletar')));
REVOKE ALL ON TABLE public.crm_importacoes FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_importacoes TO authenticated;

-- crm.industrias (identidade em industrias)
CREATE TABLE public.crm_industrias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  industria_id uuid NOT NULL REFERENCES public.industrias(id) ON DELETE CASCADE,
  ativa boolean DEFAULT false,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (industria_id)
);
COMMENT ON TABLE public.crm_industrias IS 'Origem: crm.industrias (PocketBase). Dono: crm/clientes.';
CREATE TRIGGER trg_crm_industrias_atualizado_em BEFORE UPDATE ON public.crm_industrias FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.crm_industrias ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_industrias_select ON public.crm_industrias FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'clientes', 'visualizar')));
CREATE POLICY crm_industrias_insert ON public.crm_industrias FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'clientes', 'criar')));
CREATE POLICY crm_industrias_update ON public.crm_industrias FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'clientes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'clientes', 'editar')));
CREATE POLICY crm_industrias_delete ON public.crm_industrias FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'clientes', 'deletar')));
REVOKE ALL ON TABLE public.crm_industrias FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_industrias TO authenticated;

-- crm.lojas (identidade em lojas)
CREATE TABLE public.crm_lojas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  loja_id uuid NOT NULL REFERENCES public.lojas(id) ON DELETE CASCADE,
  codigo_interno text,
  regiao_operacional text,
  status text,
  codigo_loja_rede text,
  grupo_economico text,
  observacoes text,
  ambiente text,
  origem text,
  origem_usuario uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  origem_data timestamptz,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (loja_id)
);
COMMENT ON TABLE public.crm_lojas IS 'Origem: crm.lojas (PocketBase). Dono: crm/inteligencia.';
COMMENT ON COLUMN public.crm_lojas.status IS 'Valores: ativo | inativo';
COMMENT ON COLUMN public.crm_lojas.ambiente IS 'Valores: producao | demonstracao';
COMMENT ON COLUMN public.crm_lojas.origem IS 'Valores: cadastro_manual | importacao_excel | importacao_csv | migracao | assistente_ia | sistema | demonstracao';
COMMENT ON COLUMN public.crm_lojas.origem_usuario IS 'Relação legada → users';
CREATE TRIGGER trg_crm_lojas_atualizado_em BEFORE UPDATE ON public.crm_lojas FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.crm_lojas ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_lojas_select ON public.crm_lojas FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'visualizar')));
CREATE POLICY crm_lojas_insert ON public.crm_lojas FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'criar')));
CREATE POLICY crm_lojas_update ON public.crm_lojas FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar')));
CREATE POLICY crm_lojas_delete ON public.crm_lojas FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'deletar')));
REVOKE ALL ON TABLE public.crm_lojas FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_lojas TO authenticated;

-- crm.lojas_operacao
CREATE TABLE public.crm_lojas_operacao (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  cliente uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  oportunidade uuid REFERENCES public.crm_deals(id) ON DELETE SET NULL,
  rede text,
  bandeira text,
  nome_loja text,
  cidade text,
  estado text,
  tipo text,
  frequencia_semanal numeric,
  rota text,
  horas_por_atividade numeric,
  horas_mensais numeric,
  minutos_por_visita numeric,
  dias_semana text,
  status text,
  perfil_orcado text,
  requer_moto boolean DEFAULT false,
  fort_compartilhado boolean DEFAULT false,
  observacao text,
  ambiente text,
  validacao text,
  origem_importacao text,
  data_importacao timestamptz,
  fonte_regra_tempo text,
  cnpj_origem text,
  endereco_origem text,
  bairro_origem text,
  seg_fonte text,
  ter_fonte text,
  qua_fonte text,
  qui_fonte text,
  sex_fonte text,
  sab_fonte text,
  observacao_fonte text,
  latitude numeric,
  longitude numeric,
  geocode_status text,
  geocode_confidence text,
  geocode_fonte text,
  geocode_consulta_utilizada text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_lojas_operacao IS 'Origem: crm.lojas_operacao (PocketBase). Dono: crm/inteligencia.';
COMMENT ON COLUMN public.crm_lojas_operacao.cliente IS 'Relação legada → clients';
COMMENT ON COLUMN public.crm_lojas_operacao.oportunidade IS 'Relação legada → deals';
COMMENT ON COLUMN public.crm_lojas_operacao.tipo IS 'Valores: ROTEIRO | FIXO | COMPARTILHADO';
COMMENT ON COLUMN public.crm_lojas_operacao.ambiente IS 'Valores: producao | demonstracao';
COMMENT ON COLUMN public.crm_lojas_operacao.validacao IS 'Valores: importado | validado | pendente';
CREATE TRIGGER trg_crm_lojas_operacao_atualizado_em BEFORE UPDATE ON public.crm_lojas_operacao FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX crm_lojas_operacao_oportunidade_idx ON public.crm_lojas_operacao (oportunidade);
CREATE INDEX crm_lojas_operacao_cliente_idx ON public.crm_lojas_operacao (cliente);
ALTER TABLE public.crm_lojas_operacao ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_lojas_operacao_select ON public.crm_lojas_operacao FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'visualizar')) AND public.pode_ver_industria(cliente));
CREATE POLICY crm_lojas_operacao_insert ON public.crm_lojas_operacao FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'criar')));
CREATE POLICY crm_lojas_operacao_update ON public.crm_lojas_operacao FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar')));
CREATE POLICY crm_lojas_operacao_delete ON public.crm_lojas_operacao FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'deletar')));
REVOKE ALL ON TABLE public.crm_lojas_operacao FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_lojas_operacao TO authenticated;

-- crm.metas_comerciais
CREATE TABLE public.crm_metas_comerciais (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  valor numeric,
  classificacao text,
  tipo_escopo text,
  periodo text,
  mes numeric,
  ano numeric,
  entidade_juridica uuid REFERENCES public.empresas_dcg(id) ON DELETE SET NULL,
  responsavel uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  meta_individual numeric,
  meta_consolidada numeric,
  status text,
  validacao text,
  observacoes text,
  origem text,
  origem_usuario uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  origem_data timestamptz,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_metas_comerciais IS 'Origem: crm.metas_comerciais (PocketBase). Dono: crm/comercial.';
COMMENT ON COLUMN public.crm_metas_comerciais.classificacao IS 'Valores: teste | provisoria | oficial';
COMMENT ON COLUMN public.crm_metas_comerciais.tipo_escopo IS 'Valores: consolidado | individual';
COMMENT ON COLUMN public.crm_metas_comerciais.entidade_juridica IS 'Relação legada → entidades_juridicas';
COMMENT ON COLUMN public.crm_metas_comerciais.responsavel IS 'Relação legada → users';
COMMENT ON COLUMN public.crm_metas_comerciais.origem_usuario IS 'Relação legada → users';
CREATE TRIGGER trg_crm_metas_comerciais_atualizado_em BEFORE UPDATE ON public.crm_metas_comerciais FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.crm_metas_comerciais ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_metas_comerciais_select ON public.crm_metas_comerciais FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'visualizar')));
CREATE POLICY crm_metas_comerciais_insert ON public.crm_metas_comerciais FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'comercial', 'criar')));
CREATE POLICY crm_metas_comerciais_update ON public.crm_metas_comerciais FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'comercial', 'editar')));
CREATE POLICY crm_metas_comerciais_delete ON public.crm_metas_comerciais FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'deletar')));
REVOKE ALL ON TABLE public.crm_metas_comerciais FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_metas_comerciais TO authenticated;

-- crm.necessidades_contratacao
CREATE TABLE public.crm_necessidades_contratacao (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  oportunidade uuid REFERENCES public.crm_deals(id) ON DELETE SET NULL,
  entidade_juridica uuid REFERENCES public.empresas_dcg(id) ON DELETE SET NULL,
  cargo text,
  quantidade numeric,
  regiao text,
  carga_horaria text,
  modalidade text,
  requisitos text,
  status text,
  ambiente text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_necessidades_contratacao IS 'Origem: crm.necessidades_contratacao (PocketBase). Dono: crm/operacao.';
COMMENT ON COLUMN public.crm_necessidades_contratacao.oportunidade IS 'Relação legada → deals';
COMMENT ON COLUMN public.crm_necessidades_contratacao.entidade_juridica IS 'Relação legada → entidades_juridicas';
COMMENT ON COLUMN public.crm_necessidades_contratacao.status IS 'Valores: a_contratar | contratado';
COMMENT ON COLUMN public.crm_necessidades_contratacao.ambiente IS 'Valores: producao | demonstracao';
CREATE TRIGGER trg_crm_necessidades_contratacao_atualizado_em BEFORE UPDATE ON public.crm_necessidades_contratacao FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX crm_necessidades_contratacao_oportunidade_idx ON public.crm_necessidades_contratacao (oportunidade);
ALTER TABLE public.crm_necessidades_contratacao ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_necessidades_contratacao_select ON public.crm_necessidades_contratacao FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'operacao', 'visualizar')));
CREATE POLICY crm_necessidades_contratacao_insert ON public.crm_necessidades_contratacao FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'operacao', 'criar')));
CREATE POLICY crm_necessidades_contratacao_update ON public.crm_necessidades_contratacao FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'operacao', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'operacao', 'editar')));
CREATE POLICY crm_necessidades_contratacao_delete ON public.crm_necessidades_contratacao FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'operacao', 'deletar')));
REVOKE ALL ON TABLE public.crm_necessidades_contratacao FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_necessidades_contratacao TO authenticated;

-- crm.onboarding_itens
CREATE TABLE public.crm_onboarding_itens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  categoria text,
  item text,
  responsavel text,
  prazo timestamptz,
  status text,
  evidencia text,
  client uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  deal uuid REFERENCES public.crm_deals(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_onboarding_itens IS 'Origem: crm.onboarding_itens (PocketBase). Dono: crm/clientes.';
COMMENT ON COLUMN public.crm_onboarding_itens.categoria IS 'Valores: lojas | produtos | acessos | materiais | regras | contatos | comunicacao | indicadores | treinamento';
COMMENT ON COLUMN public.crm_onboarding_itens.status IS 'Valores: pendente | ok | nao_se_aplica';
COMMENT ON COLUMN public.crm_onboarding_itens.client IS 'Relação legada → clients';
COMMENT ON COLUMN public.crm_onboarding_itens.deal IS 'Relação legada → deals';
CREATE TRIGGER trg_crm_onboarding_itens_atualizado_em BEFORE UPDATE ON public.crm_onboarding_itens FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.crm_onboarding_itens ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_onboarding_itens_select ON public.crm_onboarding_itens FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'clientes', 'visualizar')) AND public.pode_ver_industria(client));
CREATE POLICY crm_onboarding_itens_insert ON public.crm_onboarding_itens FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'clientes', 'criar')));
CREATE POLICY crm_onboarding_itens_update ON public.crm_onboarding_itens FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'clientes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'clientes', 'editar')));
CREATE POLICY crm_onboarding_itens_delete ON public.crm_onboarding_itens FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'clientes', 'deletar')));
REVOKE ALL ON TABLE public.crm_onboarding_itens FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_onboarding_itens TO authenticated;

-- crm.pesquisa_lojas
CREATE TABLE public.crm_pesquisa_lojas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  rede text,
  uf text,
  loja text,
  cnpj text,
  endereco text,
  cidade text,
  fonte text,
  validacao text,
  observacao text,
  client uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  deal uuid REFERENCES public.crm_deals(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_pesquisa_lojas IS 'Origem: crm.pesquisa_lojas (PocketBase). Dono: crm/clientes.';
COMMENT ON COLUMN public.crm_pesquisa_lojas.validacao IS 'Valores: ok | pendente_validacao';
COMMENT ON COLUMN public.crm_pesquisa_lojas.client IS 'Relação legada → clients';
COMMENT ON COLUMN public.crm_pesquisa_lojas.deal IS 'Relação legada → deals';
CREATE TRIGGER trg_crm_pesquisa_lojas_atualizado_em BEFORE UPDATE ON public.crm_pesquisa_lojas FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.crm_pesquisa_lojas ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_pesquisa_lojas_select ON public.crm_pesquisa_lojas FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'clientes', 'visualizar')) AND public.pode_ver_industria(client));
CREATE POLICY crm_pesquisa_lojas_insert ON public.crm_pesquisa_lojas FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'clientes', 'criar')));
CREATE POLICY crm_pesquisa_lojas_update ON public.crm_pesquisa_lojas FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'clientes', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'clientes', 'editar')));
CREATE POLICY crm_pesquisa_lojas_delete ON public.crm_pesquisa_lojas FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'clientes', 'deletar')));
REVOKE ALL ON TABLE public.crm_pesquisa_lojas FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_pesquisa_lojas TO authenticated;

-- crm.presentations
CREATE TABLE public.crm_presentations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  client uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  deal uuid REFERENCES public.crm_deals(id) ON DELETE SET NULL,
  title text,
  slides jsonb,
  status text,
  ambiente text,
  origem text,
  origem_usuario uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  origem_data timestamptz,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_presentations IS 'Origem: crm.presentations (PocketBase). Dono: crm/comercial.';
COMMENT ON COLUMN public.crm_presentations.client IS 'Relação legada → clients';
COMMENT ON COLUMN public.crm_presentations.deal IS 'Relação legada → deals';
COMMENT ON COLUMN public.crm_presentations.status IS 'Valores: rascunho | revisado | aprovado | apresentado';
COMMENT ON COLUMN public.crm_presentations.ambiente IS 'Valores: producao | demonstracao';
COMMENT ON COLUMN public.crm_presentations.origem IS 'Valores: cadastro_manual | importacao_excel | importacao_csv | migracao | assistente_ia | sistema | demonstracao';
COMMENT ON COLUMN public.crm_presentations.origem_usuario IS 'Relação legada → users';
CREATE TRIGGER trg_crm_presentations_atualizado_em BEFORE UPDATE ON public.crm_presentations FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX crm_presentations_client_idx ON public.crm_presentations (client);
CREATE INDEX crm_presentations_deal_idx ON public.crm_presentations (deal);
CREATE INDEX crm_presentations_criado_em_idx ON public.crm_presentations (criado_em DESC);
ALTER TABLE public.crm_presentations ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_presentations_select ON public.crm_presentations FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'visualizar')) AND public.pode_ver_industria(client));
CREATE POLICY crm_presentations_insert ON public.crm_presentations FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'comercial', 'criar')));
CREATE POLICY crm_presentations_update ON public.crm_presentations FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'comercial', 'editar')));
CREATE POLICY crm_presentations_delete ON public.crm_presentations FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'deletar')));
REVOKE ALL ON TABLE public.crm_presentations FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_presentations TO authenticated;

-- crm.promotores (identidade em colaboradores)
CREATE TABLE public.crm_promotores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  colaborador_id uuid NOT NULL REFERENCES public.colaboradores(id) ON DELETE CASCADE,
  ativo boolean DEFAULT false,
  industria_id uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  valor_bonificacao numeric,
  kpis_json jsonb,
  salario numeric,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (colaborador_id)
);
COMMENT ON TABLE public.crm_promotores IS 'Origem: crm.promotores (PocketBase). Dono: crm/operacao.';
COMMENT ON COLUMN public.crm_promotores.industria_id IS 'Relação legada → industrias';
CREATE TRIGGER trg_crm_promotores_atualizado_em BEFORE UPDATE ON public.crm_promotores FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.crm_promotores ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_promotores_select ON public.crm_promotores FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'operacao', 'visualizar')) AND public.pode_ver_industria(industria_id));
CREATE POLICY crm_promotores_insert ON public.crm_promotores FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'operacao', 'criar')));
CREATE POLICY crm_promotores_update ON public.crm_promotores FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'operacao', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'operacao', 'editar')));
CREATE POLICY crm_promotores_delete ON public.crm_promotores FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'operacao', 'deletar')));
REVOKE ALL ON TABLE public.crm_promotores FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_promotores TO authenticated;

-- crm.proposals
CREATE TABLE public.crm_proposals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  deal uuid REFERENCES public.crm_deals(id) ON DELETE SET NULL,
  client uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  title text,
  introduction text,
  scope text,
  items jsonb,
  payment_terms text,
  validity text,
  total_value numeric,
  status text,
  file text,
  plano_presenca_pdv boolean DEFAULT false,
  valor_presenca_pdv numeric,
  plano_controle_pdv boolean DEFAULT false,
  valor_controle_pdv numeric,
  plano_performance_pdv boolean DEFAULT false,
  valor_performance_pdv numeric,
  inteligencia_operacional boolean DEFAULT false,
  valor_inteligencia_operacional numeric,
  aceite_presenca_pdv boolean DEFAULT false,
  aceite_controle_pdv boolean DEFAULT false,
  aceite_performance_pdv boolean DEFAULT false,
  aceite_inteligencia_operacional boolean DEFAULT false,
  valor_aceito numeric,
  valor_hora_presenca_pdv numeric,
  horas_presenca_pdv numeric,
  minutos_presenca_pdv numeric,
  valor_hora_controle_pdv numeric,
  horas_controle_pdv numeric,
  minutos_controle_pdv numeric,
  valor_hora_performance_pdv numeric,
  horas_performance_pdv numeric,
  minutos_performance_pdv numeric,
  ambiente text,
  origem text,
  origem_usuario uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  origem_data timestamptz,
  entidade_juridica uuid REFERENCES public.empresas_dcg(id) ON DELETE SET NULL,
  tratamento_13o text,
  versao numeric,
  historico_negociacao jsonb,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_proposals IS 'Origem: crm.proposals (PocketBase). Dono: crm/comercial.';
COMMENT ON COLUMN public.crm_proposals.deal IS 'Relação legada → deals';
COMMENT ON COLUMN public.crm_proposals.client IS 'Relação legada → clients';
COMMENT ON COLUMN public.crm_proposals.status IS 'Valores: rascunho | enviado | aprovado | recusado';
COMMENT ON COLUMN public.crm_proposals.ambiente IS 'Valores: producao | demonstracao';
COMMENT ON COLUMN public.crm_proposals.origem IS 'Valores: cadastro_manual | importacao_excel | importacao_csv | migracao | assistente_ia | sistema | demonstracao';
COMMENT ON COLUMN public.crm_proposals.origem_usuario IS 'Relação legada → users';
COMMENT ON COLUMN public.crm_proposals.entidade_juridica IS 'Relação legada → entidades_juridicas';
COMMENT ON COLUMN public.crm_proposals.tratamento_13o IS 'Valores: com_13o | sem_13o';
CREATE TRIGGER trg_crm_proposals_atualizado_em BEFORE UPDATE ON public.crm_proposals FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX crm_proposals_deal_idx ON public.crm_proposals (deal);
CREATE INDEX crm_proposals_client_idx ON public.crm_proposals (client);
CREATE INDEX crm_proposals_status_idx ON public.crm_proposals (status);
CREATE INDEX crm_proposals_criado_em_idx ON public.crm_proposals (criado_em DESC);
ALTER TABLE public.crm_proposals ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_proposals_select ON public.crm_proposals FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'visualizar')) AND public.pode_ver_industria(client));
CREATE POLICY crm_proposals_insert ON public.crm_proposals FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'comercial', 'criar')));
CREATE POLICY crm_proposals_update ON public.crm_proposals FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'comercial', 'editar')));
CREATE POLICY crm_proposals_delete ON public.crm_proposals FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'deletar')));
REVOKE ALL ON TABLE public.crm_proposals FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_proposals TO authenticated;

-- crm.redes (identidade em redes)
CREATE TABLE public.crm_redes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  rede_id uuid NOT NULL REFERENCES public.redes(id) ON DELETE CASCADE,
  estado text,
  tipo_rede text,
  observacoes text,
  status text,
  grupo_economico text,
  abrangencia text,
  ambiente text,
  origem text,
  origem_usuario uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  origem_data timestamptz,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (rede_id)
);
COMMENT ON TABLE public.crm_redes IS 'Origem: crm.redes (PocketBase). Dono: crm/inteligencia.';
COMMENT ON COLUMN public.crm_redes.status IS 'Valores: ativo | inativo';
COMMENT ON COLUMN public.crm_redes.ambiente IS 'Valores: producao | demonstracao';
COMMENT ON COLUMN public.crm_redes.origem IS 'Valores: cadastro_manual | importacao_excel | importacao_csv | migracao | assistente_ia | sistema | demonstracao';
COMMENT ON COLUMN public.crm_redes.origem_usuario IS 'Relação legada → users';
CREATE TRIGGER trg_crm_redes_atualizado_em BEFORE UPDATE ON public.crm_redes FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.crm_redes ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_redes_select ON public.crm_redes FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'visualizar')));
CREATE POLICY crm_redes_insert ON public.crm_redes FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'criar')));
CREATE POLICY crm_redes_update ON public.crm_redes FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar')));
CREATE POLICY crm_redes_delete ON public.crm_redes FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'deletar')));
REVOKE ALL ON TABLE public.crm_redes FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_redes TO authenticated;

-- crm.regras_operacionais
CREATE TABLE public.crm_regras_operacionais (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  rede uuid REFERENCES public.redes(id) ON DELETE SET NULL,
  estado text,
  tipo_regra text,
  descricao text,
  modalidade_contratacao text,
  clt_obrigatorio boolean DEFAULT false,
  mei_permitido boolean DEFAULT false,
  tempo_minimo_atendimento text,
  observacoes text,
  data_inicio_validade timestamptz,
  data_fim_validade timestamptz,
  status text,
  regiao text,
  categoria_regra text,
  nome_regra text,
  terceirizado_permitido boolean DEFAULT false,
  tempo_minimo_minutos numeric,
  frequencia_minima text,
  qtd_minima_visitas numeric,
  restricao_operacional text,
  observacao_comercial text,
  observacao_interna text,
  versao numeric,
  regra_pai_id text,
  motivo_alteracao text,
  cliente uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  ambiente text,
  origem text,
  origem_usuario uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  origem_data timestamptz,
  validacao text,
  nivel text,
  rede_nome text,
  regra_json jsonb,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_regras_operacionais IS 'Origem: crm.regras_operacionais (PocketBase). Dono: crm/inteligencia.';
COMMENT ON COLUMN public.crm_regras_operacionais.rede IS 'Relação legada → redes';
COMMENT ON COLUMN public.crm_regras_operacionais.status IS 'Valores: ativo | inativo';
COMMENT ON COLUMN public.crm_regras_operacionais.cliente IS 'Relação legada → clients';
COMMENT ON COLUMN public.crm_regras_operacionais.ambiente IS 'Valores: producao | demonstracao';
COMMENT ON COLUMN public.crm_regras_operacionais.origem IS 'Valores: cadastro_manual | importacao_excel | importacao_csv | migracao | assistente_ia | sistema | demonstracao';
COMMENT ON COLUMN public.crm_regras_operacionais.origem_usuario IS 'Relação legada → users';
COMMENT ON COLUMN public.crm_regras_operacionais.validacao IS 'Valores: nao_validado | validado | arquivado';
COMMENT ON COLUMN public.crm_regras_operacionais.nivel IS 'Valores: cliente | rede | geral';
CREATE TRIGGER trg_crm_regras_operacionais_atualizado_em BEFORE UPDATE ON public.crm_regras_operacionais FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX crm_regras_operacionais_rede_idx ON public.crm_regras_operacionais (rede);
ALTER TABLE public.crm_regras_operacionais ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_regras_operacionais_select ON public.crm_regras_operacionais FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'visualizar')) AND public.pode_ver_industria(cliente));
CREATE POLICY crm_regras_operacionais_insert ON public.crm_regras_operacionais FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'criar')));
CREATE POLICY crm_regras_operacionais_update ON public.crm_regras_operacionais FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar')));
CREATE POLICY crm_regras_operacionais_delete ON public.crm_regras_operacionais FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'deletar')));
REVOKE ALL ON TABLE public.crm_regras_operacionais FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_regras_operacionais TO authenticated;

-- crm.tabela_comercial
CREATE TABLE public.crm_tabela_comercial (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  nome_programa text,
  valor numeric,
  unidade_cobranca text,
  estado text,
  rede uuid REFERENCES public.redes(id) ON DELETE SET NULL,
  data_inicio_vigencia timestamptz,
  data_fim_vigencia timestamptz,
  status text,
  descricao text,
  valor_minimo numeric,
  valor_por_hora numeric,
  valor_por_visita numeric,
  valor_por_loja numeric,
  valor_mensal numeric,
  cliente uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  regiao text,
  observacoes text,
  versao numeric,
  tabela_pai_id text,
  valor_anterior numeric,
  motivo_alteracao text,
  ambiente text,
  origem text,
  origem_usuario uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  origem_data timestamptz,
  validacao text,
  entidade_juridica uuid REFERENCES public.empresas_dcg(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_tabela_comercial IS 'Origem: crm.tabela_comercial (PocketBase). Dono: crm/inteligencia.';
COMMENT ON COLUMN public.crm_tabela_comercial.rede IS 'Relação legada → redes';
COMMENT ON COLUMN public.crm_tabela_comercial.status IS 'Valores: ativo | inativo';
COMMENT ON COLUMN public.crm_tabela_comercial.cliente IS 'Relação legada → clients';
COMMENT ON COLUMN public.crm_tabela_comercial.ambiente IS 'Valores: producao | demonstracao';
COMMENT ON COLUMN public.crm_tabela_comercial.origem IS 'Valores: cadastro_manual | importacao_excel | importacao_csv | migracao | assistente_ia | sistema | demonstracao';
COMMENT ON COLUMN public.crm_tabela_comercial.origem_usuario IS 'Relação legada → users';
COMMENT ON COLUMN public.crm_tabela_comercial.validacao IS 'Valores: nao_validado | validado | arquivado';
COMMENT ON COLUMN public.crm_tabela_comercial.entidade_juridica IS 'Relação legada → entidades_juridicas';
CREATE TRIGGER trg_crm_tabela_comercial_atualizado_em BEFORE UPDATE ON public.crm_tabela_comercial FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX crm_tabela_comercial_nome_programa_idx ON public.crm_tabela_comercial (nome_programa);
ALTER TABLE public.crm_tabela_comercial ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_tabela_comercial_select ON public.crm_tabela_comercial FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'visualizar')) AND public.pode_ver_industria(cliente));
CREATE POLICY crm_tabela_comercial_insert ON public.crm_tabela_comercial FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'criar')));
CREATE POLICY crm_tabela_comercial_update ON public.crm_tabela_comercial FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'editar')));
CREATE POLICY crm_tabela_comercial_delete ON public.crm_tabela_comercial FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'inteligencia', 'deletar')));
REVOKE ALL ON TABLE public.crm_tabela_comercial FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_tabela_comercial TO authenticated;

-- crm.tempo_operacional
CREATE TABLE public.crm_tempo_operacional (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  loja uuid REFERENCES public.crm_lojas_operacao(id) ON DELETE SET NULL,
  data timestamptz,
  dia_semana text,
  minutos_planejados numeric,
  horario_entrada text,
  horario_saida text,
  minutos_realizados numeric,
  diferenca_minutos numeric,
  aderencia_percentual numeric,
  status_aderencia text,
  tolerancia_percentual numeric,
  ambiente text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_tempo_operacional IS 'Origem: crm.tempo_operacional (PocketBase). Dono: crm/operacao.';
COMMENT ON COLUMN public.crm_tempo_operacional.loja IS 'Relação legada → lojas_operacao';
COMMENT ON COLUMN public.crm_tempo_operacional.status_aderencia IS 'Valores: conforme | atencao | nao_conforme';
COMMENT ON COLUMN public.crm_tempo_operacional.ambiente IS 'Valores: producao | demonstracao';
CREATE TRIGGER trg_crm_tempo_operacional_atualizado_em BEFORE UPDATE ON public.crm_tempo_operacional FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX crm_tempo_operacional_loja_idx ON public.crm_tempo_operacional (loja);
ALTER TABLE public.crm_tempo_operacional ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_tempo_operacional_select ON public.crm_tempo_operacional FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'operacao', 'visualizar')));
CREATE POLICY crm_tempo_operacional_insert ON public.crm_tempo_operacional FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'operacao', 'criar')));
CREATE POLICY crm_tempo_operacional_update ON public.crm_tempo_operacional FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'operacao', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'operacao', 'editar')));
CREATE POLICY crm_tempo_operacional_delete ON public.crm_tempo_operacional FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'operacao', 'deletar')));
REVOKE ALL ON TABLE public.crm_tempo_operacional FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_tempo_operacional TO authenticated;

-- crm.contracts
CREATE TABLE public.crm_contracts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  client uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  deal uuid REFERENCES public.crm_deals(id) ON DELETE SET NULL,
  proposal uuid REFERENCES public.crm_proposals(id) ON DELETE SET NULL,
  title text,
  contract_type text,
  clauses text,
  start_date timestamptz,
  end_date timestamptz,
  value numeric,
  status text,
  file text,
  attachments text[],
  ambiente text,
  origem text,
  origem_usuario uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  origem_data timestamptz,
  entidade_juridica uuid REFERENCES public.empresas_dcg(id) ON DELETE SET NULL,
  tratamento_13o text,
  assinado boolean DEFAULT false,
  data_assinatura timestamptz,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_contracts IS 'Origem: crm.contracts (PocketBase). Dono: crm/comercial.';
COMMENT ON COLUMN public.crm_contracts.client IS 'Relação legada → clients';
COMMENT ON COLUMN public.crm_contracts.deal IS 'Relação legada → deals';
COMMENT ON COLUMN public.crm_contracts.proposal IS 'Relação legada → proposals';
COMMENT ON COLUMN public.crm_contracts.contract_type IS 'Valores: prestacao_servico | consultoria | evento';
COMMENT ON COLUMN public.crm_contracts.status IS 'Valores: rascunho | pendente_assinatura | assinado | ativo | encerrado';
COMMENT ON COLUMN public.crm_contracts.ambiente IS 'Valores: producao | demonstracao';
COMMENT ON COLUMN public.crm_contracts.origem IS 'Valores: cadastro_manual | importacao_excel | importacao_csv | migracao | assistente_ia | sistema | demonstracao';
COMMENT ON COLUMN public.crm_contracts.origem_usuario IS 'Relação legada → users';
COMMENT ON COLUMN public.crm_contracts.entidade_juridica IS 'Relação legada → entidades_juridicas';
COMMENT ON COLUMN public.crm_contracts.tratamento_13o IS 'Valores: com_13o | sem_13o';
CREATE TRIGGER trg_crm_contracts_atualizado_em BEFORE UPDATE ON public.crm_contracts FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX crm_contracts_client_idx ON public.crm_contracts (client);
CREATE INDEX crm_contracts_deal_idx ON public.crm_contracts (deal);
CREATE INDEX crm_contracts_status_idx ON public.crm_contracts (status);
CREATE INDEX crm_contracts_criado_em_idx ON public.crm_contracts (criado_em DESC);
ALTER TABLE public.crm_contracts ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_contracts_select ON public.crm_contracts FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'visualizar')) AND public.pode_ver_industria(client));
CREATE POLICY crm_contracts_insert ON public.crm_contracts FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'comercial', 'criar')));
CREATE POLICY crm_contracts_update ON public.crm_contracts FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'comercial', 'editar')));
CREATE POLICY crm_contracts_delete ON public.crm_contracts FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'deletar')));
REVOKE ALL ON TABLE public.crm_contracts FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_contracts TO authenticated;

-- crm.historico_ia
CREATE TABLE public.crm_historico_ia (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  usuario uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  agente text,
  acao text,
  alteracao_realizada text,
  valor_anterior text,
  valor_novo text,
  cliente uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  negocio uuid REFERENCES public.crm_deals(id) ON DELETE SET NULL,
  orcamento uuid REFERENCES public.crm_proposals(id) ON DELETE SET NULL,
  contrato uuid REFERENCES public.crm_contracts(id) ON DELETE SET NULL,
  apresentacao uuid REFERENCES public.crm_presentations(id) ON DELETE SET NULL,
  metadados jsonb,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_historico_ia IS 'Origem: crm.historico_ia (PocketBase). Dono: crm/ia.';
COMMENT ON COLUMN public.crm_historico_ia.usuario IS 'Relação legada → users';
COMMENT ON COLUMN public.crm_historico_ia.cliente IS 'Relação legada → clients';
COMMENT ON COLUMN public.crm_historico_ia.negocio IS 'Relação legada → deals';
COMMENT ON COLUMN public.crm_historico_ia.orcamento IS 'Relação legada → proposals';
COMMENT ON COLUMN public.crm_historico_ia.contrato IS 'Relação legada → contracts';
COMMENT ON COLUMN public.crm_historico_ia.apresentacao IS 'Relação legada → presentations';
CREATE TRIGGER trg_crm_historico_ia_atualizado_em BEFORE UPDATE ON public.crm_historico_ia FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX crm_historico_ia_acao_idx ON public.crm_historico_ia (acao);
CREATE INDEX crm_historico_ia_cliente_idx ON public.crm_historico_ia (cliente);
CREATE INDEX crm_historico_ia_negocio_idx ON public.crm_historico_ia (negocio);
CREATE INDEX crm_historico_ia_criado_em_idx ON public.crm_historico_ia (criado_em DESC);
ALTER TABLE public.crm_historico_ia ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_historico_ia_select ON public.crm_historico_ia FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'ia', 'visualizar')) AND public.pode_ver_industria(cliente));
CREATE POLICY crm_historico_ia_insert ON public.crm_historico_ia FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'ia', 'criar')));
CREATE POLICY crm_historico_ia_update ON public.crm_historico_ia FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'ia', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'ia', 'editar')));
CREATE POLICY crm_historico_ia_delete ON public.crm_historico_ia FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'ia', 'deletar')));
REVOKE ALL ON TABLE public.crm_historico_ia FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_historico_ia TO authenticated;

-- crm.orcamento_versoes
CREATE TABLE public.crm_orcamento_versoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  versao numeric,
  titulo text,
  valor numeric,
  status text,
  solicitado_por text,
  motivo text,
  proposal uuid REFERENCES public.crm_proposals(id) ON DELETE SET NULL,
  criado_por uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.crm_orcamento_versoes IS 'Origem: crm.orcamento_versoes (PocketBase). Dono: crm/comercial.';
COMMENT ON COLUMN public.crm_orcamento_versoes.status IS 'Valores: proposto | negociado | aprovado';
COMMENT ON COLUMN public.crm_orcamento_versoes.proposal IS 'Relação legada → proposals';
COMMENT ON COLUMN public.crm_orcamento_versoes.criado_por IS 'Relação legada → users';
CREATE TRIGGER trg_crm_orcamento_versoes_atualizado_em BEFORE UPDATE ON public.crm_orcamento_versoes FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.crm_orcamento_versoes ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_orcamento_versoes_select ON public.crm_orcamento_versoes FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'visualizar')));
CREATE POLICY crm_orcamento_versoes_insert ON public.crm_orcamento_versoes FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('crm', 'comercial', 'criar')));
CREATE POLICY crm_orcamento_versoes_update ON public.crm_orcamento_versoes FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('crm', 'comercial', 'editar')));
CREATE POLICY crm_orcamento_versoes_delete ON public.crm_orcamento_versoes FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('crm', 'comercial', 'deletar')));
REVOKE ALL ON TABLE public.crm_orcamento_versoes FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.crm_orcamento_versoes TO authenticated;
