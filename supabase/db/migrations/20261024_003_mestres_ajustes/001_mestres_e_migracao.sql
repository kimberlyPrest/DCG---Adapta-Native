-- Migration 20261024_003 — PLANO-UNIFICACAO-BANCO U1.2
-- Ajusta os cadastros mestres (SPEC-002) aos campos que a produção dos 4
-- PocketBase usa, e cria o schema migracao para o ETL.

-- redes
ALTER TABLE public.redes ADD COLUMN codigo_externo text;
ALTER TABLE public.redes ADD COLUMN cnpj text CHECK (cnpj IS NULL OR cnpj ~ '^[0-9]{14}$');
ALTER TABLE public.redes ADD COLUMN legado jsonb NOT NULL DEFAULT '{}'::jsonb;

-- lojas: UF vem como nome completo em parte das fontes; normalização é do ETL.
ALTER TABLE public.lojas ALTER COLUMN uf TYPE text;
ALTER TABLE public.lojas ADD COLUMN razao_social text;
ALTER TABLE public.lojas ADD COLUMN regiao text;
ALTER TABLE public.lojas ADD COLUMN bairro text;
ALTER TABLE public.lojas ADD COLUMN cep text;
ALTER TABLE public.lojas ADD COLUMN legado jsonb NOT NULL DEFAULT '{}'::jsonb;

-- industrias
ALTER TABLE public.industrias ADD COLUMN segmento text;
ALTER TABLE public.industrias ADD COLUMN tradepro_client_id text;
ALTER TABLE public.industrias ADD COLUMN legado jsonb NOT NULL DEFAULT '{}'::jsonb;
CREATE INDEX idx_industrias_tradepro ON public.industrias (tradepro_client_id);

-- produtos: a IO tem mix sem código; sku deixa de ser obrigatório.
ALTER TABLE public.produtos ALTER COLUMN sku DROP NOT NULL;
ALTER TABLE public.produtos DROP CONSTRAINT produtos_industria_id_sku_key;
CREATE UNIQUE INDEX produtos_industria_sku_uk ON public.produtos (industria_id, sku) WHERE sku IS NOT NULL AND sku <> '';
CREATE INDEX idx_produtos_ean ON public.produtos (ean);
ALTER TABLE public.produtos ADD COLUMN categoria text;
ALTER TABLE public.produtos ADD COLUMN familia text;
ALTER TABLE public.produtos ADD COLUMN sabor text;
ALTER TABLE public.produtos ADD COLUMN gramatura text;
ALTER TABLE public.produtos ADD COLUMN embalagem text;
ALTER TABLE public.produtos ADD COLUMN shelf_life_dias numeric;
ALTER TABLE public.produtos ADD COLUMN legado jsonb NOT NULL DEFAULT '{}'::jsonb;

-- colaboradores: o WhatsApp é a chave usada pelo bot e pela gamificação.
ALTER TABLE public.colaboradores DROP CONSTRAINT colaboradores_funcao_check;
ALTER TABLE public.colaboradores ADD CONSTRAINT colaboradores_funcao_check
  CHECK (funcao IN ('promotor', 'supervisor', 'coordenador', 'lider', 'repositor', 'outro'));
ALTER TABLE public.colaboradores ALTER COLUMN funcao SET DEFAULT 'promotor';
ALTER TABLE public.colaboradores ADD COLUMN regiao text;
ALTER TABLE public.colaboradores ADD COLUMN whatsapp_jid text UNIQUE;
ALTER TABLE public.colaboradores ADD COLUMN legado jsonb NOT NULL DEFAULT '{}'::jsonb;
COMMENT ON COLUMN public.colaboradores.whatsapp_jid IS
  'JID do WhatsApp (participant_jid). Substitui o casamento por nome entre CRM e Margem Real.';

-- empresas_dcg: entidades jurídicas do CRM podem estar sem CNPJ.
ALTER TABLE public.empresas_dcg ALTER COLUMN cnpj DROP NOT NULL;
ALTER TABLE public.empresas_dcg ADD COLUMN legado jsonb NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.lojas.legado IS
  'Resíduo de origem do ETL (ids e campos de controle de cada sistema legado). Não usar em regra de negócio.';

-- Schema de controle da migração: só service_role.
CREATE SCHEMA migracao;
REVOKE ALL ON SCHEMA migracao FROM PUBLIC, anon, authenticated;

CREATE TABLE migracao.id_map (
  sistema text NOT NULL,
  colecao text NOT NULL,
  pb_id text NOT NULL,
  tabela text NOT NULL,
  uuid uuid NOT NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (sistema, colecao, pb_id)
);
CREATE INDEX idx_id_map_uuid ON migracao.id_map (tabela, uuid);

COMMENT ON TABLE migracao.id_map IS
  'De-para id PocketBase → uuid. Vários registros legados podem apontar para o mesmo mestre.';

CREATE TABLE migracao.pendencias (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sistema text NOT NULL,
  colecao text NOT NULL,
  pb_id text NOT NULL,
  motivo text NOT NULL,
  candidatos jsonb,
  resolvido_uuid uuid,
  resolvido_por text,
  resolvido_em timestamptz,
  criado_em timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE migracao.pendencias IS
  'Casamentos que o ETL não resolveu com segurança (ex.: duas lojas com o mesmo nome). Revisão humana.';
