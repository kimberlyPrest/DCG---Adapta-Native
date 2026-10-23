// SPEC-001. Unica porta de entrada de usuario novo (cadastro publico desligado).
// Exige hub/usuarios/criar. Envia convite por e-mail; o trigger
// on_auth_user_created cria public.usuarios. Papeis e escopo sao atribuidos
// depois pela tela da Central DP (RLS de usuario_papeis/usuario_industrias).
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'jsr:@supabase/supabase-js@2'
import { corsHeaders, env, json } from '../_shared/cors.ts'

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return json({ error: 'Método não permitido.' }, 405)

  const cfg = env()
  if (!cfg) return json({ error: 'Configuração Supabase incompleta.' }, 500)

  try {
    const userClient = createClient(cfg.url, cfg.anonKey, {
      global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
    })
    const adminClient = createClient(cfg.url, cfg.serviceKey)

    const { data: { user } } = await userClient.auth.getUser()
    if (!user) return json({ error: 'Não autorizado.' }, 401)

    const { data: podeCriar } = await userClient.rpc('hub_pode_executar', {
      p_system_slug: 'hub',
      p_modulo_chave: 'usuarios',
      p_acao: 'criar',
    })
    if (!podeCriar) return json({ error: 'Sem permissão para convidar usuários.' }, 403)

    const body = await req.json().catch(() => ({}))
    const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : ''
    const nome = typeof body.nome === 'string' ? body.nome.trim() : ''
    const tipo = body.tipo === 'industria' ? 'industria' : 'interno'
    const redirectTo = typeof body.redirect_to === 'string' ? body.redirect_to : undefined

    if (!EMAIL_RE.test(email) || nome.length < 2) {
      return json({ error: 'Informe nome e e-mail válidos.' }, 400)
    }

    const { data, error } = await adminClient.auth.admin.inviteUserByEmail(email, {
      data: { nome, tipo },
      redirectTo,
    })
    if (error || !data?.user) {
      const jaExiste = error?.message?.toLowerCase().includes('already')
      console.error('admin-convidar-usuario: falha no convite', error?.message)
      return json({ error: jaExiste ? 'Já existe usuário com este e-mail.' : 'Falha ao enviar convite.' }, jaExiste ? 409 : 500)
    }

    return json({ usuario_id: data.user.id, email, nome, tipo }, 201)
  } catch (error) {
    console.error('admin-convidar-usuario: erro inesperado', error)
    return json({ error: 'Erro inesperado.' }, 500)
  }
})
