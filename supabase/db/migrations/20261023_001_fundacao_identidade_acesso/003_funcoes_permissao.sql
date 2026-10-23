-- Migration 20261023_001 - SPEC-001 Parte 3
-- Contrato de permissao do ecossistema.
--
-- Semantica (corrige os bugs que o Lucenera teve com NULL - SPEC-069/085 de la):
-- - p_modulo_chave NULL = "algum modulo do sistema"; p_acao NULL = "alguma acao".
--   Ex.: hub_pode_executar('crm') responde "pode abrir o CRM?".
-- - Grant/excecao com modulo_id NULL ou acao NULL vale para todos.
-- - Ordem: usuario inativo -> false; admin -> true; negar que cobre a pergunta -> false;
--   conceder ou papel que cubra a pergunta e nao esteja negado -> true.
-- - Modulo inexistente -> false (erro de digitacao nunca vira acesso).
-- - Usa auth.uid(): o usuario so pergunta por si mesmo. A variante com
--   p_usuario_id fica restrita ao service_role (Edge Functions).

CREATE OR REPLACE FUNCTION public.hub_pode_executar_usuario(
  p_usuario_id uuid,
  p_system_slug text,
  p_modulo_chave text DEFAULT NULL,
  p_acao text DEFAULT NULL
) RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_system_id uuid;
  v_modulo_id uuid;
BEGIN
  IF p_usuario_id IS NULL OR p_system_slug IS NULL THEN
    RETURN false;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = p_usuario_id AND ativo) THEN
    RETURN false;
  END IF;

  SELECT id INTO v_system_id FROM systems WHERE slug = p_system_slug AND ativo;
  IF v_system_id IS NULL THEN
    RETURN false;
  END IF;

  IF p_modulo_chave IS NOT NULL THEN
    SELECT id INTO v_modulo_id FROM modulos WHERE system_id = v_system_id AND chave = p_modulo_chave;
    IF v_modulo_id IS NULL THEN
      RETURN false;
    END IF;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM usuario_papeis up
    JOIN papeis p ON p.id = up.papel_id
    WHERE up.usuario_id = p_usuario_id AND p.chave = 'admin'
  ) THEN
    RETURN true;
  END IF;

  -- Grants candidatos (papel ou excecao conceder) que tocam a pergunta.
  -- Cada grant e reduzido ao escopo efetivo (modulo/acao) e descartado se
  -- uma excecao negar vigente cobrir esse escopo.
  RETURN EXISTS (
    WITH grants AS (
      SELECT pp.modulo_id, pp.acao
      FROM usuario_papeis up
      JOIN papel_permissoes pp ON pp.papel_id = up.papel_id
      WHERE up.usuario_id = p_usuario_id
        AND pp.system_id = v_system_id
      UNION ALL
      SELECT e.modulo_id, e.acao
      FROM usuario_permissao_excecoes e
      WHERE e.usuario_id = p_usuario_id
        AND e.system_id = v_system_id
        AND e.tipo = 'conceder'
        AND (e.valido_ate IS NULL OR e.valido_ate > now())
    ),
    efetivos AS (
      SELECT COALESCE(v_modulo_id, g.modulo_id) AS modulo_id,
             COALESCE(p_acao, g.acao) AS acao
      FROM grants g
      WHERE (v_modulo_id IS NULL OR g.modulo_id IS NULL OR g.modulo_id = v_modulo_id)
        AND (p_acao IS NULL OR g.acao IS NULL OR g.acao = p_acao)
    )
    SELECT 1
    FROM efetivos ef
    WHERE NOT EXISTS (
      SELECT 1
      FROM usuario_permissao_excecoes n
      WHERE n.usuario_id = p_usuario_id
        AND n.system_id = v_system_id
        AND n.tipo = 'negar'
        AND (n.valido_ate IS NULL OR n.valido_ate > now())
        AND (n.modulo_id IS NULL OR n.modulo_id = ef.modulo_id)
        AND (n.acao IS NULL OR n.acao = ef.acao)
    )
  );
END;
$$;

COMMENT ON FUNCTION public.hub_pode_executar_usuario(uuid, text, text, text) IS
'SPEC-001. Versao com usuario explicito, so para service_role (Edge Functions). Sistemas e RLS usam hub_pode_executar.';

CREATE OR REPLACE FUNCTION public.hub_pode_executar(
  p_system_slug text,
  p_modulo_chave text DEFAULT NULL,
  p_acao text DEFAULT NULL
) RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.hub_pode_executar_usuario(auth.uid(), p_system_slug, p_modulo_chave, p_acao);
$$;

COMMENT ON FUNCTION public.hub_pode_executar(text, text, text) IS
'SPEC-001. Contrato unico de permissao do ecossistema DCG para o usuario logado. Em RLS, chamar como (SELECT public.hub_pode_executar(...)) para ser avaliado uma vez por consulta.';

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM usuarios u
    JOIN usuario_papeis up ON up.usuario_id = u.id
    JOIN papeis p ON p.id = up.papel_id
    WHERE u.id = auth.uid() AND u.ativo AND p.chave = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.hub_usuario_ativo()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND ativo);
$$;

CREATE OR REPLACE FUNCTION public.hub_usuario_interno()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND ativo AND tipo = 'interno');
$$;

COMMENT ON FUNCTION public.hub_usuario_interno() IS
'SPEC-001. Usuario ativo da equipe DCG (nao e usuario de industria). Use em RLS de dado interno.';

CREATE OR REPLACE FUNCTION public.hub_sistemas_permitidos()
RETURNS SETOF public.systems
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT s.*
  FROM systems s
  WHERE s.ativo
    AND s.visivel_no_hub
    AND public.hub_pode_executar(s.slug)
  ORDER BY s.ordem, s.nome;
$$;

COMMENT ON FUNCTION public.hub_sistemas_permitidos() IS
'SPEC-001. Cards da Central DP e menu de troca de sistema: sistemas que o usuario logado pode abrir.';

CREATE OR REPLACE FUNCTION public.hub_minhas_permissoes(p_system_slug text)
RETURNS TABLE (modulo text, acao text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT m.chave, a.chave
  FROM systems s
  JOIN modulos m ON m.system_id = s.id
  JOIN modulo_acoes a ON a.modulo_id = m.id
  WHERE s.slug = p_system_slug
    AND public.hub_pode_executar(s.slug, m.chave, a.chave)
  ORDER BY m.ordem, m.chave, a.chave;
$$;

COMMENT ON FUNCTION public.hub_minhas_permissoes(text) IS
'SPEC-001. Lista (modulo, acao) liberados ao usuario logado num sistema. O front carrega uma vez e esconde abas/botoes.';

REVOKE ALL ON FUNCTION public.hub_pode_executar_usuario(uuid, text, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.hub_pode_executar_usuario(uuid, text, text, text) TO service_role;

REVOKE ALL ON FUNCTION public.hub_pode_executar(text, text, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.hub_usuario_ativo() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.hub_usuario_interno() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.hub_sistemas_permitidos() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.hub_minhas_permissoes(text) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.hub_pode_executar(text, text, text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.hub_usuario_ativo() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.hub_usuario_interno() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.hub_sistemas_permitidos() TO authenticated;
GRANT EXECUTE ON FUNCTION public.hub_minhas_permissoes(text) TO authenticated;
