import { PGlite } from '@electric-sql/pglite'
import { readFileSync, readdirSync } from 'node:fs'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'

const MIG = process.argv[2] ?? fileURLToPath(new URL("../db/migrations", import.meta.url))
const db = new PGlite()

// Stub minimo do ambiente Supabase.
await db.exec(`
  CREATE ROLE anon NOLOGIN; CREATE ROLE authenticated NOLOGIN; CREATE ROLE service_role NOLOGIN BYPASSRLS;
  CREATE SCHEMA storage;
  CREATE TABLE storage.buckets (id text PRIMARY KEY, name text, public boolean);
  CREATE TABLE storage.objects (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), bucket_id text, name text);
  ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
  GRANT USAGE ON SCHEMA storage TO authenticated;
  GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO authenticated;
  CREATE SCHEMA auth;
  CREATE TABLE auth.users (id uuid PRIMARY KEY, email text, raw_user_meta_data jsonb DEFAULT '{}');
  CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS
    $$ SELECT nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
  GRANT USAGE ON SCHEMA auth, public TO anon, authenticated, service_role;
  GRANT EXECUTE ON FUNCTION auth.uid() TO anon, authenticated, service_role;
  -- Usuario que ja existia antes das migrations (seed das bases Skip, metadata "name").
  INSERT INTO auth.users (id, email, raw_user_meta_data)
  VALUES ('00000000-0000-0000-0000-0000000000ee', 'Daniel@Exemplo.com', '{"name":"Daniel"}');
`)

// Aplica todas as migrations centrais em ordem, como no Supabase real.
for (const dir of readdirSync(MIG).filter((d) => /^[0-9]{8}_[0-9]{3}_/.test(d)).sort()) {
  for (const f of readdirSync(join(MIG, dir)).filter((f) => f.endsWith('.sql')).sort()) {
    try {
      await db.exec(readFileSync(join(MIG, dir, f), 'utf8'))
    } catch (e) {
      console.error(`FALHA em ${dir}/${f}: ${e.message}`)
      process.exit(1)
    }
  }
}
console.log('migrations aplicadas')

const U = {
  admin: '00000000-0000-0000-0000-00000000000a',
  sup: '00000000-0000-0000-0000-00000000000b',
  ind: '00000000-0000-0000-0000-00000000000c',
  inativo: '00000000-0000-0000-0000-00000000000d',
}
await db.exec(`
  INSERT INTO auth.users (id, email, raw_user_meta_data) VALUES
    ('${U.admin}', 'Admin@dcg.com', '{"nome":"Admin"}'),
    ('${U.sup}', 'sup@dcg.com', '{}'),
    ('${U.ind}', 'rep@industria.com', '{"tipo":"industria"}'),
    ('${U.inativo}', 'ex@dcg.com', '{}');
  UPDATE public.usuarios SET ativo = false WHERE id = '${U.inativo}';
  INSERT INTO public.usuario_papeis (usuario_id, papel_id) SELECT '${U.admin}', id FROM papeis WHERE chave = 'admin';
  INSERT INTO public.papeis (chave, nome) VALUES ('supervisao', 'Supervisão');
  -- supervisao: CRM inteiro; IO so cadastros/visualizar.
  INSERT INTO public.papel_permissoes (papel_id, system_id)
    SELECT p.id, s.id FROM papeis p, systems s WHERE p.chave = 'supervisao' AND s.slug = 'crm';
  INSERT INTO public.papel_permissoes (papel_id, system_id, modulo_id, acao)
    SELECT p.id, s.id, m.id, 'visualizar' FROM papeis p, systems s JOIN modulos m ON m.system_id = s.id AND m.chave = 'cadastros'
    WHERE p.chave = 'supervisao' AND s.slug = 'io';
  INSERT INTO public.usuario_papeis (usuario_id, papel_id) SELECT u, id FROM papeis, unnest(array['${U.sup}','${U.inativo}']::uuid[]) u WHERE chave = 'supervisao';
  INSERT INTO public.industrias (id, nome) VALUES ('10000000-0000-0000-0000-000000000001', 'Italac'), ('10000000-0000-0000-0000-000000000002', 'Fort');
  INSERT INTO public.usuario_industrias VALUES ('${U.ind}', '10000000-0000-0000-0000-000000000001');
  INSERT INTO public.colaboradores (nome, funcao) VALUES ('Promotor 1', 'promotor');
`)

let falhas = 0
async function como(uid, sql) {
  await db.exec(`RESET ROLE; SELECT set_config('request.jwt.claim.sub', '${uid ?? ''}', false); SET ROLE ${uid ? 'authenticated' : 'anon'};`)
  try {
    return await db.query(sql)
  } finally {
    await db.exec('RESET ROLE')
  }
}
async function check(nome, uid, sql, esperado) {
  let obtido
  try {
    const r = await como(uid, sql)
    obtido = r.rows.length === 1 && Object.keys(r.rows[0]).length === 1 ? Object.values(r.rows[0])[0] : r.rows
  } catch (e) {
    obtido = 'ERRO'
  }
  const ok = JSON.stringify(obtido) === JSON.stringify(esperado)
  if (!ok) falhas++
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${nome} -> ${JSON.stringify(obtido)}${ok ? '' : ` (esperado ${JSON.stringify(esperado)})`}`)
}
const pode = (...a) => `SELECT public.hub_pode_executar(${a.map((x) => (x === null ? 'NULL' : `'${x}'`)).join(', ')}) AS r`

console.log('\n-- seed / trigger')
await check('email minusculo pelo trigger', U.admin, `SELECT email FROM usuarios WHERE id = '${U.admin}'`, 'admin@dcg.com')
await check('tipo industria pelo metadata', U.ind, `SELECT tipo FROM usuarios WHERE id = '${U.ind}'`, 'industria')

await check('usuario pre-existente trazido para usuarios', U.admin, `SELECT nome || ' ' || email FROM usuarios WHERE id = '00000000-0000-0000-0000-0000000000ee'`, 'Daniel daniel@exemplo.com')

console.log('\n-- semantica hub_pode_executar')
await check('admin abre margem-real', U.admin, pode('margem-real'), true)
await check('admin modulo inexistente', U.admin, pode('crm', 'nao_existe', 'criar'), false)
await check('sup abre crm (sistema inteiro)', U.sup, pode('crm'), true)
await check('sup crm/clientes/deletar', U.sup, pode('crm', 'clientes', 'deletar'), true)
await check('sup abre io (so modulo especifico)', U.sup, pode('io'), true)
await check('sup io/cadastros (qualquer acao)', U.sup, pode('io', 'cadastros', null), true)
await check('sup io/cadastros/visualizar', U.sup, pode('io', 'cadastros', 'visualizar'), true)
await check('sup io/cadastros/criar', U.sup, pode('io', 'cadastros', 'criar'), false)
await check('sup sem margem-real', U.sup, pode('margem-real'), false)
await check('sup sem hub/permissoes', U.sup, pode('hub', 'permissoes', 'visualizar'), false)
await check('inativo com mesmo papel', U.inativo, pode('crm'), false)
await check('anon', null, pode('crm'), 'ERRO')
await check('sistema inexistente', U.admin, pode('nao-existe'), false)

await db.exec(`
  INSERT INTO usuario_permissao_excecoes (usuario_id, system_id, modulo_id, acao, tipo, justificativa)
  SELECT '${U.sup}', s.id, m.id, 'deletar', 'negar', 'teste' FROM systems s JOIN modulos m ON m.system_id = s.id AND m.chave = 'clientes' WHERE s.slug = 'crm';
  INSERT INTO usuario_permissao_excecoes (usuario_id, system_id, modulo_id, acao, tipo, justificativa, valido_ate)
  SELECT '${U.sup}', id, NULL, NULL, 'conceder', 'expirada', now() - interval '1 day' FROM systems WHERE slug = 'margem-real';
`)
console.log('\n-- excecoes')
await check('negar crm/clientes/deletar', U.sup, pode('crm', 'clientes', 'deletar'), false)
await check('negar estreito nao tira crm/clientes/editar', U.sup, pode('crm', 'clientes', 'editar'), true)
await check('negar estreito nao tira acesso ao crm', U.sup, pode('crm'), true)
await check('conceder expirado nao vale', U.sup, pode('margem-real'), false)

await db.exec(`
  INSERT INTO usuario_permissao_excecoes (usuario_id, system_id, modulo_id, acao, tipo, justificativa)
  SELECT '${U.sup}', s.id, m.id, NULL, 'negar', 'teste' FROM systems s JOIN modulos m ON m.system_id = s.id AND m.chave = 'cadastros' WHERE s.slug = 'io';
  INSERT INTO usuario_permissao_excecoes (usuario_id, system_id, modulo_id, acao, tipo, justificativa)
  SELECT '${U.sup}', s.id, m.id, 'visualizar', 'conceder', 'teste' FROM systems s JOIN modulos m ON m.system_id = s.id AND m.chave = 'empresa' WHERE s.slug = 'margem-real';
`)
await check('unico grant de io negado -> nao abre io', U.sup, pode('io'), false)
await check('conceder vigente margem-real/empresa', U.sup, pode('margem-real', 'empresa', 'visualizar'), true)
await check('conceder vigente abre margem-real', U.sup, pode('margem-real'), true)
await check('conceder nao estende para editar', U.sup, pode('margem-real', 'empresa', 'editar'), false)

console.log('\n-- RPCs de UI')
await check('admin sistemas permitidos', U.admin, `SELECT array_agg(slug ORDER BY ordem) FROM hub_sistemas_permitidos()`, ['io', 'books', 'crm', 'margem-real'])
await check('sup sistemas permitidos', U.sup, `SELECT array_agg(slug ORDER BY ordem) FROM hub_sistemas_permitidos()`, ['crm', 'margem-real'])
await check('sup minhas permissoes margem-real', U.sup, `SELECT array_agg(modulo || ':' || acao) FROM hub_minhas_permissoes('margem-real')`, ['empresa:visualizar'])
await check('sup nao chama versao service_role', U.sup, `SELECT hub_pode_executar_usuario('${U.admin}', 'crm')`, 'ERRO')

console.log('\n-- RLS')
await check('anon nao le usuarios', null, `SELECT count(*)::int FROM usuarios`, 'ERRO')
await check('sup le usuarios internos', U.sup, `SELECT count(*)::int FROM usuarios`, 5)
await check('industria so le a si mesmo', U.ind, `SELECT count(*)::int FROM usuarios`, 1)
await check('sup nao le matriz', U.sup, `SELECT count(*)::int FROM papel_permissoes`, 0)
const adminPapel = (await db.query(`SELECT id FROM papeis WHERE chave = 'admin'`)).rows[0].id
await check('sup nao se promove a admin', U.sup, `INSERT INTO usuario_papeis (usuario_id, papel_id) VALUES ('${U.sup}', '${adminPapel}') RETURNING 1`, 'ERRO')
await check('sup nao cria excecao para si', U.sup, `INSERT INTO usuario_permissao_excecoes (usuario_id, system_id, tipo, justificativa) SELECT '${U.sup}', id, 'conceder', 'x' FROM systems WHERE slug = 'hub' RETURNING 1`, 'ERRO')
await check('sup nao edita usuario', U.sup, `UPDATE usuarios SET ativo = false WHERE id = '${U.admin}' RETURNING 1`, [])
await check('sup nao insere loja', U.sup, `INSERT INTO lojas (nome) VALUES ('x') RETURNING 1`, 'ERRO')
await check('admin insere loja', U.admin, `INSERT INTO lojas (nome) VALUES ('Loja A') RETURNING nome`, 'Loja A')
await check('sup le lojas', U.sup, `SELECT count(*)::int FROM lojas`, 1)
await check('sup (crm inteiro) cria industria', U.sup, `INSERT INTO industrias (nome, situacao) VALUES ('Prospect X', 'prospect') RETURNING nome`, 'Prospect X')
await check('industria ve so a sua', U.ind, `SELECT array_agg(nome) FROM industrias`, ['Italac'])
await check('industria nao ve colaboradores', U.ind, `SELECT count(*)::int FROM colaboradores`, 0)
await check('industria nao ve empresas_dcg', U.ind, `SELECT count(*)::int FROM empresas_dcg`, 0)
await check('inativo nao le lojas', U.inativo, `SELECT count(*)::int FROM lojas`, 0)
await check('authenticated nao le codigos sso', U.admin, `SELECT count(*)::int FROM cross_system_session_codes`, 'ERRO')
await check('auditoria registrou alteracoes', U.admin, `SELECT count(*) > 0 FROM auditoria_permissoes WHERE entidade = 'usuario_permissao_excecoes'`, true)

console.log('\n-- dominios (004-010)')
// Papeis de teste: comercial do CRM, financeiro do MR (sem pessoal), RH do CRM.
await db.exec(`
  INSERT INTO papeis (chave, nome) VALUES ('t_comercial', 't'), ('t_financeiro', 't'), ('t_rh', 't'), ('t_io_ind', 't');
  INSERT INTO papel_permissoes (papel_id, system_id, modulo_id)
    SELECT p.id, s.id, m.id FROM papeis p, systems s JOIN modulos m ON m.system_id = s.id
    WHERE (p.chave, s.slug, m.chave) IN (('t_comercial','crm','comercial'), ('t_financeiro','margem-real','financeiro'),
                                         ('t_rh','crm','rh'), ('t_io_ind','io','validades'));
  INSERT INTO auth.users (id, email) VALUES
    ('00000000-0000-0000-0000-0000000000c1', 'com@dcg.com'), ('00000000-0000-0000-0000-0000000000f1', 'fin@dcg.com'),
    ('00000000-0000-0000-0000-0000000000a1', 'rh@dcg.com'), ('00000000-0000-0000-0000-0000000000d1', 'nada@dcg.com');
  INSERT INTO usuario_papeis SELECT u, p.id, NULL, now() FROM papeis p, (VALUES
    ('00000000-0000-0000-0000-0000000000c1'::uuid, 't_comercial'), ('00000000-0000-0000-0000-0000000000f1'::uuid, 't_financeiro'),
    ('00000000-0000-0000-0000-0000000000a1'::uuid, 't_rh'), ('${U.ind}'::uuid, 't_io_ind')) AS x(u, chave) WHERE p.chave = x.chave;
  INSERT INTO colaboradores (id, nome, funcao) VALUES ('20000000-0000-0000-0000-000000000001', 'Promotor X', 'promotor');
  INSERT INTO mr_pagamentos (valor) VALUES (1500);
  INSERT INTO mr_lancamentos (descricao, valor) VALUES ('teste', 10);
  INSERT INTO rh_registros (tipo, promotor) VALUES ('falta', '20000000-0000-0000-0000-000000000001');
  INSERT INTO io_validades_base (produto, industry_id) VALUES
    ('Leite', '10000000-0000-0000-0000-000000000001'), ('Feijao', '10000000-0000-0000-0000-000000000002');
`)
const C = '00000000-0000-0000-0000-0000000000c1', F = '00000000-0000-0000-0000-0000000000f1'
const R = '00000000-0000-0000-0000-0000000000a1', N = '00000000-0000-0000-0000-0000000000d1'
await check('comercial nao le pagamentos do MR', C, `SELECT count(*)::int FROM mr_pagamentos`, 0)
await check('comercial nao grava no MR', C, `INSERT INTO mr_lancamentos (descricao) VALUES ('x') RETURNING 1`, 'ERRO')
await check('financeiro le lancamentos', F, `SELECT count(*)::int FROM mr_lancamentos`, 1)
await check('financeiro nao le pagamentos (pessoal)', F, `SELECT count(*)::int FROM mr_pagamentos`, 0)
await check('rh le registros de RH', R, `SELECT count(*)::int FROM rh_registros`, 1)
await check('comercial nao le RH', C, `SELECT count(*)::int FROM rh_registros`, 0)
await check('admin le pagamentos', U.admin, `SELECT count(*)::int FROM mr_pagamentos`, 1)
await check('usuario de industria ve so a validade da sua industria', U.ind, `SELECT array_agg(produto) FROM io_validades_base`, ['Leite'])
await check('interno sem modulo nao ve validades', U.sup, `SELECT count(*)::int FROM io_validades_base`, 0)
await check('extensao exige mestre (mr_promotores sem colaborador)', U.admin, `INSERT INTO mr_promotores (salario) VALUES (1) RETURNING 1`, 'ERRO')
await check('extensao 1:1 com o mestre', U.admin,
  `INSERT INTO mr_promotores (colaborador_id) VALUES ('20000000-0000-0000-0000-000000000001'), ('20000000-0000-0000-0000-000000000001') RETURNING 1`, 'ERRO')

const dominio = (await db.query(`SELECT c.relname AS t, c.relrowsecurity AS rls,
    (SELECT count(*)::int FROM pg_policies p WHERE p.schemaname = 'public' AND p.tablename = c.relname) AS pol
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relname ~ '^(io|books|crm|mr|dp|wa|trade|rh)_'`)).rows
const semRls = dominio.filter((r) => !r.rls || r.pol !== 4).map((r) => r.t)
await check(`${dominio.length} tabelas de dominio com RLS e 4 policies`, U.admin, `SELECT ${JSON.stringify(semRls.length)}::int`, 0)
let abertas = []
for (const { t } of dominio) {
  try { const r = await como(N, `SELECT count(*)::int AS n FROM public.${t}`); if (r.rows[0].n > 0) abertas.push(t) } catch { abertas.push(t + '(erro)') }
}
await check('usuario sem papel nao le nenhuma tabela de dominio', N, `SELECT ${abertas.length}::int`, 0)
if (abertas.length) console.log('   abertas:', abertas.join(', '))
let gravaveis = []
for (const { t } of dominio) {
  try { await como(N, `INSERT INTO public.${t} DEFAULT VALUES`); gravaveis.push(t) } catch {}
}
await check('usuario sem papel nao grava em nenhuma tabela de dominio', N, `SELECT ${gravaveis.length}::int`, 0)
await check('anon nao le tabela de dominio', null, `SELECT count(*)::int FROM crm_deals`, 'ERRO')
await check('authenticated nao acessa schema migracao', U.admin, `SELECT count(*)::int FROM migracao.id_map`, 'ERRO')

console.log('\n-- storage')
await db.exec(`INSERT INTO storage.objects (bucket_id, name) VALUES ('mr-pessoal', 'folha.pdf'), ('crm', 'proposta.pdf')`)
await check('comercial ve arquivo do CRM, nao a folha', C, `SELECT array_agg(name ORDER BY name) FROM storage.objects`, ['proposta.pdf'])
await check('financeiro nao ve folha (pessoal)', F, `SELECT count(*)::int FROM storage.objects`, 0)
await check('admin ve todos os arquivos', U.admin, `SELECT count(*)::int FROM storage.objects`, 2)
await check('comercial nao sobe arquivo no bucket pessoal', C, `INSERT INTO storage.objects (bucket_id, name) VALUES ('mr-pessoal', 'x') RETURNING 1`, 'ERRO')

console.log(`\n${falhas === 0 ? 'TODOS OS TESTES PASSARAM' : `${falhas} FALHA(S)`}`)
process.exit(falhas === 0 ? 0 : 1)
