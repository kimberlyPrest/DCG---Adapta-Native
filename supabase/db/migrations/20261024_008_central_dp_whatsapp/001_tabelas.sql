-- Migration 20261024_008_central_dp_whatsapp — GERADA por scripts/unificacao/gerar_migrations.py. Não editar à mão:
-- ajuste o gerador e gere de novo. Origem: schema.json de produção (2026-10-21/22).

INSERT INTO public.modulos (system_id, chave, nome)
SELECT s.id, m.chave, m.nome FROM public.systems s
CROSS JOIN (VALUES ('ocorrencias', 'Ocorrências'), ('whatsapp', 'WhatsApp')) AS m(chave, nome)
WHERE s.slug = 'hub'
ON CONFLICT (system_id, chave) DO UPDATE SET nome = EXCLUDED.nome;

INSERT INTO public.modulo_acoes (modulo_id, chave)
SELECT m.id, a.chave FROM public.modulos m JOIN public.systems s ON s.id = m.system_id
CROSS JOIN (VALUES ('visualizar'), ('criar'), ('editar'), ('deletar')) AS a(chave)
WHERE s.slug = 'hub'
ON CONFLICT (modulo_id, chave) DO NOTHING;

-- crm.bot_config_grupos
CREATE TABLE public.wa_bot_config_grupos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  instance_name text,
  remote_jid text,
  grupo_nome text,
  modulo text,
  ativo boolean DEFAULT false,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.wa_bot_config_grupos IS 'Origem: crm.bot_config_grupos (PocketBase). Dono: hub/whatsapp.';
COMMENT ON COLUMN public.wa_bot_config_grupos.modulo IS 'Valores: ocorrencias | pontos_extras | trocas | menu | avisos | qr_code';
CREATE TRIGGER trg_wa_bot_config_grupos_atualizado_em BEFORE UPDATE ON public.wa_bot_config_grupos FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX wa_bot_config_grupos_instance_name_remote_jid_uk ON public.wa_bot_config_grupos (instance_name, remote_jid);
ALTER TABLE public.wa_bot_config_grupos ENABLE ROW LEVEL SECURITY;
CREATE POLICY wa_bot_config_grupos_select ON public.wa_bot_config_grupos FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'visualizar')));
CREATE POLICY wa_bot_config_grupos_insert ON public.wa_bot_config_grupos FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'criar')));
CREATE POLICY wa_bot_config_grupos_update ON public.wa_bot_config_grupos FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'editar')));
CREATE POLICY wa_bot_config_grupos_delete ON public.wa_bot_config_grupos FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'deletar')));
REVOKE ALL ON TABLE public.wa_bot_config_grupos FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.wa_bot_config_grupos TO authenticated;

-- crm.bot_sessoes
CREATE TABLE public.wa_bot_sessoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  chat_jid text,
  participant_jid text,
  participant_nome text,
  instance_name text,
  modulo text,
  step numeric,
  dados jsonb,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.wa_bot_sessoes IS 'Origem: crm.bot_sessoes (PocketBase). Dono: hub/whatsapp.';
COMMENT ON COLUMN public.wa_bot_sessoes.modulo IS 'Valores: ocorrencias | pontos_extras | menu | nome | ativacoes | trocas';
CREATE TRIGGER trg_wa_bot_sessoes_atualizado_em BEFORE UPDATE ON public.wa_bot_sessoes FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX wa_bot_sessoes_chat_jid_participant_jid_uk ON public.wa_bot_sessoes (chat_jid, participant_jid);
ALTER TABLE public.wa_bot_sessoes ENABLE ROW LEVEL SECURITY;
CREATE POLICY wa_bot_sessoes_select ON public.wa_bot_sessoes FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'visualizar')));
CREATE POLICY wa_bot_sessoes_insert ON public.wa_bot_sessoes FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'criar')));
CREATE POLICY wa_bot_sessoes_update ON public.wa_bot_sessoes FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'editar')));
CREATE POLICY wa_bot_sessoes_delete ON public.wa_bot_sessoes FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'deletar')));
REVOKE ALL ON TABLE public.wa_bot_sessoes FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.wa_bot_sessoes TO authenticated;

-- crm.conversations
CREATE TABLE public.wa_conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  user_id uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  instance_name text,
  remote_jid text,
  contact_name text,
  contact_phone text,
  is_group boolean DEFAULT false,
  type text,
  avatar text,
  avatar_url text,
  last_message text,
  unread_count numeric,
  picture_fetched_at timestamptz,
  history_synced_at timestamptz,
  history_oldest_timestamp numeric,
  last_message_timestamp numeric,
  archived boolean DEFAULT false,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.wa_conversations IS 'Origem: crm.conversations (PocketBase). Dono: hub/whatsapp.';
COMMENT ON COLUMN public.wa_conversations.user_id IS 'Relação legada → users';
COMMENT ON COLUMN public.wa_conversations.type IS 'Valores: individual | group';
CREATE TRIGGER trg_wa_conversations_atualizado_em BEFORE UPDATE ON public.wa_conversations FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX wa_conversations_user_id_instance_name_remote_jid_idx ON public.wa_conversations (user_id, instance_name, remote_jid);
ALTER TABLE public.wa_conversations ENABLE ROW LEVEL SECURITY;
CREATE POLICY wa_conversations_select ON public.wa_conversations FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'visualizar')));
CREATE POLICY wa_conversations_insert ON public.wa_conversations FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'criar')));
CREATE POLICY wa_conversations_update ON public.wa_conversations FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'editar')));
CREATE POLICY wa_conversations_delete ON public.wa_conversations FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'deletar')));
REVOKE ALL ON TABLE public.wa_conversations FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.wa_conversations TO authenticated;

-- crm.ia_treino
CREATE TABLE public.dp_ia_treino (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  situacao text,
  categoria text,
  gravidade text,
  prioridade text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.dp_ia_treino IS 'Origem: crm.ia_treino (PocketBase). Dono: hub/ocorrencias.';
COMMENT ON COLUMN public.dp_ia_treino.categoria IS 'Valores: estrutura | ruptura | validade | avaria | reposicao | equipamento | atendimento | outro | operacional';
COMMENT ON COLUMN public.dp_ia_treino.gravidade IS 'Valores: baixa | media | alta | critica';
COMMENT ON COLUMN public.dp_ia_treino.prioridade IS 'Valores: baixa | media | alta | urgente';
CREATE TRIGGER trg_dp_ia_treino_atualizado_em BEFORE UPDATE ON public.dp_ia_treino FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX dp_ia_treino_situacao_idx ON public.dp_ia_treino (situacao);
ALTER TABLE public.dp_ia_treino ENABLE ROW LEVEL SECURITY;
CREATE POLICY dp_ia_treino_select ON public.dp_ia_treino FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'visualizar')));
CREATE POLICY dp_ia_treino_insert ON public.dp_ia_treino FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'criar')));
CREATE POLICY dp_ia_treino_update ON public.dp_ia_treino FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'editar')));
CREATE POLICY dp_ia_treino_delete ON public.dp_ia_treino FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'deletar')));
REVOKE ALL ON TABLE public.dp_ia_treino FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.dp_ia_treino TO authenticated;

-- crm.regras_direcionamento
CREATE TABLE public.dp_regras_direcionamento (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  area text,
  palavras_chave text,
  responsavel_nome text,
  descricao text,
  ativa boolean DEFAULT false,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.dp_regras_direcionamento IS 'Origem: crm.regras_direcionamento (PocketBase). Dono: hub/ocorrencias.';
COMMENT ON COLUMN public.dp_regras_direcionamento.area IS 'Valores: io | operacao_loja | merchandising | pontos_extras | acesso_loja | outro';
CREATE TRIGGER trg_dp_regras_direcionamento_atualizado_em BEFORE UPDATE ON public.dp_regras_direcionamento FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX dp_regras_direcionamento_area_idx ON public.dp_regras_direcionamento (area);
ALTER TABLE public.dp_regras_direcionamento ENABLE ROW LEVEL SECURITY;
CREATE POLICY dp_regras_direcionamento_select ON public.dp_regras_direcionamento FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'visualizar')));
CREATE POLICY dp_regras_direcionamento_insert ON public.dp_regras_direcionamento FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'criar')));
CREATE POLICY dp_regras_direcionamento_update ON public.dp_regras_direcionamento FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'editar')));
CREATE POLICY dp_regras_direcionamento_delete ON public.dp_regras_direcionamento FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'deletar')));
REVOKE ALL ON TABLE public.dp_regras_direcionamento FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.dp_regras_direcionamento TO authenticated;

-- crm.representantes
CREATE TABLE public.dp_representantes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  nome text,
  email text,
  telefone text,
  industria_id uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  ativo boolean DEFAULT false,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.dp_representantes IS 'Origem: crm.representantes (PocketBase). Dono: hub/ocorrencias.';
COMMENT ON COLUMN public.dp_representantes.industria_id IS 'Relação legada → industrias';
CREATE TRIGGER trg_dp_representantes_atualizado_em BEFORE UPDATE ON public.dp_representantes FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX dp_representantes_nome_idx ON public.dp_representantes (nome);
ALTER TABLE public.dp_representantes ENABLE ROW LEVEL SECURITY;
CREATE POLICY dp_representantes_select ON public.dp_representantes FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'visualizar')) AND public.pode_ver_industria(industria_id));
CREATE POLICY dp_representantes_insert ON public.dp_representantes FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'criar')));
CREATE POLICY dp_representantes_update ON public.dp_representantes FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'editar')));
CREATE POLICY dp_representantes_delete ON public.dp_representantes FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'deletar')));
REVOKE ALL ON TABLE public.dp_representantes FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.dp_representantes TO authenticated;

-- crm.theo_ensinamentos
CREATE TABLE public.wa_theo_ensinamentos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  titulo text,
  conteudo text,
  categoria text,
  publico boolean DEFAULT false,
  ativo boolean DEFAULT false,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.wa_theo_ensinamentos IS 'Origem: crm.theo_ensinamentos (PocketBase). Dono: hub/whatsapp.';
COMMENT ON COLUMN public.wa_theo_ensinamentos.categoria IS 'Valores: comercial | trade | rh | geral';
CREATE TRIGGER trg_wa_theo_ensinamentos_atualizado_em BEFORE UPDATE ON public.wa_theo_ensinamentos FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.wa_theo_ensinamentos ENABLE ROW LEVEL SECURITY;
CREATE POLICY wa_theo_ensinamentos_select ON public.wa_theo_ensinamentos FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'visualizar')));
CREATE POLICY wa_theo_ensinamentos_insert ON public.wa_theo_ensinamentos FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'criar')));
CREATE POLICY wa_theo_ensinamentos_update ON public.wa_theo_ensinamentos FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'editar')));
CREATE POLICY wa_theo_ensinamentos_delete ON public.wa_theo_ensinamentos FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'deletar')));
REVOKE ALL ON TABLE public.wa_theo_ensinamentos FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.wa_theo_ensinamentos TO authenticated;

-- crm.whatsapp_instances
CREATE TABLE public.wa_whatsapp_instances (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  user_id uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  instance_name text,
  instance_id text,
  instance_hash text,
  status text,
  phone_number text,
  needs_initial_sync boolean DEFAULT false,
  needs_resync boolean DEFAULT false,
  auth_failure_count numeric,
  is_importing_history boolean DEFAULT false,
  import_messages_count numeric,
  import_started_at timestamptz,
  import_finished_at timestamptz,
  sync_period_days numeric,
  qrcode_base64 text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.wa_whatsapp_instances IS 'Origem: crm.whatsapp_instances (PocketBase). Dono: hub/whatsapp.';
COMMENT ON COLUMN public.wa_whatsapp_instances.user_id IS 'Relação legada → users';
COMMENT ON COLUMN public.wa_whatsapp_instances.status IS 'Valores: creating | qrcode | connected | disconnected';
CREATE TRIGGER trg_wa_whatsapp_instances_atualizado_em BEFORE UPDATE ON public.wa_whatsapp_instances FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX wa_whatsapp_instances_user_id_instance_name_uk ON public.wa_whatsapp_instances (user_id, instance_name);
ALTER TABLE public.wa_whatsapp_instances ENABLE ROW LEVEL SECURITY;
CREATE POLICY wa_whatsapp_instances_select ON public.wa_whatsapp_instances FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'visualizar')));
CREATE POLICY wa_whatsapp_instances_insert ON public.wa_whatsapp_instances FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'criar')));
CREATE POLICY wa_whatsapp_instances_update ON public.wa_whatsapp_instances FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'editar')));
CREATE POLICY wa_whatsapp_instances_delete ON public.wa_whatsapp_instances FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'deletar')));
REVOKE ALL ON TABLE public.wa_whatsapp_instances FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.wa_whatsapp_instances TO authenticated;

-- crm.whatsapp_messages
CREATE TABLE public.wa_whatsapp_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  user_id uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  instance_name text,
  remote_jid text,
  from_me boolean DEFAULT false,
  message_id text,
  push_name text,
  content text,
  message_type text,
  media_file text,
  status text,
  timestamp numeric,
  participant_jid text,
  participant_pushname text,
  media_url text,
  media_mimetype text,
  media_filename text,
  link_url text,
  link_title text,
  link_description text,
  link_thumbnail_b64 text,
  registro_vinculado text,
  bot_responder text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.wa_whatsapp_messages IS 'Origem: crm.whatsapp_messages (PocketBase). Dono: hub/whatsapp.';
COMMENT ON COLUMN public.wa_whatsapp_messages.user_id IS 'Relação legada → users';
CREATE TRIGGER trg_wa_whatsapp_messages_atualizado_em BEFORE UPDATE ON public.wa_whatsapp_messages FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX wa_whatsapp_messages_instance_name_message_id_idx ON public.wa_whatsapp_messages (instance_name, message_id);
CREATE INDEX wa_whatsapp_messages_instance_name_remote_jid_timestamp_idx ON public.wa_whatsapp_messages (instance_name, remote_jid, timestamp);
ALTER TABLE public.wa_whatsapp_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY wa_whatsapp_messages_select ON public.wa_whatsapp_messages FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'visualizar')));
CREATE POLICY wa_whatsapp_messages_insert ON public.wa_whatsapp_messages FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'criar')));
CREATE POLICY wa_whatsapp_messages_update ON public.wa_whatsapp_messages FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'editar')));
CREATE POLICY wa_whatsapp_messages_delete ON public.wa_whatsapp_messages FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'whatsapp', 'deletar')));
REVOKE ALL ON TABLE public.wa_whatsapp_messages FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.wa_whatsapp_messages TO authenticated;

-- crm.ocorrencias
CREATE TABLE public.dp_ocorrencias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  numero numeric,
  data_ocorrencia timestamptz,
  promotor_id uuid REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  repositor_nome text,
  loja_id uuid REFERENCES public.lojas(id) ON DELETE SET NULL,
  loja_nome text,
  industria_id uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  industria_nome text,
  produto text,
  situacao text,
  acao_realizada text,
  contato_loja text,
  precisa_apoio boolean DEFAULT false,
  midia text[],
  categoria text,
  gravidade text,
  prioridade text,
  visibilidade text,
  responsavel_id uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  sla_prazo timestamptz,
  status text,
  resolvida_em timestamptz,
  tempo_resolucao_min numeric,
  origem text,
  mensagem_bruta text,
  criado_por uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  acompanhamento_industria boolean DEFAULT false,
  lembretes_enviados numeric,
  area text,
  responsavel_nome text,
  representante_id uuid REFERENCES public.dp_representantes(id) ON DELETE SET NULL,
  autorizado_representante text,
  rh_status text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.dp_ocorrencias IS 'Origem: crm.ocorrencias (PocketBase). Dono: hub/ocorrencias.';
COMMENT ON COLUMN public.dp_ocorrencias.promotor_id IS 'Relação legada → promotores';
COMMENT ON COLUMN public.dp_ocorrencias.loja_id IS 'Relação legada → lojas';
COMMENT ON COLUMN public.dp_ocorrencias.industria_id IS 'Relação legada → industrias';
COMMENT ON COLUMN public.dp_ocorrencias.categoria IS 'Valores: estrutura | ruptura | validade | avaria | reposicao | equipamento | atendimento | outro | operacional | falta | rh';
COMMENT ON COLUMN public.dp_ocorrencias.gravidade IS 'Valores: baixa | media | alta | critica';
COMMENT ON COLUMN public.dp_ocorrencias.prioridade IS 'Valores: baixa | media | alta | urgente';
COMMENT ON COLUMN public.dp_ocorrencias.visibilidade IS 'Valores: interno | representante | industria';
COMMENT ON COLUMN public.dp_ocorrencias.responsavel_id IS 'Relação legada → users';
COMMENT ON COLUMN public.dp_ocorrencias.status IS 'Valores: nova | em_analise | direcionada | em_tratativa | aguardando_loja | aguardando_industria | aguardando_representante | resolvida | cancelada | improcedente';
COMMENT ON COLUMN public.dp_ocorrencias.origem IS 'Valores: whatsapp | manual';
COMMENT ON COLUMN public.dp_ocorrencias.criado_por IS 'Relação legada → users';
COMMENT ON COLUMN public.dp_ocorrencias.area IS 'Valores: io | operacao_loja | merchandising | pontos_extras | acesso_loja | outro | rh';
COMMENT ON COLUMN public.dp_ocorrencias.representante_id IS 'Relação legada → representantes';
COMMENT ON COLUMN public.dp_ocorrencias.rh_status IS 'Valores: nao_iniciado | rh_registrado';
CREATE TRIGGER trg_dp_ocorrencias_atualizado_em BEFORE UPDATE ON public.dp_ocorrencias FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX dp_ocorrencias_numero_uk ON public.dp_ocorrencias (numero);
CREATE INDEX dp_ocorrencias_status_idx ON public.dp_ocorrencias (status);
CREATE INDEX dp_ocorrencias_industria_id_idx ON public.dp_ocorrencias (industria_id);
CREATE INDEX dp_ocorrencias_loja_id_idx ON public.dp_ocorrencias (loja_id);
ALTER TABLE public.dp_ocorrencias ENABLE ROW LEVEL SECURITY;
CREATE POLICY dp_ocorrencias_select ON public.dp_ocorrencias FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'visualizar')) AND public.pode_ver_industria(industria_id));
CREATE POLICY dp_ocorrencias_insert ON public.dp_ocorrencias FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'criar')));
CREATE POLICY dp_ocorrencias_update ON public.dp_ocorrencias FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'editar')));
CREATE POLICY dp_ocorrencias_delete ON public.dp_ocorrencias FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'deletar')));
REVOKE ALL ON TABLE public.dp_ocorrencias FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.dp_ocorrencias TO authenticated;

-- crm.tratativas
CREATE TABLE public.dp_tratativas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  ocorrencia_id uuid REFERENCES public.dp_ocorrencias(id) ON DELETE SET NULL,
  autor_id uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  autor_nome text,
  tipo text,
  descricao text,
  texto text,
  previsao text,
  evidencia text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.dp_tratativas IS 'Origem: crm.tratativas (PocketBase). Dono: hub/ocorrencias.';
COMMENT ON COLUMN public.dp_tratativas.ocorrencia_id IS 'Relação legada → ocorrencias';
COMMENT ON COLUMN public.dp_tratativas.autor_id IS 'Relação legada → users';
CREATE TRIGGER trg_dp_tratativas_atualizado_em BEFORE UPDATE ON public.dp_tratativas FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX dp_tratativas_ocorrencia_id_idx ON public.dp_tratativas (ocorrencia_id);
ALTER TABLE public.dp_tratativas ENABLE ROW LEVEL SECURITY;
CREATE POLICY dp_tratativas_select ON public.dp_tratativas FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'visualizar')));
CREATE POLICY dp_tratativas_insert ON public.dp_tratativas FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'criar')));
CREATE POLICY dp_tratativas_update ON public.dp_tratativas FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'editar')));
CREATE POLICY dp_tratativas_delete ON public.dp_tratativas FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'deletar')));
REVOKE ALL ON TABLE public.dp_tratativas FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.dp_tratativas TO authenticated;

-- crm.lembretes
CREATE TABLE public.dp_lembretes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  ocorrencia_id uuid REFERENCES public.dp_ocorrencias(id) ON DELETE SET NULL,
  destinatario text,
  destinatario_tipo text,
  destinatario_nome text,
  destinatario_telefone text,
  mensagem text,
  canal text,
  enviado boolean DEFAULT false,
  status text,
  erro text,
  enviado_em timestamptz,
  origem text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.dp_lembretes IS 'Origem: crm.lembretes (PocketBase). Dono: hub/ocorrencias.';
COMMENT ON COLUMN public.dp_lembretes.ocorrencia_id IS 'Relação legada → ocorrencias';
CREATE TRIGGER trg_dp_lembretes_atualizado_em BEFORE UPDATE ON public.dp_lembretes FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX dp_lembretes_ocorrencia_id_idx ON public.dp_lembretes (ocorrencia_id);
ALTER TABLE public.dp_lembretes ENABLE ROW LEVEL SECURITY;
CREATE POLICY dp_lembretes_select ON public.dp_lembretes FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'visualizar')));
CREATE POLICY dp_lembretes_insert ON public.dp_lembretes FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'criar')));
CREATE POLICY dp_lembretes_update ON public.dp_lembretes FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'editar')));
CREATE POLICY dp_lembretes_delete ON public.dp_lembretes FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'deletar')));
REVOKE ALL ON TABLE public.dp_lembretes FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.dp_lembretes TO authenticated;

-- crm.mensagens_whatsapp
CREATE TABLE public.dp_mensagens_whatsapp (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  origem text,
  evento text,
  remetente text,
  grupo text,
  conteudo text,
  payload jsonb,
  processada boolean DEFAULT false,
  ocorrencia_id uuid REFERENCES public.dp_ocorrencias(id) ON DELETE SET NULL,
  erro text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.dp_mensagens_whatsapp IS 'Origem: crm.mensagens_whatsapp (PocketBase). Dono: hub/ocorrencias.';
COMMENT ON COLUMN public.dp_mensagens_whatsapp.ocorrencia_id IS 'Relação legada → ocorrencias';
CREATE TRIGGER trg_dp_mensagens_whatsapp_atualizado_em BEFORE UPDATE ON public.dp_mensagens_whatsapp FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX dp_mensagens_whatsapp_grupo_idx ON public.dp_mensagens_whatsapp (grupo);
ALTER TABLE public.dp_mensagens_whatsapp ENABLE ROW LEVEL SECURITY;
CREATE POLICY dp_mensagens_whatsapp_select ON public.dp_mensagens_whatsapp FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'visualizar')));
CREATE POLICY dp_mensagens_whatsapp_insert ON public.dp_mensagens_whatsapp FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'criar')));
CREATE POLICY dp_mensagens_whatsapp_update ON public.dp_mensagens_whatsapp FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'editar')));
CREATE POLICY dp_mensagens_whatsapp_delete ON public.dp_mensagens_whatsapp FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('hub', 'ocorrencias', 'deletar')));
REVOKE ALL ON TABLE public.dp_mensagens_whatsapp FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.dp_mensagens_whatsapp TO authenticated;
