-- Migration 20261024_010 — PLANO-UNIFICACAO-BANCO U2 (storage)
-- Buckets privados por sistema/módulo. O caminho do arquivo fica na coluna da
-- tabela (campos "file" do PocketBase). Acesso pela mesma matriz de permissões.

INSERT INTO storage.buckets (id, name, public) VALUES
  ('io', 'io', false),
  ('books', 'books', false),
  ('crm', 'crm', false),
  ('mr-financeiro', 'mr-financeiro', false),
  ('mr-pessoal', 'mr-pessoal', false),
  ('rh', 'rh', false),
  ('trade', 'trade', false),
  ('ocorrencias', 'ocorrencias', false),
  ('whatsapp', 'whatsapp', false)
ON CONFLICT (id) DO NOTHING;

CREATE OR REPLACE FUNCTION public.storage_pode(p_bucket text, p_acao text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT CASE p_bucket
    WHEN 'io' THEN public.hub_pode_executar('io', NULL, p_acao)
    WHEN 'books' THEN public.hub_pode_executar('books', NULL, p_acao)
    WHEN 'crm' THEN public.hub_pode_executar('crm', 'comercial', p_acao)
    WHEN 'mr-financeiro' THEN public.hub_pode_executar('margem-real', 'financeiro', p_acao)
    WHEN 'mr-pessoal' THEN public.hub_pode_executar('margem-real', 'pessoal', p_acao)
    WHEN 'rh' THEN public.hub_pode_executar('crm', 'rh', p_acao)
    WHEN 'trade' THEN public.hub_pode_executar('crm', 'trade', p_acao)
    WHEN 'ocorrencias' THEN public.hub_pode_executar('hub', 'ocorrencias', p_acao)
    WHEN 'whatsapp' THEN public.hub_pode_executar('hub', 'whatsapp', p_acao)
    ELSE false
  END;
$$;

COMMENT ON FUNCTION public.storage_pode(text, text) IS
  'Mapa bucket → sistema/módulo. Bucket novo precisa entrar aqui, senão ninguém acessa.';

REVOKE ALL ON FUNCTION public.storage_pode(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.storage_pode(text, text) TO authenticated, service_role;

CREATE POLICY dcg_storage_select ON storage.objects FOR SELECT TO authenticated
  USING (public.storage_pode(bucket_id, 'visualizar'));
CREATE POLICY dcg_storage_insert ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (public.storage_pode(bucket_id, 'criar'));
CREATE POLICY dcg_storage_update ON storage.objects FOR UPDATE TO authenticated
  USING (public.storage_pode(bucket_id, 'editar'))
  WITH CHECK (public.storage_pode(bucket_id, 'editar'));
CREATE POLICY dcg_storage_delete ON storage.objects FOR DELETE TO authenticated
  USING (public.storage_pode(bucket_id, 'deletar'));
