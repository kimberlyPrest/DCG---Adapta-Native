-- Migration 20261023_001 - SPEC-001 Parte 1
-- Identidade unica do ecossistema DCG: public.usuarios espelha auth.users.
--
-- Nao existe tabela de usuarios por sistema. Todo sistema le daqui.
-- Cadastro publico fica desligado em config.toml (enable_signup = false);
-- usuario nasce por convite da Central DP (Edge Function admin-convidar-usuario).

CREATE OR REPLACE FUNCTION public.set_atualizado_em()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.atualizado_em := now();
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.set_atualizado_em() IS
'SPEC-001. Trigger generico BEFORE UPDATE para manter atualizado_em.';

CREATE TABLE public.usuarios (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL UNIQUE,
  nome text NOT NULL,
  tipo text NOT NULL DEFAULT 'interno' CHECK (tipo IN ('interno', 'industria')),
  ativo boolean NOT NULL DEFAULT true,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.usuarios IS
'SPEC-001. Perfil unico do usuario em todos os sistemas DCG. id = auth.users.id.';
COMMENT ON COLUMN public.usuarios.tipo IS
'interno = equipe DCG; industria = usuario externo restrito as industrias de usuario_industrias (SPEC-002).';
COMMENT ON COLUMN public.usuarios.ativo IS
'false bloqueia o acesso em todos os sistemas: hub_pode_executar retorna false para usuario inativo.';

CREATE TRIGGER trg_usuarios_atualizado_em
  BEFORE UPDATE ON public.usuarios
  FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();

-- Cria o perfil quando o auth.users nasce (convite ou criacao pelo painel).
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.usuarios (id, email, nome, tipo)
  VALUES (
    NEW.id,
    lower(NEW.email),
    COALESCE(
      NULLIF(NEW.raw_user_meta_data->>'nome', ''),
      NULLIF(NEW.raw_user_meta_data->>'name', ''),
      split_part(NEW.email, '@', 1)
    ),
    CASE WHEN NEW.raw_user_meta_data->>'tipo' = 'industria' THEN 'industria' ELSE 'interno' END
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- Usuarios criados antes deste trigger (ex.: seeds das bases Skip de
-- 2026-10-23, que inserem direto em auth.users). Metadata dessas bases usa
-- "name", nao "nome".
INSERT INTO public.usuarios (id, email, nome, tipo)
SELECT
  au.id,
  lower(au.email),
  COALESCE(
    NULLIF(au.raw_user_meta_data->>'nome', ''),
    NULLIF(au.raw_user_meta_data->>'name', ''),
    split_part(au.email, '@', 1)
  ),
  CASE WHEN au.raw_user_meta_data->>'tipo' = 'industria' THEN 'industria' ELSE 'interno' END
FROM auth.users au
WHERE au.email IS NOT NULL
ON CONFLICT (id) DO NOTHING;

-- Mantem o e-mail sincronizado quando o usuario troca e-mail no auth.
CREATE OR REPLACE FUNCTION public.handle_auth_user_email_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.email IS DISTINCT FROM OLD.email THEN
    UPDATE public.usuarios SET email = lower(NEW.email) WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_email_changed
  AFTER UPDATE OF email ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_auth_user_email_change();
