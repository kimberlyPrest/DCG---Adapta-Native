-- Migration 20261023_001 - SPEC-001 Parte 2
-- Catalogo de sistemas e matriz de permissoes (sistema -> modulo -> acao).
--
-- Mesmo desenho da SPEC-006 do Lucenera, com as correcoes que la vieram depois:
-- - acao nao e lista fechada (Lucenera precisou de 'aprovar' depois); validada por formato;
-- - excecao aceita acao NULL (todas as acoes);
-- - coluna valido_ate sem acento;
-- - usuario_papeis com auditoria pela mesma funcao generica.

CREATE TABLE public.systems (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  nome text NOT NULL,
  descricao text,
  url text,
  icone text,
  ordem integer NOT NULL DEFAULT 0,
  visivel_no_hub boolean NOT NULL DEFAULT true,
  ativo boolean NOT NULL DEFAULT true,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.systems IS
'SPEC-001. Sistemas do ecossistema. slug e o identificador estavel usado por hub_pode_executar e pelo SSO.';
COMMENT ON COLUMN public.systems.visivel_no_hub IS
'false = sistema regido pela matriz mas sem card na Central DP (ex.: o proprio hub).';

CREATE TRIGGER trg_systems_atualizado_em
  BEFORE UPDATE ON public.systems
  FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();

CREATE TABLE public.modulos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  system_id uuid NOT NULL REFERENCES public.systems(id) ON DELETE CASCADE,
  chave text NOT NULL CHECK (chave ~ '^[a-z0-9_]+$'),
  nome text NOT NULL,
  descricao text,
  ordem integer NOT NULL DEFAULT 0,
  UNIQUE (system_id, chave)
);

COMMENT ON TABLE public.modulos IS
'SPEC-001. Modulos/abas de cada sistema. Cada sistema registra os seus na propria SPEC.';

CREATE TABLE public.modulo_acoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  modulo_id uuid NOT NULL REFERENCES public.modulos(id) ON DELETE CASCADE,
  chave text NOT NULL CHECK (chave ~ '^[a-z_]+$'),
  UNIQUE (modulo_id, chave)
);

COMMENT ON TABLE public.modulo_acoes IS
'SPEC-001. Catalogo das acoes existentes em cada modulo (visualizar, criar, editar, deletar, aprovar, exportar...). Alimenta a tela de permissoes e hub_minhas_permissoes.';

CREATE TABLE public.papeis (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chave text NOT NULL UNIQUE CHECK (chave ~ '^[a-z0-9_]+$'),
  nome text NOT NULL,
  descricao text,
  criado_em timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.papeis IS
'SPEC-001. Papeis configuraveis pela Central DP. O papel de chave admin tem acesso total implicito.';

CREATE TABLE public.papel_permissoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  papel_id uuid NOT NULL REFERENCES public.papeis(id) ON DELETE CASCADE,
  system_id uuid NOT NULL REFERENCES public.systems(id) ON DELETE CASCADE,
  modulo_id uuid REFERENCES public.modulos(id) ON DELETE CASCADE,
  acao text CHECK (acao ~ '^[a-z_]+$')
);

COMMENT ON TABLE public.papel_permissoes IS
'SPEC-001. modulo_id NULL = todos os modulos do sistema; acao NULL = todas as acoes.';

CREATE UNIQUE INDEX papel_permissoes_uniq ON public.papel_permissoes (
  papel_id,
  system_id,
  COALESCE(modulo_id, '00000000-0000-0000-0000-000000000000'::uuid),
  COALESCE(acao, '*')
);

CREATE TABLE public.usuario_papeis (
  usuario_id uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  papel_id uuid NOT NULL REFERENCES public.papeis(id) ON DELETE CASCADE,
  atribuido_por uuid REFERENCES public.usuarios(id),
  atribuido_em timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (usuario_id, papel_id)
);

COMMENT ON TABLE public.usuario_papeis IS
'SPEC-001. Um usuario pode ter mais de um papel; as permissoes somam.';

CREATE TABLE public.usuario_permissao_excecoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  system_id uuid NOT NULL REFERENCES public.systems(id) ON DELETE CASCADE,
  modulo_id uuid REFERENCES public.modulos(id) ON DELETE CASCADE,
  acao text CHECK (acao ~ '^[a-z_]+$'),
  tipo text NOT NULL CHECK (tipo IN ('conceder', 'negar')),
  justificativa text NOT NULL,
  valido_ate timestamptz,
  criado_por uuid REFERENCES public.usuarios(id),
  criado_em timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.usuario_permissao_excecoes IS
'SPEC-001. Excecao individual. negar prevalece sobre conceder, que prevalece sobre papel. modulo_id/acao NULL = todos.';

CREATE INDEX idx_excecoes_usuario ON public.usuario_permissao_excecoes (usuario_id, system_id);

CREATE TABLE public.auditoria_permissoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  autor_id uuid,
  entidade text NOT NULL,
  entidade_id uuid,
  operacao text NOT NULL,
  antes jsonb,
  depois jsonb,
  criado_em timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.auditoria_permissoes IS
'SPEC-001. Trilha automatica de alteracoes em usuarios, papeis, permissoes, atribuicoes e excecoes. Somente leitura pela UI.';

CREATE INDEX idx_auditoria_permissoes_criado ON public.auditoria_permissoes (criado_em DESC);
