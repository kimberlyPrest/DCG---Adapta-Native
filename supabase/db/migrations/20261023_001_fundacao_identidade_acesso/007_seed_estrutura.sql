-- Migration 20261023_001 - SPEC-001 Parte 7
-- Seed de ESTRUTURA (nunca de pessoas, senhas ou dados reais).
--
-- - 5 sistemas do ecossistema (url preenchida pela Central DP apos o deploy);
-- - modulos da propria Central DP que regem identidade e acesso;
-- - papel admin (acesso total implicito).
-- Os modulos de IO, Books, CRM e Margem Real sao registrados na SPEC de cada
-- sistema. Os papeis de negocio (diretoria, supervisao, financeiro...) sao
-- criados pela UI depois do aceite dos perfis iniciais pelo champion.
-- O primeiro admin e atribuido pelo procedimento do README desta pasta.

INSERT INTO public.systems (slug, nome, descricao, icone, ordem, visivel_no_hub) VALUES
  ('hub', 'Central DP', 'Central de trabalho, usuarios e permissoes do ecossistema DCG.', 'LayoutDashboard', 0, false),
  ('io', 'Inteligência Operacional', 'Validades, rupturas, devoluções, visitas e cadastros mestres de campo.', 'Radar', 10, true),
  ('books', 'Auditoria de Books', 'Auditoria de execução por foto, notas por loja e ranking.', 'Images', 20, true),
  ('crm', 'CRM de Orçamento e Contratos', 'Clientes, propostas, contratos, regras operacionais e dimensionamento.', 'Handshake', 30, true),
  ('margem-real', 'Margem Real', 'Financeiro gerencial: DRE, contas, rateio e fechamento.', 'Wallet', 40, true)
ON CONFLICT (slug) DO UPDATE
SET nome = EXCLUDED.nome,
    descricao = EXCLUDED.descricao,
    icone = EXCLUDED.icone,
    ordem = EXCLUDED.ordem,
    visivel_no_hub = EXCLUDED.visivel_no_hub;

INSERT INTO public.modulos (system_id, chave, nome, descricao, ordem)
SELECT s.id, m.chave, m.nome, m.descricao, m.ordem
FROM public.systems s
CROSS JOIN (VALUES
  ('usuarios', 'Usuários', 'Convite, ativação e dados de usuários.', 10),
  ('permissoes', 'Permissões', 'Papéis, matriz de permissões e exceções.', 20),
  ('sistemas', 'Sistemas', 'Catálogo de sistemas, módulos e ações.', 30),
  ('auditoria', 'Auditoria', 'Trilha de alterações de acesso.', 40)
) AS m(chave, nome, descricao, ordem)
WHERE s.slug = 'hub'
ON CONFLICT (system_id, chave) DO UPDATE
SET nome = EXCLUDED.nome, descricao = EXCLUDED.descricao, ordem = EXCLUDED.ordem;

INSERT INTO public.modulo_acoes (modulo_id, chave)
SELECT m.id, a.chave
FROM public.modulos m
JOIN public.systems s ON s.id = m.system_id AND s.slug = 'hub'
JOIN (VALUES
  ('usuarios', 'visualizar'), ('usuarios', 'criar'), ('usuarios', 'editar'),
  ('permissoes', 'visualizar'), ('permissoes', 'editar'),
  ('sistemas', 'visualizar'), ('sistemas', 'criar'), ('sistemas', 'editar'), ('sistemas', 'deletar'),
  ('auditoria', 'visualizar')
) AS a(modulo, chave) ON a.modulo = m.chave
ON CONFLICT (modulo_id, chave) DO NOTHING;

INSERT INTO public.papeis (chave, nome, descricao)
VALUES ('admin', 'Administrador', 'Acesso total a todos os sistemas, módulos e ações.')
ON CONFLICT (chave) DO NOTHING;
