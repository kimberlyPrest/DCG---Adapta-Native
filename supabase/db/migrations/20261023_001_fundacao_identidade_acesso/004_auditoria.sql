-- Migration 20261023_001 - SPEC-001 Parte 4
-- Auditoria automatica de quem mudou acesso de quem.

CREATE OR REPLACE FUNCTION public.fn_auditoria_permissoes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_linha jsonb := to_jsonb(COALESCE(NEW, OLD));
BEGIN
  INSERT INTO public.auditoria_permissoes (autor_id, entidade, entidade_id, operacao, antes, depois)
  VALUES (
    auth.uid(),
    TG_TABLE_NAME,
    -- usuario_papeis nao tem id proprio: registra o usuario afetado.
    COALESCE(v_linha->>'id', v_linha->>'usuario_id')::uuid,
    TG_OP,
    CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) END,
    CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) END
  );
  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trg_auditoria_usuarios
  AFTER UPDATE OR DELETE ON public.usuarios
  FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_permissoes();

CREATE TRIGGER trg_auditoria_papeis
  AFTER INSERT OR UPDATE OR DELETE ON public.papeis
  FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_permissoes();

CREATE TRIGGER trg_auditoria_papel_permissoes
  AFTER INSERT OR UPDATE OR DELETE ON public.papel_permissoes
  FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_permissoes();

CREATE TRIGGER trg_auditoria_usuario_papeis
  AFTER INSERT OR UPDATE OR DELETE ON public.usuario_papeis
  FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_permissoes();

CREATE TRIGGER trg_auditoria_usuario_permissao_excecoes
  AFTER INSERT OR UPDATE OR DELETE ON public.usuario_permissao_excecoes
  FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_permissoes();

CREATE TRIGGER trg_auditoria_systems
  AFTER INSERT OR UPDATE OR DELETE ON public.systems
  FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_permissoes();
