// SPEC-001. Gera codigo opaco (60 s, uso unico) para abrir outro sistema DCG
// sem novo login. So gera se o usuario pode abrir o sistema de destino.
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'jsr:@supabase/supabase-js@2'
import { corsHeaders, env, json, sanitizePath } from '../_shared/cors.ts'

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

    const body = await req.json().catch(() => ({}))
    const sistemaOrigem = typeof body.sistema_origem === 'string' ? body.sistema_origem.trim() : ''
    const sistemaDestino = typeof body.sistema_destino === 'string' ? body.sistema_destino.trim() : ''
    if (!sistemaOrigem || !sistemaDestino) {
      return json({ error: 'Informe sistema_origem e sistema_destino.' }, 400)
    }

    const { data: podeAbrir, error: permError } = await userClient.rpc('hub_pode_executar', {
      p_system_slug: sistemaDestino,
    })
    if (permError) {
      console.error('generate-cross-system-code: falha ao checar permissao', permError.message)
      return json({ error: 'Falha ao verificar permissão.' }, 500)
    }
    if (!podeAbrir) return json({ error: 'Sem acesso ao sistema de destino.' }, 403)

    await adminClient
      .from('cross_system_session_codes')
      .delete()
      .or(`expira_em.lt.${new Date().toISOString()},usado_em.not.is.null`)

    const { data, error } = await adminClient
      .from('cross_system_session_codes')
      .insert({
        usuario_id: user.id,
        sistema_origem: sistemaOrigem,
        sistema_destino: sistemaDestino,
        contexto: { redirect_to: sanitizePath(body.redirect_to) },
      })
      .select('code, expira_em')
      .single()

    if (error || !data) {
      console.error('generate-cross-system-code: falha ao gravar codigo', error?.message)
      return json({ error: 'Falha ao gerar código.' }, 500)
    }

    return json(data)
  } catch (error) {
    console.error('generate-cross-system-code: erro inesperado', error)
    return json({ error: 'Erro inesperado.' }, 500)
  }
})
