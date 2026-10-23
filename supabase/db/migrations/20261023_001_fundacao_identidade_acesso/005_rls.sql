-- Migration 20261023_001 - SPEC-001 Parte 5
-- RLS das tabelas de identidade e acesso.
--
-- Modulos da Central DP (slug hub) que regem estas tabelas:
--   usuarios    -> usuarios
--   sistemas    -> systems, modulos, modulo_acoes
--   permissoes  -> papeis, papel_permissoes, usuario_papeis, usuario_permissao_excecoes
--   auditoria   -> auditoria_permissoes
-- Os sistemas-satelite nao leem estas tabelas direto: usam as RPCs hub_*.

ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.systems ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.modulos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.modulo_acoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.papeis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.papel_permissoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuario_papeis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuario_permissao_excecoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.auditoria_permissoes ENABLE ROW LEVEL SECURITY;

-- usuarios: cada um le o proprio perfil; equipe interna le nomes (para
-- responsavel, autor etc. em todos os sistemas); so a Central DP edita.
-- Insercao so pelo trigger de auth.users; exclusao so apagando o auth.users.
CREATE POLICY usuarios_select ON public.usuarios FOR SELECT TO authenticated
  USING (id = auth.uid() OR (SELECT public.hub_usuario_interno()));

CREATE POLICY usuarios_update ON public.usuarios FOR UPDATE TO authenticated
  USING ((SELECT public.hub_pode_executar('hub', 'usuarios', 'editar')))
  WITH CHECK ((SELECT public.hub_pode_executar('hub', 'usuarios', 'editar')));

-- systems/modulos/modulo_acoes: catalogo legivel por qualquer usuario ativo.
CREATE POLICY systems_select ON public.systems FOR SELECT TO authenticated
  USING ((SELECT public.hub_usuario_ativo()));
CREATE POLICY systems_insert ON public.systems FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.hub_pode_executar('hub', 'sistemas', 'criar')));
CREATE POLICY systems_update ON public.systems FOR UPDATE TO authenticated
  USING ((SELECT public.hub_pode_executar('hub', 'sistemas', 'editar')))
  WITH CHECK ((SELECT public.hub_pode_executar('hub', 'sistemas', 'editar')));
CREATE POLICY systems_delete ON public.systems FOR DELETE TO authenticated
  USING ((SELECT public.hub_pode_executar('hub', 'sistemas', 'deletar')));

CREATE POLICY modulos_select ON public.modulos FOR SELECT TO authenticated
  USING ((SELECT public.hub_usuario_ativo()));
CREATE POLICY modulos_write ON public.modulos FOR ALL TO authenticated
  USING ((SELECT public.hub_pode_executar('hub', 'sistemas', 'editar')))
  WITH CHECK ((SELECT public.hub_pode_executar('hub', 'sistemas', 'editar')));

CREATE POLICY modulo_acoes_select ON public.modulo_acoes FOR SELECT TO authenticated
  USING ((SELECT public.hub_usuario_ativo()));
CREATE POLICY modulo_acoes_write ON public.modulo_acoes FOR ALL TO authenticated
  USING ((SELECT public.hub_pode_executar('hub', 'sistemas', 'editar')))
  WITH CHECK ((SELECT public.hub_pode_executar('hub', 'sistemas', 'editar')));

-- Matriz de permissoes: so quem tem o modulo permissoes na Central DP.
CREATE POLICY papeis_select ON public.papeis FOR SELECT TO authenticated
  USING ((SELECT public.hub_pode_executar('hub', 'permissoes', 'visualizar')));
CREATE POLICY papeis_write ON public.papeis FOR ALL TO authenticated
  USING ((SELECT public.hub_pode_executar('hub', 'permissoes', 'editar')))
  WITH CHECK ((SELECT public.hub_pode_executar('hub', 'permissoes', 'editar')));

CREATE POLICY papel_permissoes_select ON public.papel_permissoes FOR SELECT TO authenticated
  USING ((SELECT public.hub_pode_executar('hub', 'permissoes', 'visualizar')));
CREATE POLICY papel_permissoes_write ON public.papel_permissoes FOR ALL TO authenticated
  USING ((SELECT public.hub_pode_executar('hub', 'permissoes', 'editar')))
  WITH CHECK ((SELECT public.hub_pode_executar('hub', 'permissoes', 'editar')));

CREATE POLICY usuario_papeis_select ON public.usuario_papeis FOR SELECT TO authenticated
  USING (usuario_id = auth.uid() OR (SELECT public.hub_pode_executar('hub', 'permissoes', 'visualizar')));
CREATE POLICY usuario_papeis_write ON public.usuario_papeis FOR ALL TO authenticated
  USING ((SELECT public.hub_pode_executar('hub', 'permissoes', 'editar')))
  WITH CHECK ((SELECT public.hub_pode_executar('hub', 'permissoes', 'editar')));

CREATE POLICY excecoes_select ON public.usuario_permissao_excecoes FOR SELECT TO authenticated
  USING (usuario_id = auth.uid() OR (SELECT public.hub_pode_executar('hub', 'permissoes', 'visualizar')));
CREATE POLICY excecoes_write ON public.usuario_permissao_excecoes FOR ALL TO authenticated
  USING ((SELECT public.hub_pode_executar('hub', 'permissoes', 'editar')))
  WITH CHECK ((SELECT public.hub_pode_executar('hub', 'permissoes', 'editar')));

-- Auditoria: somente leitura; gravacao so pelo trigger SECURITY DEFINER.
CREATE POLICY auditoria_permissoes_select ON public.auditoria_permissoes FOR SELECT TO authenticated
  USING ((SELECT public.hub_pode_executar('hub', 'auditoria', 'visualizar')));

REVOKE ALL ON TABLE
  public.usuarios, public.systems, public.modulos, public.modulo_acoes, public.papeis,
  public.papel_permissoes, public.usuario_papeis, public.usuario_permissao_excecoes,
  public.auditoria_permissoes
FROM anon;

GRANT SELECT, UPDATE ON TABLE public.usuarios TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE
  public.systems, public.modulos, public.modulo_acoes, public.papeis,
  public.papel_permissoes, public.usuario_papeis, public.usuario_permissao_excecoes
TO authenticated;
GRANT SELECT ON TABLE public.auditoria_permissoes TO authenticated;
