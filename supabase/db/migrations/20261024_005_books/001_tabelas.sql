-- Migration 20261024_005_books — GERADA por scripts/unificacao/gerar_migrations.py. Não editar à mão:
-- ajuste o gerador e gere de novo. Origem: schema.json de produção (2026-10-21/22).

INSERT INTO public.modulos (system_id, chave, nome)
SELECT s.id, m.chave, m.nome FROM public.systems s
CROSS JOIN (VALUES ('agenda', 'Agenda de visitas'), ('books', 'Books'), ('cadastros', 'Cadastros'), ('regras', 'Regras de auditoria'), ('rupturas', 'Rupturas'), ('sortimento', 'Sortimento e preços')) AS m(chave, nome)
WHERE s.slug = 'books'
ON CONFLICT (system_id, chave) DO UPDATE SET nome = EXCLUDED.nome;

INSERT INTO public.modulo_acoes (modulo_id, chave)
SELECT m.id, a.chave FROM public.modulos m JOIN public.systems s ON s.id = m.system_id
CROSS JOIN (VALUES ('visualizar'), ('criar'), ('editar'), ('deletar')) AS a(chave)
WHERE s.slug = 'books'
ON CONFLICT (modulo_id, chave) DO NOTHING;

-- books.assortment_matrix
CREATE TABLE public.books_assortment_matrix (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  brand uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  sku uuid REFERENCES public.produtos(id) ON DELETE SET NULL,
  network text,
  store uuid REFERENCES public.lojas(id) ON DELETE SET NULL,
  status text,
  start_date timestamptz,
  end_date timestamptz,
  min_facings numeric,
  notes text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.books_assortment_matrix IS 'Origem: books.assortment_matrix (PocketBase). Dono: books/sortimento.';
COMMENT ON COLUMN public.books_assortment_matrix.brand IS 'Relação legada → brands';
COMMENT ON COLUMN public.books_assortment_matrix.sku IS 'Relação legada → skus';
COMMENT ON COLUMN public.books_assortment_matrix.store IS 'Relação legada → stores';
COMMENT ON COLUMN public.books_assortment_matrix.status IS 'Valores: obrigatorio | opcional | nao_trabalhado | aguardando_confirmacao';
CREATE TRIGGER trg_books_assortment_matrix_atualizado_em BEFORE UPDATE ON public.books_assortment_matrix FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX books_assortment_matrix_brand_idx ON public.books_assortment_matrix (brand);
CREATE INDEX books_assortment_matrix_sku_idx ON public.books_assortment_matrix (sku);
CREATE INDEX books_assortment_matrix_store_idx ON public.books_assortment_matrix (store);
CREATE INDEX books_assortment_matrix_network_idx ON public.books_assortment_matrix (network);
CREATE INDEX books_assortment_matrix_status_idx ON public.books_assortment_matrix (status);
ALTER TABLE public.books_assortment_matrix ENABLE ROW LEVEL SECURITY;
CREATE POLICY books_assortment_matrix_select ON public.books_assortment_matrix FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('books', 'sortimento', 'visualizar')) AND public.pode_ver_industria(brand));
CREATE POLICY books_assortment_matrix_insert ON public.books_assortment_matrix FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('books', 'sortimento', 'criar')));
CREATE POLICY books_assortment_matrix_update ON public.books_assortment_matrix FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'sortimento', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('books', 'sortimento', 'editar')));
CREATE POLICY books_assortment_matrix_delete ON public.books_assortment_matrix FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'sortimento', 'deletar')));
REVOKE ALL ON TABLE public.books_assortment_matrix FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.books_assortment_matrix TO authenticated;

-- books.audit_rules
CREATE TABLE public.books_audit_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  brand uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  title text,
  criteria text,
  mandatory_layout text,
  requires_splash boolean DEFAULT false,
  min_facings numeric,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.books_audit_rules IS 'Origem: books.audit_rules (PocketBase). Dono: books/regras.';
COMMENT ON COLUMN public.books_audit_rules.brand IS 'Relação legada → brands';
CREATE TRIGGER trg_books_audit_rules_atualizado_em BEFORE UPDATE ON public.books_audit_rules FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX books_audit_rules_brand_idx ON public.books_audit_rules (brand);
ALTER TABLE public.books_audit_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY books_audit_rules_select ON public.books_audit_rules FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('books', 'regras', 'visualizar')) AND public.pode_ver_industria(brand));
CREATE POLICY books_audit_rules_insert ON public.books_audit_rules FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('books', 'regras', 'criar')));
CREATE POLICY books_audit_rules_update ON public.books_audit_rules FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'regras', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('books', 'regras', 'editar')));
CREATE POLICY books_audit_rules_delete ON public.books_audit_rules FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'regras', 'deletar')));
REVOKE ALL ON TABLE public.books_audit_rules FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.books_audit_rules TO authenticated;

-- books.books
CREATE TABLE public.books_books (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  title text,
  brand uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  analyst uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  file_name text,
  file_size numeric,
  audit_date timestamptz,
  audit_frequency text,
  total_slides numeric,
  total_photos numeric,
  identified_stores numeric,
  pending_review numeric,
  missing_stores numeric,
  status text,
  missing_store_ids text,
  analysis_status text,
  analysis_summary text,
  analyzed_at timestamptz,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.books_books IS 'Origem: books.books (PocketBase). Dono: books/books.';
COMMENT ON COLUMN public.books_books.brand IS 'Relação legada → brands';
COMMENT ON COLUMN public.books_books.analyst IS 'Relação legada → users';
COMMENT ON COLUMN public.books_books.audit_frequency IS 'Valores: daily | seg_qua_sex | ter_qui_sab | seg_qua_sex_sab';
COMMENT ON COLUMN public.books_books.status IS 'Valores: processing | pending_review | reviewed | completed';
COMMENT ON COLUMN public.books_books.analysis_status IS 'Valores: pending | processing | completed';
CREATE TRIGGER trg_books_books_atualizado_em BEFORE UPDATE ON public.books_books FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX books_books_brand_idx ON public.books_books (brand);
CREATE INDEX books_books_analyst_idx ON public.books_books (analyst);
CREATE INDEX books_books_status_idx ON public.books_books (status);
CREATE INDEX books_books_criado_em_idx ON public.books_books (criado_em DESC);
ALTER TABLE public.books_books ENABLE ROW LEVEL SECURITY;
CREATE POLICY books_books_select ON public.books_books FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('books', 'books', 'visualizar')) AND public.pode_ver_industria(brand));
CREATE POLICY books_books_insert ON public.books_books FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('books', 'books', 'criar')));
CREATE POLICY books_books_update ON public.books_books FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'books', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('books', 'books', 'editar')));
CREATE POLICY books_books_delete ON public.books_books FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'books', 'deletar')));
REVOKE ALL ON TABLE public.books_books FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.books_books TO authenticated;

-- books.brands (identidade em industrias)
CREATE TABLE public.books_brands (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  industria_id uuid NOT NULL REFERENCES public.industrias(id) ON DELETE CASCADE,
  logo text,
  frequency text,
  stores uuid[],
  analysts uuid[],
  supervisors uuid[],
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (industria_id)
);
COMMENT ON TABLE public.books_brands IS 'Origem: books.brands (PocketBase). Dono: books/cadastros.';
COMMENT ON COLUMN public.books_brands.frequency IS 'Valores: diaria | seg_qua_sex | ter_qui_sab | seg_qua_sex_sab';
COMMENT ON COLUMN public.books_brands.stores IS 'Relação legada → stores';
COMMENT ON COLUMN public.books_brands.analysts IS 'Relação legada → users';
COMMENT ON COLUMN public.books_brands.supervisors IS 'Relação legada → users';
CREATE TRIGGER trg_books_brands_atualizado_em BEFORE UPDATE ON public.books_brands FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.books_brands ENABLE ROW LEVEL SECURITY;
CREATE POLICY books_brands_select ON public.books_brands FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('books', 'cadastros', 'visualizar')));
CREATE POLICY books_brands_insert ON public.books_brands FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('books', 'cadastros', 'criar')));
CREATE POLICY books_brands_update ON public.books_brands FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'cadastros', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('books', 'cadastros', 'editar')));
CREATE POLICY books_brands_delete ON public.books_brands FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'cadastros', 'deletar')));
REVOKE ALL ON TABLE public.books_brands FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.books_brands TO authenticated;

-- books.price_tables
CREATE TABLE public.books_price_tables (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  brand uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  sku uuid REFERENCES public.produtos(id) ON DELETE SET NULL,
  rede text,
  secao text,
  preco numeric,
  vigencia timestamptz,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.books_price_tables IS 'Origem: books.price_tables (PocketBase). Dono: books/sortimento.';
COMMENT ON COLUMN public.books_price_tables.brand IS 'Relação legada → brands';
COMMENT ON COLUMN public.books_price_tables.sku IS 'Relação legada → skus';
CREATE TRIGGER trg_books_price_tables_atualizado_em BEFORE UPDATE ON public.books_price_tables FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX books_price_tables_brand_sku_rede_secao_uk ON public.books_price_tables (brand, sku, rede, secao);
ALTER TABLE public.books_price_tables ENABLE ROW LEVEL SECURITY;
CREATE POLICY books_price_tables_select ON public.books_price_tables FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('books', 'sortimento', 'visualizar')) AND public.pode_ver_industria(brand));
CREATE POLICY books_price_tables_insert ON public.books_price_tables FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('books', 'sortimento', 'criar')));
CREATE POLICY books_price_tables_update ON public.books_price_tables FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'sortimento', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('books', 'sortimento', 'editar')));
CREATE POLICY books_price_tables_delete ON public.books_price_tables FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'sortimento', 'deletar')));
REVOKE ALL ON TABLE public.books_price_tables FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.books_price_tables TO authenticated;

-- books.promoters (identidade em colaboradores)
CREATE TABLE public.books_promoters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  colaborador_id uuid NOT NULL REFERENCES public.colaboradores(id) ON DELETE CASCADE,
  brands uuid[],
  stores uuid[],
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (colaborador_id)
);
COMMENT ON TABLE public.books_promoters IS 'Origem: books.promoters (PocketBase). Dono: books/cadastros.';
COMMENT ON COLUMN public.books_promoters.brands IS 'Relação legada → brands';
COMMENT ON COLUMN public.books_promoters.stores IS 'Relação legada → stores';
CREATE TRIGGER trg_books_promoters_atualizado_em BEFORE UPDATE ON public.books_promoters FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.books_promoters ENABLE ROW LEVEL SECURITY;
CREATE POLICY books_promoters_select ON public.books_promoters FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('books', 'cadastros', 'visualizar')));
CREATE POLICY books_promoters_insert ON public.books_promoters FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('books', 'cadastros', 'criar')));
CREATE POLICY books_promoters_update ON public.books_promoters FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'cadastros', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('books', 'cadastros', 'editar')));
CREATE POLICY books_promoters_delete ON public.books_promoters FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'cadastros', 'deletar')));
REVOKE ALL ON TABLE public.books_promoters FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.books_promoters TO authenticated;

-- books.rupture_reports
CREATE TABLE public.books_rupture_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  brand uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  store uuid REFERENCES public.lojas(id) ON DELETE SET NULL,
  sku uuid REFERENCES public.produtos(id) ON DELETE SET NULL,
  report_date timestamptz,
  rupture_type text,
  days_in_rupture numeric,
  scope text,
  brand_level_declared boolean DEFAULT false,
  requires_clarification boolean DEFAULT false,
  clarification_reason text,
  is_inferred boolean DEFAULT false,
  inference_notes text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.books_rupture_reports IS 'Origem: books.rupture_reports (PocketBase). Dono: books/rupturas.';
COMMENT ON COLUMN public.books_rupture_reports.brand IS 'Relação legada → brands';
COMMENT ON COLUMN public.books_rupture_reports.store IS 'Relação legada → stores';
COMMENT ON COLUMN public.books_rupture_reports.sku IS 'Relação legada → skus';
COMMENT ON COLUMN public.books_rupture_reports.rupture_type IS 'Valores: total | parcial | zerado';
COMMENT ON COLUMN public.books_rupture_reports.scope IS 'Valores: sku | brand_family';
CREATE TRIGGER trg_books_rupture_reports_atualizado_em BEFORE UPDATE ON public.books_rupture_reports FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX books_rupture_reports_brand_idx ON public.books_rupture_reports (brand);
CREATE INDEX books_rupture_reports_store_idx ON public.books_rupture_reports (store);
CREATE INDEX books_rupture_reports_sku_idx ON public.books_rupture_reports (sku);
CREATE INDEX books_rupture_reports_report_date_idx ON public.books_rupture_reports (report_date);
ALTER TABLE public.books_rupture_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY books_rupture_reports_select ON public.books_rupture_reports FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('books', 'rupturas', 'visualizar')) AND public.pode_ver_industria(brand));
CREATE POLICY books_rupture_reports_insert ON public.books_rupture_reports FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('books', 'rupturas', 'criar')));
CREATE POLICY books_rupture_reports_update ON public.books_rupture_reports FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'rupturas', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('books', 'rupturas', 'editar')));
CREATE POLICY books_rupture_reports_delete ON public.books_rupture_reports FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'rupturas', 'deletar')));
REVOKE ALL ON TABLE public.books_rupture_reports FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.books_rupture_reports TO authenticated;

-- books.skus (identidade em produtos)
CREATE TABLE public.books_skus (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
  image text,
  normal_price numeric,
  promo_price numeric,
  promo_start timestamptz,
  promo_end timestamptz,
  main_gondola boolean DEFAULT false,
  min_quantity numeric,
  requires_splash boolean DEFAULT false,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (produto_id)
);
COMMENT ON TABLE public.books_skus IS 'Origem: books.skus (PocketBase). Dono: books/cadastros.';
CREATE TRIGGER trg_books_skus_atualizado_em BEFORE UPDATE ON public.books_skus FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
ALTER TABLE public.books_skus ENABLE ROW LEVEL SECURITY;
CREATE POLICY books_skus_select ON public.books_skus FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('books', 'cadastros', 'visualizar')));
CREATE POLICY books_skus_insert ON public.books_skus FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('books', 'cadastros', 'criar')));
CREATE POLICY books_skus_update ON public.books_skus FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'cadastros', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('books', 'cadastros', 'editar')));
CREATE POLICY books_skus_delete ON public.books_skus FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'cadastros', 'deletar')));
REVOKE ALL ON TABLE public.books_skus FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.books_skus TO authenticated;

-- books.stores (identidade em lojas)
CREATE TABLE public.books_stores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  loja_id uuid NOT NULL REFERENCES public.lojas(id) ON DELETE CASCADE,
  number text,
  network text,
  region text,
  api_identifier text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (loja_id)
);
COMMENT ON TABLE public.books_stores IS 'Origem: books.stores (PocketBase). Dono: books/cadastros.';
COMMENT ON COLUMN public.books_stores.region IS 'Valores: Sul | Sudeste | Centro-Oeste | Nordeste | Norte';
CREATE TRIGGER trg_books_stores_atualizado_em BEFORE UPDATE ON public.books_stores FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE UNIQUE INDEX books_stores_number_uk ON public.books_stores (number);
ALTER TABLE public.books_stores ENABLE ROW LEVEL SECURITY;
CREATE POLICY books_stores_select ON public.books_stores FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('books', 'cadastros', 'visualizar')));
CREATE POLICY books_stores_insert ON public.books_stores FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('books', 'cadastros', 'criar')));
CREATE POLICY books_stores_update ON public.books_stores FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'cadastros', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('books', 'cadastros', 'editar')));
CREATE POLICY books_stores_delete ON public.books_stores FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'cadastros', 'deletar')));
REVOKE ALL ON TABLE public.books_stores FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.books_stores TO authenticated;

-- books.visit_schedules
CREATE TABLE public.books_visit_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  store uuid REFERENCES public.lojas(id) ON DELETE SET NULL,
  visit_date timestamptz,
  promoter uuid REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  brand uuid REFERENCES public.industrias(id) ON DELETE SET NULL,
  status text,
  shift text,
  origin text,
  checkin_time text,
  checkout_time text,
  is_inferred boolean DEFAULT false,
  ambiguous_conflict boolean DEFAULT false,
  conflict_notes text,
  notes text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.books_visit_schedules IS 'Origem: books.visit_schedules (PocketBase). Dono: books/agenda.';
COMMENT ON COLUMN public.books_visit_schedules.store IS 'Relação legada → stores';
COMMENT ON COLUMN public.books_visit_schedules.promoter IS 'Relação legada → promoters';
COMMENT ON COLUMN public.books_visit_schedules.brand IS 'Relação legada → brands';
COMMENT ON COLUMN public.books_visit_schedules.status IS 'Valores: sem_visita_agendada | agenda_desconhecida | visita_agendada_nao_confirmada | visita_confirmada_fotos_pendentes | visita_confirmada_evidencias';
COMMENT ON COLUMN public.books_visit_schedules.shift IS 'Valores: manha | tarde | integral';
COMMENT ON COLUMN public.books_visit_schedules.origin IS 'Valores: manual | import_planilha | api_tradepro';
CREATE TRIGGER trg_books_visit_schedules_atualizado_em BEFORE UPDATE ON public.books_visit_schedules FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX books_visit_schedules_store_idx ON public.books_visit_schedules (store);
CREATE INDEX books_visit_schedules_visit_date_idx ON public.books_visit_schedules (visit_date);
CREATE INDEX books_visit_schedules_promoter_idx ON public.books_visit_schedules (promoter);
CREATE INDEX books_visit_schedules_brand_idx ON public.books_visit_schedules (brand);
CREATE INDEX books_visit_schedules_status_idx ON public.books_visit_schedules (status);
ALTER TABLE public.books_visit_schedules ENABLE ROW LEVEL SECURITY;
CREATE POLICY books_visit_schedules_select ON public.books_visit_schedules FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('books', 'agenda', 'visualizar')) AND public.pode_ver_industria(brand));
CREATE POLICY books_visit_schedules_insert ON public.books_visit_schedules FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('books', 'agenda', 'criar')));
CREATE POLICY books_visit_schedules_update ON public.books_visit_schedules FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'agenda', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('books', 'agenda', 'editar')));
CREATE POLICY books_visit_schedules_delete ON public.books_visit_schedules FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'agenda', 'deletar')));
REVOKE ALL ON TABLE public.books_visit_schedules FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.books_visit_schedules TO authenticated;

-- books.book_photos
CREATE TABLE public.books_book_photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  book uuid REFERENCES public.books_books(id) ON DELETE SET NULL,
  slide_number numeric,
  photo_index numeric,
  image_data text,
  extracted_text text,
  identified_store uuid REFERENCES public.lojas(id) ON DELETE SET NULL,
  identified_store_name text,
  confidence numeric,
  needs_review boolean DEFAULT false,
  review_status text,
  reviewed_by uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  review_notes text,
  corrected_store uuid REFERENCES public.lojas(id) ON DELETE SET NULL,
  is_inferred boolean DEFAULT false,
  ambiguous_match boolean DEFAULT false,
  inferred_notes text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.books_book_photos IS 'Origem: books.book_photos (PocketBase). Dono: books/books.';
COMMENT ON COLUMN public.books_book_photos.book IS 'Relação legada → books';
COMMENT ON COLUMN public.books_book_photos.identified_store IS 'Relação legada → stores';
COMMENT ON COLUMN public.books_book_photos.review_status IS 'Valores: pending | approved | corrected';
COMMENT ON COLUMN public.books_book_photos.reviewed_by IS 'Relação legada → users';
COMMENT ON COLUMN public.books_book_photos.corrected_store IS 'Relação legada → stores';
CREATE TRIGGER trg_books_book_photos_atualizado_em BEFORE UPDATE ON public.books_book_photos FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX books_book_photos_book_idx ON public.books_book_photos (book);
CREATE INDEX books_book_photos_identified_store_idx ON public.books_book_photos (identified_store);
CREATE INDEX books_book_photos_needs_review_idx ON public.books_book_photos (needs_review);
ALTER TABLE public.books_book_photos ENABLE ROW LEVEL SECURITY;
CREATE POLICY books_book_photos_select ON public.books_book_photos FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('books', 'books', 'visualizar')));
CREATE POLICY books_book_photos_insert ON public.books_book_photos FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('books', 'books', 'criar')));
CREATE POLICY books_book_photos_update ON public.books_book_photos FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'books', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('books', 'books', 'editar')));
CREATE POLICY books_book_photos_delete ON public.books_book_photos FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'books', 'deletar')));
REVOKE ALL ON TABLE public.books_book_photos FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.books_book_photos TO authenticated;

-- books.sku_classifications
CREATE TABLE public.books_sku_classifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legado_id text UNIQUE,
  book uuid REFERENCES public.books_books(id) ON DELETE SET NULL,
  store uuid REFERENCES public.lojas(id) ON DELETE SET NULL,
  sku uuid REFERENCES public.produtos(id) ON DELETE SET NULL,
  category text,
  confidence text,
  similarity numeric,
  matched_photo uuid REFERENCES public.books_book_photos(id) ON DELETE SET NULL,
  reviewer uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  notes text,
  price_checked boolean DEFAULT false,
  price_match boolean DEFAULT false,
  price_observed text,
  price_expected text,
  missing_price_tag boolean DEFAULT false,
  missing_splash boolean DEFAULT false,
  reason_text text,
  evidence_photo_url text,
  presence_dimension text,
  coverage_dimension text,
  price_dimension text,
  rupture_dimension text,
  visit_dimension text,
  is_inferred_link boolean DEFAULT false,
  inferred_link_notes text,
  discrepancy_flag boolean DEFAULT false,
  assortment_status text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.books_sku_classifications IS 'Origem: books.sku_classifications (PocketBase). Dono: books/books.';
COMMENT ON COLUMN public.books_sku_classifications.book IS 'Relação legada → books';
COMMENT ON COLUMN public.books_sku_classifications.store IS 'Relação legada → stores';
COMMENT ON COLUMN public.books_sku_classifications.sku IS 'Relação legada → skus';
COMMENT ON COLUMN public.books_sku_classifications.category IS 'Valores: presente_pdv | nao_identificado | evidencia_insuficiente | sem_foto_secao | sem_foto_loja | nao_verificado | falha_tecnica | ruptura_justificada | validar_ruptura_antiga | ausente_cobrar';
COMMENT ON COLUMN public.books_sku_classifications.confidence IS 'Valores: alta | media | baixa';
COMMENT ON COLUMN public.books_sku_classifications.matched_photo IS 'Relação legada → book_photos';
COMMENT ON COLUMN public.books_sku_classifications.reviewer IS 'Relação legada → users';
COMMENT ON COLUMN public.books_sku_classifications.presence_dimension IS 'Valores: presente_com_evidencia | nao_identificado | evidencia_insuficiente | nao_verificado | ausente_confirmado';
COMMENT ON COLUMN public.books_sku_classifications.coverage_dimension IS 'Valores: cobertura_completa | secao_parcial | sem_foto_secao | sem_foto_loja';
COMMENT ON COLUMN public.books_sku_classifications.price_dimension IS 'Valores: conforme | divergente | sem_etiqueta | sem_splash | nao_verificado';
COMMENT ON COLUMN public.books_sku_classifications.rupture_dimension IS 'Valores: sem_ruptura | ruptura_justificada | ruptura_declarada_marca | validar_antiga | discrepancia_visivel_vs_declarada';
COMMENT ON COLUMN public.books_sku_classifications.visit_dimension IS 'Valores: visita_confirmada_evidencias | visita_confirmada_fotos_pendentes | visita_agendada_nao_confirmada | sem_visita_agendada | agenda_desconhecida';
COMMENT ON COLUMN public.books_sku_classifications.assortment_status IS 'Valores: obrigatorio | opcional | nao_trabalhado | aguardando_confirmacao';
CREATE TRIGGER trg_books_sku_classifications_atualizado_em BEFORE UPDATE ON public.books_sku_classifications FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();
CREATE INDEX books_sku_classifications_book_idx ON public.books_sku_classifications (book);
CREATE INDEX books_sku_classifications_store_idx ON public.books_sku_classifications (store);
CREATE INDEX books_sku_classifications_sku_idx ON public.books_sku_classifications (sku);
CREATE INDEX books_sku_classifications_category_idx ON public.books_sku_classifications (category);
CREATE INDEX books_sku_classifications_confidence_idx ON public.books_sku_classifications (confidence);
CREATE UNIQUE INDEX books_sku_classifications_book_store_sku_uk ON public.books_sku_classifications (book, store, sku);
ALTER TABLE public.books_sku_classifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY books_sku_classifications_select ON public.books_sku_classifications FOR SELECT TO authenticated USING ((SELECT public.hub_pode_executar('books', 'books', 'visualizar')));
CREATE POLICY books_sku_classifications_insert ON public.books_sku_classifications FOR INSERT TO authenticated WITH CHECK ((SELECT public.hub_pode_executar('books', 'books', 'criar')));
CREATE POLICY books_sku_classifications_update ON public.books_sku_classifications FOR UPDATE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'books', 'editar'))) WITH CHECK ((SELECT public.hub_pode_executar('books', 'books', 'editar')));
CREATE POLICY books_sku_classifications_delete ON public.books_sku_classifications FOR DELETE TO authenticated USING ((SELECT public.hub_pode_executar('books', 'books', 'deletar')));
REVOKE ALL ON TABLE public.books_sku_classifications FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.books_sku_classifications TO authenticated;
