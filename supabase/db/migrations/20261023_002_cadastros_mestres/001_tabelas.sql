-- Migration 20261023_002 - SPEC-002 Parte 1
-- Cadastros mestres compartilhados pelos 5 sistemas.
--
-- Resolve o achado T-20 da analise (loja em 6 colecoes, promotor em 6,
-- industria em 6). Cada entidade existe uma vez; o sistema dono escreve,
-- os demais leem e referenciam por FK. Dono de cada tabela:
--   empresas_dcg          -> margem-real / empresa
--   redes, lojas, produtos, colaboradores, cadastro_aliases -> io / cadastros
--   industrias            -> io / cadastros  OU  crm / clientes
-- Dados especificos de um sistema ficam em tabela do proprio sistema com FK
-- para o mestre (ex.: books guarda imagem de referencia do produto; margem-real
-- guarda salario/PIX do colaborador).

CREATE TABLE public.empresas_dcg (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cnpj text NOT NULL UNIQUE CHECK (cnpj ~ '^[0-9]{14}$'),
  razao_social text NOT NULL,
  nome_fantasia text,
  ativo boolean NOT NULL DEFAULT true,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.empresas_dcg IS
'SPEC-002. CNPJs do grupo DCG (quem fatura/paga). Dono: margem-real. cnpj so digitos.';

CREATE TABLE public.redes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL UNIQUE,
  ativo boolean NOT NULL DEFAULT true,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.redes IS 'SPEC-002. Redes varejistas. Dono: io.';

CREATE TABLE public.lojas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rede_id uuid REFERENCES public.redes(id),
  nome text NOT NULL,
  codigo_tradepro text UNIQUE,
  cnpj text CHECK (cnpj IS NULL OR cnpj ~ '^[0-9]{14}$'),
  endereco text,
  cidade text,
  uf char(2),
  latitude numeric(9, 6),
  longitude numeric(9, 6),
  ativo boolean NOT NULL DEFAULT true,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.lojas IS 'SPEC-002. Lojas atendidas. Dono: io. codigo_tradepro liga a API do Trade Pro.';

CREATE INDEX idx_lojas_rede ON public.lojas (rede_id);

CREATE TABLE public.industrias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  razao_social text,
  cnpj text UNIQUE CHECK (cnpj IS NULL OR cnpj ~ '^[0-9]{14}$'),
  situacao text NOT NULL DEFAULT 'ativa' CHECK (situacao IN ('prospect', 'ativa', 'inativa')),
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.industrias IS
'SPEC-002. Industria/marca cliente da DCG. Unifica industry_registry (IO), brands (Books), clients/industrias (CRM) e clientes (Margem Real). prospect nasce no CRM; ativa = atendida em campo.';

CREATE TABLE public.produtos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  industria_id uuid NOT NULL REFERENCES public.industrias(id),
  sku text NOT NULL,
  ean text,
  descricao text NOT NULL,
  ativo boolean NOT NULL DEFAULT true,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (industria_id, sku)
);

COMMENT ON TABLE public.produtos IS 'SPEC-002. Produto/SKU por industria. Dono: io.';

CREATE TABLE public.colaboradores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  funcao text NOT NULL CHECK (funcao IN ('promotor', 'supervisor', 'coordenador', 'outro')),
  supervisor_id uuid REFERENCES public.colaboradores(id),
  usuario_id uuid UNIQUE REFERENCES public.usuarios(id) ON DELETE SET NULL,
  codigo_tradepro text UNIQUE,
  telefone text,
  vinculo text CHECK (vinculo IN ('clt', 'mei', 'terceirizado')),
  situacao text NOT NULL DEFAULT 'ativo' CHECK (situacao IN ('ativo', 'afastado', 'desligado')),
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.colaboradores IS
'SPEC-002. Equipe de campo (promotores, supervisores). Dono: io. Dado de pagamento (salario, PIX, banco) NAO fica aqui: fica no Margem Real com FK para esta tabela. usuario_id preenchido quando a pessoa tambem acessa os sistemas.';

CREATE INDEX idx_colaboradores_supervisor ON public.colaboradores (supervisor_id);

CREATE TABLE public.cadastro_aliases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entidade text NOT NULL CHECK (entidade IN ('rede', 'loja', 'industria', 'produto', 'colaborador')),
  entidade_id uuid NOT NULL,
  origem text NOT NULL,
  valor text NOT NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (entidade, origem, valor)
);

COMMENT ON TABLE public.cadastro_aliases IS
'SPEC-002. Nomes alternativos vindos de fontes externas (tradepro, planilha, whatsapp...) apontando para o cadastro mestre. Substitui store_aliases/network_aliases/product_aliases da IO.';

CREATE INDEX idx_cadastro_aliases_entidade ON public.cadastro_aliases (entidade, entidade_id);

-- Escopo de usuario de industria (achado T-09: escopo so na tela).
CREATE TABLE public.usuario_industrias (
  usuario_id uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  industria_id uuid NOT NULL REFERENCES public.industrias(id) ON DELETE CASCADE,
  PRIMARY KEY (usuario_id, industria_id)
);

COMMENT ON TABLE public.usuario_industrias IS
'SPEC-002. Industrias que um usuario tipo=industria pode ver. Usuario de industria sem linha aqui nao ve nada.';

CREATE TRIGGER trg_empresas_dcg_atualizado_em BEFORE UPDATE ON public.empresas_dcg FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE TRIGGER trg_redes_atualizado_em BEFORE UPDATE ON public.redes FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE TRIGGER trg_lojas_atualizado_em BEFORE UPDATE ON public.lojas FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE TRIGGER trg_industrias_atualizado_em BEFORE UPDATE ON public.industrias FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE TRIGGER trg_produtos_atualizado_em BEFORE UPDATE ON public.produtos FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE TRIGGER trg_colaboradores_atualizado_em BEFORE UPDATE ON public.colaboradores FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();

CREATE TRIGGER trg_auditoria_usuario_industrias
  AFTER INSERT OR UPDATE OR DELETE ON public.usuario_industrias
  FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_permissoes();
