-- Migration 20261024_007_margem_real — GERADA por scripts/unificacao/gerar_migrations.py. Não editar à mão:
-- ajuste o gerador e gere de novo. Origem: schema.json de produção (2026-10-21/22).

INSERT INTO public.modulos (system_id, chave, nome)
SELECT s.id, m.chave, m.nome FROM public.systems s
CROSS JOIN (VALUES ('empresa', 'Minha empresa'), ('financeiro', 'Financeiro'), ('pessoal', 'Pessoal (folha e pagamentos)')) AS m(chave, nome)
WHERE s.slug = 'margem-real'
ON CONFLICT (system_id, chave) DO UPDATE SET nome = EXCLUDED.nome;

INSERT INTO public.modulo_acoes (modulo_id, chave)
SELECT m.id, a.chave FROM public.modulos m JOIN public.systems s ON s.id = m.system_id
CROSS JOIN (VALUES ('visualizar'), ('criar'), ('editar'), ('deletar')) AS a(chave)
WHERE s.slug = 'margem-real'
ON CONFLICT (modulo_id, chave) DO NOTHING;

-- mr.clientes (identidade em industrias)
CREATE TABLE public.mr_clientes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  industria_id uuid NOT NULL REFERENCES public.industrias(id) ON DELETE CASCADE,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  contato text,
  observacoes text,
  ativo boolean DEFAULT false,
  dias_atendimento numeric,
  pct_rateio numeric,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (industria_id)
);
COMMENT ON TABLE public.mr_clientes IS 'Origem: mr.clientes (PocketBase). Dono: margem-real/financeiro.';
COMMENT ON COLUMN public.mr_clientes.owner IS 'Relação legada → users';
CREATE TRIGGER trg_mr_clientes_atualizado_em BEFORE UPDATE ON public.mr_clientes FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX mr_clientes_owner_idx ON public.mr_clientes (owner);
ALTER TABLE public.mr_clientes ENABLE ROW LEVEL SECURITY;
CREATE POLICY mr_clientes_select ON public.mr_clientes FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'visualizar')));
CREATE POLICY mr_clientes_insert ON public.mr_clientes FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'criar')));
CREATE POLICY mr_clientes_update ON public.mr_clientes FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar')));
CREATE POLICY mr_clientes_delete ON public.mr_clientes FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'deletar')));
REVOKE ALL ON TABLE public.mr_clientes FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mr_clientes TO authenticated;

-- mr.cnpjs (identidade em empresas_dcg)
CREATE TABLE public.mr_cnpjs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  empresa_id uuid NOT NULL REFERENCES public.empresas_dcg(id) ON DELETE CASCADE,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  apelido text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (empresa_id)
);
COMMENT ON TABLE public.mr_cnpjs IS 'Origem: mr.cnpjs (PocketBase). Dono: margem-real/empresa.';
COMMENT ON COLUMN public.mr_cnpjs.owner IS 'Relação legada → users';
CREATE TRIGGER trg_mr_cnpjs_atualizado_em BEFORE UPDATE ON public.mr_cnpjs FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX mr_cnpjs_owner_idx ON public.mr_cnpjs (owner);
ALTER TABLE public.mr_cnpjs ENABLE ROW LEVEL SECURITY;
CREATE POLICY mr_cnpjs_select ON public.mr_cnpjs FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'empresa', 'visualizar')));
CREATE POLICY mr_cnpjs_insert ON public.mr_cnpjs FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'empresa', 'criar')));
CREATE POLICY mr_cnpjs_update ON public.mr_cnpjs FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'empresa', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'empresa', 'editar')));
CREATE POLICY mr_cnpjs_delete ON public.mr_cnpjs FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'empresa', 'deletar')));
REVOKE ALL ON TABLE public.mr_cnpjs FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mr_cnpjs TO authenticated;

-- mr.contas_bancarias
CREATE TABLE public.mr_contas_bancarias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  apelido text,
  tipo text,
  banco text,
  cnpj uuid REFERENCES public.empresas_dcg(id) ON DELETE SET NULL,
  limite numeric,
  ativo boolean DEFAULT false,
  pluggy_account_id text,
  saldo numeric,
  saldo_atualizado_em timestamptz,
  agencia text,
  conta text,
  cartao_final text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.mr_contas_bancarias IS 'Origem: mr.contas_bancarias (PocketBase). Dono: margem-real/financeiro.';
COMMENT ON COLUMN public.mr_contas_bancarias.owner IS 'Relação legada → users';
COMMENT ON COLUMN public.mr_contas_bancarias.tipo IS 'Valores: conta_corrente | poupanca | cartao';
COMMENT ON COLUMN public.mr_contas_bancarias.cnpj IS 'Relação legada → cnpjs';
CREATE TRIGGER trg_mr_contas_bancarias_atualizado_em BEFORE UPDATE ON public.mr_contas_bancarias FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX mr_contas_bancarias_owner_idx ON public.mr_contas_bancarias (owner);
ALTER TABLE public.mr_contas_bancarias ENABLE ROW LEVEL SECURITY;
CREATE POLICY mr_contas_bancarias_select ON public.mr_contas_bancarias FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'visualizar')));
CREATE POLICY mr_contas_bancarias_insert ON public.mr_contas_bancarias FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'criar')));
CREATE POLICY mr_contas_bancarias_update ON public.mr_contas_bancarias FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar')));
CREATE POLICY mr_contas_bancarias_delete ON public.mr_contas_bancarias FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'deletar')));
REVOKE ALL ON TABLE public.mr_contas_bancarias FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mr_contas_bancarias TO authenticated;

-- mr.contas_receber
CREATE TABLE public.mr_contas_receber (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  descricao text,
  cliente uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  valor numeric,
  vencimento timestamptz,
  status text,
  data_recebimento timestamptz,
  cnpj uuid REFERENCES public.empresas_dcg(id) ON DELETE SET NULL,
  comprovante text,
  recorrencia text,
  recorrencia_meses text,
  boleto text,
  nf text,
  conciliado_bancario boolean DEFAULT false,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.mr_contas_receber IS 'Origem: mr.contas_receber (PocketBase). Dono: margem-real/financeiro.';
COMMENT ON COLUMN public.mr_contas_receber.owner IS 'Relação legada → users';
COMMENT ON COLUMN public.mr_contas_receber.cliente IS 'Relação legada → clientes';
COMMENT ON COLUMN public.mr_contas_receber.status IS 'Valores: previsto | realizado | cancelado';
COMMENT ON COLUMN public.mr_contas_receber.cnpj IS 'Relação legada → cnpjs';
COMMENT ON COLUMN public.mr_contas_receber.recorrencia IS 'Valores: nenhuma | fixa | parcelas';
CREATE TRIGGER trg_mr_contas_receber_atualizado_em BEFORE UPDATE ON public.mr_contas_receber FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX mr_contas_receber_owner_vencimento_idx ON public.mr_contas_receber (owner, vencimento);
ALTER TABLE public.mr_contas_receber ENABLE ROW LEVEL SECURITY;
CREATE POLICY mr_contas_receber_select ON public.mr_contas_receber FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'visualizar')) AND public.pode_ver_industria(cliente));
CREATE POLICY mr_contas_receber_insert ON public.mr_contas_receber FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'criar')));
CREATE POLICY mr_contas_receber_update ON public.mr_contas_receber FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar')));
CREATE POLICY mr_contas_receber_delete ON public.mr_contas_receber FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'deletar')));
REVOKE ALL ON TABLE public.mr_contas_receber FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mr_contas_receber TO authenticated;

-- mr.contratos
CREATE TABLE public.mr_contratos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  cliente uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  cnpj uuid REFERENCES public.empresas_dcg(id) ON DELETE SET NULL,
  descricao text,
  valor_mensal numeric,
  data_inicio timestamptz,
  data_fim timestamptz,
  ativo boolean DEFAULT false,
  visitas_semana numeric,
  horas_semana numeric,
  valor_hora numeric,
  dia_vencimento numeric,
  historico_reajuste jsonb,
  arquivo text,
  promotor uuid REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.mr_contratos IS 'Origem: mr.contratos (PocketBase). Dono: margem-real/financeiro.';
COMMENT ON COLUMN public.mr_contratos.owner IS 'Relação legada → users';
COMMENT ON COLUMN public.mr_contratos.cliente IS 'Relação legada → clientes';
COMMENT ON COLUMN public.mr_contratos.cnpj IS 'Relação legada → cnpjs';
COMMENT ON COLUMN public.mr_contratos.promotor IS 'Relação legada → promotores';
CREATE TRIGGER trg_mr_contratos_atualizado_em BEFORE UPDATE ON public.mr_contratos FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX mr_contratos_owner_idx ON public.mr_contratos (owner);
ALTER TABLE public.mr_contratos ENABLE ROW LEVEL SECURITY;
CREATE POLICY mr_contratos_select ON public.mr_contratos FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'visualizar')) AND public.pode_ver_industria(cliente));
CREATE POLICY mr_contratos_insert ON public.mr_contratos FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'criar')));
CREATE POLICY mr_contratos_update ON public.mr_contratos FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar')));
CREATE POLICY mr_contratos_delete ON public.mr_contratos FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'deletar')));
REVOKE ALL ON TABLE public.mr_contratos FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mr_contratos TO authenticated;

-- mr.documentos
CREATE TABLE public.mr_documentos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  arquivo text[],
  nome text,
  tipo text,
  mes text,
  vencimento timestamptz,
  cliente uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  promotor uuid REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  observacao text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.mr_documentos IS 'Origem: mr.documentos (PocketBase). Dono: margem-real/pessoal.';
COMMENT ON COLUMN public.mr_documentos.owner IS 'Relação legada → users';
COMMENT ON COLUMN public.mr_documentos.tipo IS 'Valores: folha | guia_pagamento | boleto | nf | extrato | outro | extrato_bancario | fatura_cartao';
COMMENT ON COLUMN public.mr_documentos.cliente IS 'Relação legada → clientes';
COMMENT ON COLUMN public.mr_documentos.promotor IS 'Relação legada → promotores';
CREATE TRIGGER trg_mr_documentos_atualizado_em BEFORE UPDATE ON public.mr_documentos FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX mr_documentos_owner_mes_idx ON public.mr_documentos (owner, mes);
ALTER TABLE public.mr_documentos ENABLE ROW LEVEL SECURITY;
CREATE POLICY mr_documentos_select ON public.mr_documentos FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'pessoal', 'visualizar')) AND public.pode_ver_industria(cliente));
CREATE POLICY mr_documentos_insert ON public.mr_documentos FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'pessoal', 'criar')));
CREATE POLICY mr_documentos_update ON public.mr_documentos FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'pessoal', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'pessoal', 'editar')));
CREATE POLICY mr_documentos_delete ON public.mr_documentos FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'pessoal', 'deletar')));
REVOKE ALL ON TABLE public.mr_documentos FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mr_documentos TO authenticated;

-- mr.fechamento_mensal
CREATE TABLE public.mr_fechamento_mensal (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  mes text,
  cliente uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  cnpj_faturante uuid REFERENCES public.empresas_dcg(id) ON DELETE SET NULL,
  valor_bruto numeric,
  status text,
  nf_numero text,
  nf_url text,
  boleto_url text,
  observacoes text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.mr_fechamento_mensal IS 'Origem: mr.fechamento_mensal (PocketBase). Dono: margem-real/financeiro.';
COMMENT ON COLUMN public.mr_fechamento_mensal.owner IS 'Relação legada → users';
COMMENT ON COLUMN public.mr_fechamento_mensal.cliente IS 'Relação legada → clientes';
COMMENT ON COLUMN public.mr_fechamento_mensal.cnpj_faturante IS 'Relação legada → cnpjs';
COMMENT ON COLUMN public.mr_fechamento_mensal.status IS 'Valores: aberto | faturado | pago | cancelado';
CREATE TRIGGER trg_mr_fechamento_mensal_atualizado_em BEFORE UPDATE ON public.mr_fechamento_mensal FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX mr_fechamento_mensal_owner_mes_cliente_idx ON public.mr_fechamento_mensal (owner, mes, cliente);
ALTER TABLE public.mr_fechamento_mensal ENABLE ROW LEVEL SECURITY;
CREATE POLICY mr_fechamento_mensal_select ON public.mr_fechamento_mensal FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'visualizar')) AND public.pode_ver_industria(cliente));
CREATE POLICY mr_fechamento_mensal_insert ON public.mr_fechamento_mensal FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'criar')));
CREATE POLICY mr_fechamento_mensal_update ON public.mr_fechamento_mensal FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar')));
CREATE POLICY mr_fechamento_mensal_delete ON public.mr_fechamento_mensal FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'deletar')));
REVOKE ALL ON TABLE public.mr_fechamento_mensal FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mr_fechamento_mensal TO authenticated;

-- mr.fechamentos
CREATE TABLE public.mr_fechamentos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  mes text,
  status text,
  decisao text,
  dre jsonb,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.mr_fechamentos IS 'Origem: mr.fechamentos (PocketBase). Dono: margem-real/financeiro.';
COMMENT ON COLUMN public.mr_fechamentos.owner IS 'Relação legada → users';
COMMENT ON COLUMN public.mr_fechamentos.status IS 'Valores: aberto | fechado';
CREATE TRIGGER trg_mr_fechamentos_atualizado_em BEFORE UPDATE ON public.mr_fechamentos FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX mr_fechamentos_owner_mes_uk ON public.mr_fechamentos (owner, mes);
ALTER TABLE public.mr_fechamentos ENABLE ROW LEVEL SECURITY;
CREATE POLICY mr_fechamentos_select ON public.mr_fechamentos FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'visualizar')));
CREATE POLICY mr_fechamentos_insert ON public.mr_fechamentos FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'criar')));
CREATE POLICY mr_fechamentos_update ON public.mr_fechamentos FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar')));
CREATE POLICY mr_fechamentos_delete ON public.mr_fechamentos FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'deletar')));
REVOKE ALL ON TABLE public.mr_fechamentos FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mr_fechamentos TO authenticated;

-- mr.lojas (identidade em lojas)
CREATE TABLE public.mr_lojas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  loja_id uuid NOT NULL REFERENCES public.lojas(id) ON DELETE CASCADE,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  rede text,
  bandeira text,
  contratos numeric,
  visitas_semana numeric,
  minutos_semana numeric,
  promotor uuid REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  status text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (loja_id)
);
COMMENT ON TABLE public.mr_lojas IS 'Origem: mr.lojas (PocketBase). Dono: margem-real/financeiro.';
COMMENT ON COLUMN public.mr_lojas.owner IS 'Relação legada → users';
COMMENT ON COLUMN public.mr_lojas.promotor IS 'Relação legada → promotores';
COMMENT ON COLUMN public.mr_lojas.status IS 'Valores: ativa | inativa';
CREATE TRIGGER trg_mr_lojas_atualizado_em BEFORE UPDATE ON public.mr_lojas FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX mr_lojas_owner_idx ON public.mr_lojas (owner);
ALTER TABLE public.mr_lojas ENABLE ROW LEVEL SECURITY;
CREATE POLICY mr_lojas_select ON public.mr_lojas FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'visualizar')));
CREATE POLICY mr_lojas_insert ON public.mr_lojas FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'criar')));
CREATE POLICY mr_lojas_update ON public.mr_lojas FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar')));
CREATE POLICY mr_lojas_delete ON public.mr_lojas FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'deletar')));
REVOKE ALL ON TABLE public.mr_lojas FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mr_lojas TO authenticated;

-- mr.of_conexoes
CREATE TABLE public.mr_of_conexoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  item_id text,
  instituicao text,
  status text,
  ultima_sync timestamptz,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.mr_of_conexoes IS 'Origem: mr.of_conexoes (PocketBase). Dono: margem-real/financeiro.';
COMMENT ON COLUMN public.mr_of_conexoes.owner IS 'Relação legada → users';
COMMENT ON COLUMN public.mr_of_conexoes.status IS 'Valores: ativa | erro | desconectada';
CREATE TRIGGER trg_mr_of_conexoes_atualizado_em BEFORE UPDATE ON public.mr_of_conexoes FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX mr_of_conexoes_owner_idx ON public.mr_of_conexoes (owner);
ALTER TABLE public.mr_of_conexoes ENABLE ROW LEVEL SECURITY;
CREATE POLICY mr_of_conexoes_select ON public.mr_of_conexoes FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'visualizar')));
CREATE POLICY mr_of_conexoes_insert ON public.mr_of_conexoes FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'criar')));
CREATE POLICY mr_of_conexoes_update ON public.mr_of_conexoes FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar')));
CREATE POLICY mr_of_conexoes_delete ON public.mr_of_conexoes FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'deletar')));
REVOKE ALL ON TABLE public.mr_of_conexoes FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mr_of_conexoes TO authenticated;

-- mr.plano_contas
CREATE TABLE public.mr_plano_contas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  nome text,
  tipo text,
  categoria text,
  subcategoria text,
  linha_dre text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.mr_plano_contas IS 'Origem: mr.plano_contas (PocketBase). Dono: margem-real/financeiro.';
COMMENT ON COLUMN public.mr_plano_contas.owner IS 'Relação legada → users';
COMMENT ON COLUMN public.mr_plano_contas.tipo IS 'Valores: receita | despesa';
COMMENT ON COLUMN public.mr_plano_contas.linha_dre IS 'Valores: receita_bruta | deducoes | custos | despesas_operacionais | juros | outras | excluido';
CREATE TRIGGER trg_mr_plano_contas_atualizado_em BEFORE UPDATE ON public.mr_plano_contas FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX mr_plano_contas_owner_idx ON public.mr_plano_contas (owner);
ALTER TABLE public.mr_plano_contas ENABLE ROW LEVEL SECURITY;
CREATE POLICY mr_plano_contas_select ON public.mr_plano_contas FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'visualizar')));
CREATE POLICY mr_plano_contas_insert ON public.mr_plano_contas FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'criar')));
CREATE POLICY mr_plano_contas_update ON public.mr_plano_contas FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar')));
CREATE POLICY mr_plano_contas_delete ON public.mr_plano_contas FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'deletar')));
REVOKE ALL ON TABLE public.mr_plano_contas FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mr_plano_contas TO authenticated;

-- mr.promotores (identidade em colaboradores)
CREATE TABLE public.mr_promotores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  colaborador_id uuid NOT NULL REFERENCES public.colaboradores(id) ON DELETE CASCADE,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  cargo text,
  salario numeric,
  encargos numeric,
  beneficios numeric,
  cliente uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  ativo boolean DEFAULT false,
  cnpj uuid REFERENCES public.empresas_dcg(id) ON DELETE SET NULL,
  tipo_vinculo text,
  documento text,
  lojas text,
  status text,
  chave_pix text,
  banco text,
  observacoes text,
  cpf text,
  agencia text,
  conta text,
  data_nascimento text,
  data_inicio text,
  data_demissao text,
  saiu boolean DEFAULT false,
  arrecadacao numeric,
  beneficios_json jsonb,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (colaborador_id)
);
COMMENT ON TABLE public.mr_promotores IS 'Origem: mr.promotores (PocketBase). Dono: margem-real/pessoal.';
COMMENT ON COLUMN public.mr_promotores.owner IS 'Relação legada → users';
COMMENT ON COLUMN public.mr_promotores.cargo IS 'Valores: promotor | lider';
COMMENT ON COLUMN public.mr_promotores.cliente IS 'Relação legada → clientes';
COMMENT ON COLUMN public.mr_promotores.cnpj IS 'Relação legada → cnpjs';
COMMENT ON COLUMN public.mr_promotores.tipo_vinculo IS 'Valores: CLT | MEI | PJ | terceirizado';
COMMENT ON COLUMN public.mr_promotores.status IS 'Valores: ativo | inativo';
CREATE TRIGGER trg_mr_promotores_atualizado_em BEFORE UPDATE ON public.mr_promotores FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX mr_promotores_owner_idx ON public.mr_promotores (owner);
ALTER TABLE public.mr_promotores ENABLE ROW LEVEL SECURITY;
CREATE POLICY mr_promotores_select ON public.mr_promotores FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'pessoal', 'visualizar')) AND public.pode_ver_industria(cliente));
CREATE POLICY mr_promotores_insert ON public.mr_promotores FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'pessoal', 'criar')));
CREATE POLICY mr_promotores_update ON public.mr_promotores FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'pessoal', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'pessoal', 'editar')));
CREATE POLICY mr_promotores_delete ON public.mr_promotores FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'pessoal', 'deletar')));
REVOKE ALL ON TABLE public.mr_promotores FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mr_promotores TO authenticated;

-- mr.alertas
CREATE TABLE public.mr_alertas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  documento uuid REFERENCES public.mr_documentos(id) ON DELETE SET NULL,
  tipo text,
  titulo text,
  vencimento text,
  lido boolean DEFAULT false,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.mr_alertas IS 'Origem: mr.alertas (PocketBase). Dono: margem-real/financeiro.';
COMMENT ON COLUMN public.mr_alertas.owner IS 'Relação legada → users';
COMMENT ON COLUMN public.mr_alertas.documento IS 'Relação legada → documentos';
COMMENT ON COLUMN public.mr_alertas.tipo IS 'Valores: vence_breve | vencido | lembrete';
CREATE TRIGGER trg_mr_alertas_atualizado_em BEFORE UPDATE ON public.mr_alertas FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX mr_alertas_owner_idx ON public.mr_alertas (owner);
ALTER TABLE public.mr_alertas ENABLE ROW LEVEL SECURITY;
CREATE POLICY mr_alertas_select ON public.mr_alertas FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'visualizar')));
CREATE POLICY mr_alertas_insert ON public.mr_alertas FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'criar')));
CREATE POLICY mr_alertas_update ON public.mr_alertas FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar')));
CREATE POLICY mr_alertas_delete ON public.mr_alertas FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'deletar')));
REVOKE ALL ON TABLE public.mr_alertas FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mr_alertas TO authenticated;

-- mr.contas_pagar
CREATE TABLE public.mr_contas_pagar (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  descricao text,
  valor numeric,
  vencimento timestamptz,
  status text,
  categoria uuid REFERENCES public.mr_plano_contas(id) ON DELETE SET NULL,
  data_pagamento timestamptz,
  cnpj uuid REFERENCES public.empresas_dcg(id) ON DELETE SET NULL,
  comprovante text,
  recorrencia text,
  recorrencia_meses text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.mr_contas_pagar IS 'Origem: mr.contas_pagar (PocketBase). Dono: margem-real/financeiro.';
COMMENT ON COLUMN public.mr_contas_pagar.owner IS 'Relação legada → users';
COMMENT ON COLUMN public.mr_contas_pagar.status IS 'Valores: previsto | realizado | cancelado';
COMMENT ON COLUMN public.mr_contas_pagar.categoria IS 'Relação legada → plano_contas';
COMMENT ON COLUMN public.mr_contas_pagar.cnpj IS 'Relação legada → cnpjs';
COMMENT ON COLUMN public.mr_contas_pagar.recorrencia IS 'Valores: nenhuma | fixa | parcelas';
CREATE TRIGGER trg_mr_contas_pagar_atualizado_em BEFORE UPDATE ON public.mr_contas_pagar FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX mr_contas_pagar_owner_vencimento_idx ON public.mr_contas_pagar (owner, vencimento);
ALTER TABLE public.mr_contas_pagar ENABLE ROW LEVEL SECURITY;
CREATE POLICY mr_contas_pagar_select ON public.mr_contas_pagar FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'visualizar')));
CREATE POLICY mr_contas_pagar_insert ON public.mr_contas_pagar FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'criar')));
CREATE POLICY mr_contas_pagar_update ON public.mr_contas_pagar FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar')));
CREATE POLICY mr_contas_pagar_delete ON public.mr_contas_pagar FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'deletar')));
REVOKE ALL ON TABLE public.mr_contas_pagar FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mr_contas_pagar TO authenticated;

-- mr.lancamentos
CREATE TABLE public.mr_lancamentos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  data timestamptz,
  descricao text,
  valor numeric,
  tipo text,
  categoria uuid REFERENCES public.mr_plano_contas(id) ON DELETE SET NULL,
  cliente uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  origem text,
  conciliado boolean DEFAULT false,
  cnpj uuid REFERENCES public.empresas_dcg(id) ON DELETE SET NULL,
  conta uuid REFERENCES public.mr_contas_bancarias(id) ON DELETE SET NULL,
  promotor uuid REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  motivo_pagamento text,
  pago_para text,
  adiantamento boolean DEFAULT false,
  referencia text,
  pluggy_id text,
  nf_numero text,
  forma_pagamento text,
  competencia text,
  taxa_pct numeric,
  valor_taxa numeric,
  natureza text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.mr_lancamentos IS 'Origem: mr.lancamentos (PocketBase). Dono: margem-real/financeiro.';
COMMENT ON COLUMN public.mr_lancamentos.owner IS 'Relação legada → users';
COMMENT ON COLUMN public.mr_lancamentos.tipo IS 'Valores: entrada | saida';
COMMENT ON COLUMN public.mr_lancamentos.categoria IS 'Relação legada → plano_contas';
COMMENT ON COLUMN public.mr_lancamentos.cliente IS 'Relação legada → clientes';
COMMENT ON COLUMN public.mr_lancamentos.origem IS 'Valores: manual | extrato';
COMMENT ON COLUMN public.mr_lancamentos.cnpj IS 'Relação legada → cnpjs';
COMMENT ON COLUMN public.mr_lancamentos.conta IS 'Relação legada → contas_bancarias';
COMMENT ON COLUMN public.mr_lancamentos.promotor IS 'Relação legada → promotores';
COMMENT ON COLUMN public.mr_lancamentos.motivo_pagamento IS 'Valores: salario | adiantamento | vale | refeicao | ferias | viagem | decimo_terceiro | outros | prestacao_servicos';
COMMENT ON COLUMN public.mr_lancamentos.forma_pagamento IS 'Valores: pix | boleto | transferencia | outros';
COMMENT ON COLUMN public.mr_lancamentos.natureza IS 'Valores: folha_clt | mei_terceirizado | imposto_guia | operacional | outros';
CREATE TRIGGER trg_mr_lancamentos_atualizado_em BEFORE UPDATE ON public.mr_lancamentos FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX mr_lancamentos_owner_data_idx ON public.mr_lancamentos (owner, data);
ALTER TABLE public.mr_lancamentos ENABLE ROW LEVEL SECURITY;
CREATE POLICY mr_lancamentos_select ON public.mr_lancamentos FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'visualizar')) AND public.pode_ver_industria(cliente));
CREATE POLICY mr_lancamentos_insert ON public.mr_lancamentos FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'criar')));
CREATE POLICY mr_lancamentos_update ON public.mr_lancamentos FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'editar')));
CREATE POLICY mr_lancamentos_delete ON public.mr_lancamentos FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'financeiro', 'deletar')));
REVOKE ALL ON TABLE public.mr_lancamentos FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mr_lancamentos TO authenticated;

-- mr.pagamentos
CREATE TABLE public.mr_pagamentos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  owner uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  promotor uuid REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  valor numeric,
  motivo_pagamento text,
  conta uuid REFERENCES public.mr_contas_bancarias(id) ON DELETE SET NULL,
  data_prevista timestamptz,
  status text,
  pago_em timestamptz,
  lancamento uuid REFERENCES public.mr_lancamentos(id) ON DELETE SET NULL,
  observacao text,
  competencia text,
  liberado boolean DEFAULT false,
  liberado_em timestamptz,
  nf_numero text,
  nf_arquivo text,
  folha_doc uuid REFERENCES public.mr_documentos(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.mr_pagamentos IS 'Origem: mr.pagamentos (PocketBase). Dono: margem-real/pessoal.';
COMMENT ON COLUMN public.mr_pagamentos.owner IS 'Relação legada → users';
COMMENT ON COLUMN public.mr_pagamentos.promotor IS 'Relação legada → promotores';
COMMENT ON COLUMN public.mr_pagamentos.motivo_pagamento IS 'Valores: salario | adiantamento | vale | refeicao | ferias | viagem | decimo_terceiro | outros | prestacao_servicos';
COMMENT ON COLUMN public.mr_pagamentos.conta IS 'Relação legada → contas_bancarias';
COMMENT ON COLUMN public.mr_pagamentos.status IS 'Valores: pendente | pago | cancelado';
COMMENT ON COLUMN public.mr_pagamentos.lancamento IS 'Relação legada → lancamentos';
COMMENT ON COLUMN public.mr_pagamentos.folha_doc IS 'Relação legada → documentos';
CREATE TRIGGER trg_mr_pagamentos_atualizado_em BEFORE UPDATE ON public.mr_pagamentos FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX mr_pagamentos_owner_idx ON public.mr_pagamentos (owner);
ALTER TABLE public.mr_pagamentos ENABLE ROW LEVEL SECURITY;
CREATE POLICY mr_pagamentos_select ON public.mr_pagamentos FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'pessoal', 'visualizar')));
CREATE POLICY mr_pagamentos_insert ON public.mr_pagamentos FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'pessoal', 'criar')));
CREATE POLICY mr_pagamentos_update ON public.mr_pagamentos FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'pessoal', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'pessoal', 'editar')));
CREATE POLICY mr_pagamentos_delete ON public.mr_pagamentos FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('margem-real', 'pessoal', 'deletar')));
REVOKE ALL ON TABLE public.mr_pagamentos FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mr_pagamentos TO authenticated;
