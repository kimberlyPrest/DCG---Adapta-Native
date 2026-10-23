-- Migration 20261023_001 - SPEC-001 Parte 6
-- SSO entre sistemas (mesmo desenho da SPEC-007 do Lucenera).
--
-- Origem chama generate-cross-system-code (autenticada) e abre o destino com
-- ?sso_code=<uuid>. Destino chama exchange-cross-system-code antes de mostrar
-- o login. Codigo vale 60 s, uso unico. Token nunca trafega na URL.

CREATE TABLE public.cross_system_session_codes (
  code uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  sistema_origem text NOT NULL,
  sistema_destino text NOT NULL REFERENCES public.systems(slug) ON UPDATE CASCADE,
  contexto jsonb NOT NULL DEFAULT '{}'::jsonb,
  criado_em timestamptz NOT NULL DEFAULT now(),
  expira_em timestamptz NOT NULL DEFAULT (now() + interval '60 seconds'),
  usado_em timestamptz
);

COMMENT ON TABLE public.cross_system_session_codes IS
'SPEC-001. Codigo opaco de curta duracao e uso unico para abrir outro sistema sem novo login. Acesso so por service_role.';

CREATE INDEX idx_cross_system_codes_expira ON public.cross_system_session_codes (expira_em);

ALTER TABLE public.cross_system_session_codes ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.cross_system_session_codes FROM anon, authenticated;
