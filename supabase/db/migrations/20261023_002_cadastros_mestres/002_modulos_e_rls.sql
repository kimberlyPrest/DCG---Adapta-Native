-- Migration 20261023_002 - SPEC-002 Parte 2
-- Modulos donos dos cadastros mestres, funcao de escopo por industria e RLS.

INSERT INTO public.modulos (system_id, chave, nome, descricao, ordem)
SELECT s.id, m.chave, m.nome, m.descricao, m.ordem
FROM public.systems s
JOIN (VALUES
  ('io', 'cadastros', 'Cadastros', 'Redes, lojas, indústrias, produtos, colaboradores e aliases.', 90),
  ('crm', 'clientes', 'Clientes', 'Indústrias clientes e prospects.', 10),
  ('margem-real', 'empresa', 'Minha empresa', 'CNPJs do grupo DCG.', 90)
) AS m(slug, chave, nome, descricao, ordem) ON m.slug = s.slug
ON CONFLICT (system_id, chave) DO UPDATE
SET nome = EXCLUDED.nome, descricao = EXCLUDED.descricao, ordem = EXCLUDED.ordem;

INSERT INTO public.modulo_acoes (modulo_id, chave)
SELECT m.id, a.chave
FROM public.modulos m
JOIN public.systems s ON s.id = m.system_id
CROSS JOIN (VALUES ('visualizar'), ('criar'), ('editar'), ('deletar')) AS a(chave)
WHERE (s.slug, m.chave) IN (('io', 'cadastros'), ('crm', 'clientes'), ('margem-real', 'empresa'))
ON CONFLICT (modulo_id, chave) DO NOTHING;

CREATE OR REPLACE FUNCTION public.pode_ver_industria(p_industria_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM usuarios u
    WHERE u.id = auth.uid()
      AND u.ativo
      AND (
        u.tipo = 'interno'
        OR EXISTS (
          SELECT 1 FROM usuario_industrias ui
          WHERE ui.usuario_id = u.id AND ui.industria_id = p_industria_id
        )
      )
  );
$$;

COMMENT ON FUNCTION public.pode_ver_industria(uuid) IS
'SPEC-002. Equipe interna ve todas; usuario de industria so as suas. Use no SELECT de toda tabela com industria_id.';

REVOKE ALL ON FUNCTION public.pode_ver_industria(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.pode_ver_industria(uuid) TO authenticated, service_role;

ALTER TABLE public.empresas_dcg ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.redes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lojas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.industrias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.colaboradores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cadastro_aliases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuario_industrias ENABLE ROW LEVEL SECURITY;

-- empresas_dcg: interno le; margem-real/empresa escreve.
CREATE POLICY empresas_dcg_select ON public.empresas_dcg FOR SELECT TO authenticated
  USING ((SELECT public.hub_usuario_interno()));
CREATE POLICY empresas_dcg_insert ON public.empresas_dcg FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'empresa', 'criar')));
CREATE POLICY empresas_dcg_update ON public.empresas_dcg FOR UPDATE TO authenticated
  USING ((SELECT public.hub_pode_executar('margem-real', 'empresa', 'editar')))
  WITH CHECK ((SELECT public.hub_pode_executar('margem-real', 'empresa', 'editar')));
CREATE POLICY empresas_dcg_delete ON public.empresas_dcg FOR DELETE TO authenticated
  USING ((SELECT public.hub_pode_executar('margem-real', 'empresa', 'deletar')));

-- redes e lojas: qualquer usuario ativo le (inclusive industria); io/cadastros escreve.
CREATE POLICY redes_select ON public.redes FOR SELECT TO authenticated
  USING ((SELECT public.hub_usuario_ativo()));
CREATE POLICY redes_insert ON public.redes FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'criar')));
CREATE POLICY redes_update ON public.redes FOR UPDATE TO authenticated
  USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar')))
  WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar')));
CREATE POLICY redes_delete ON public.redes FOR DELETE TO authenticated
  USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'deletar')));

CREATE POLICY lojas_select ON public.lojas FOR SELECT TO authenticated
  USING ((SELECT public.hub_usuario_ativo()));
CREATE POLICY lojas_insert ON public.lojas FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'criar')));
CREATE POLICY lojas_update ON public.lojas FOR UPDATE TO authenticated
  USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar')))
  WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar')));
CREATE POLICY lojas_delete ON public.lojas FOR DELETE TO authenticated
  USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'deletar')));

-- industrias: escopo por industria na leitura; io/cadastros ou crm/clientes escreve.
CREATE POLICY industrias_select ON public.industrias FOR SELECT TO authenticated
  USING (public.pode_ver_industria(id));
CREATE POLICY industrias_insert ON public.industrias FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT public.hub_pode_executar('io', 'cadastros', 'criar'))
    OR (SELECT public.hub_pode_executar('crm', 'clientes', 'criar'))
  );
CREATE POLICY industrias_update ON public.industrias FOR UPDATE TO authenticated
  USING (
    (SELECT public.hub_pode_executar('io', 'cadastros', 'editar'))
    OR (SELECT public.hub_pode_executar('crm', 'clientes', 'editar'))
  )
  WITH CHECK (
    (SELECT public.hub_pode_executar('io', 'cadastros', 'editar'))
    OR (SELECT public.hub_pode_executar('crm', 'clientes', 'editar'))
  );
CREATE POLICY industrias_delete ON public.industrias FOR DELETE TO authenticated
  USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'deletar')));

-- produtos: escopo pela industria do produto; io/cadastros escreve.
CREATE POLICY produtos_select ON public.produtos FOR SELECT TO authenticated
  USING (public.pode_ver_industria(industria_id));
CREATE POLICY produtos_insert ON public.produtos FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'criar')));
CREATE POLICY produtos_update ON public.produtos FOR UPDATE TO authenticated
  USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar')))
  WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar')));
CREATE POLICY produtos_delete ON public.produtos FOR DELETE TO authenticated
  USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'deletar')));

-- colaboradores e aliases: so equipe interna le; io/cadastros escreve.
CREATE POLICY colaboradores_select ON public.colaboradores FOR SELECT TO authenticated
  USING ((SELECT public.hub_usuario_interno()));
CREATE POLICY colaboradores_insert ON public.colaboradores FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'criar')));
CREATE POLICY colaboradores_update ON public.colaboradores FOR UPDATE TO authenticated
  USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar')))
  WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar')));
CREATE POLICY colaboradores_delete ON public.colaboradores FOR DELETE TO authenticated
  USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'deletar')));

CREATE POLICY cadastro_aliases_select ON public.cadastro_aliases FOR SELECT TO authenticated
  USING ((SELECT public.hub_usuario_interno()));
CREATE POLICY cadastro_aliases_write ON public.cadastro_aliases FOR ALL TO authenticated
  USING ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar')))
  WITH CHECK ((SELECT public.hub_pode_executar('io', 'cadastros', 'editar')));

-- usuario_industrias: cada um ve o proprio escopo; Central DP/usuarios administra.
CREATE POLICY usuario_industrias_select ON public.usuario_industrias FOR SELECT TO authenticated
  USING (usuario_id = auth.uid() OR (SELECT public.hub_pode_executar('hub', 'usuarios', 'visualizar')));
CREATE POLICY usuario_industrias_write ON public.usuario_industrias FOR ALL TO authenticated
  USING ((SELECT public.hub_pode_executar('hub', 'usuarios', 'editar')))
  WITH CHECK ((SELECT public.hub_pode_executar('hub', 'usuarios', 'editar')));

REVOKE ALL ON TABLE
  public.empresas_dcg, public.redes, public.lojas, public.industrias, public.produtos,
  public.colaboradores, public.cadastro_aliases, public.usuario_industrias
FROM anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE
  public.empresas_dcg, public.redes, public.lojas, public.industrias, public.produtos,
  public.colaboradores, public.cadastro_aliases, public.usuario_industrias
TO authenticated;
