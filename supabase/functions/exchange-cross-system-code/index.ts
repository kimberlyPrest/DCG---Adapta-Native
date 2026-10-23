// SPEC-001. Consome o codigo uma unica vez e devolve sessao Supabase para o
// sistema de destino. Chamado sem login (verify_jwt = false em config.toml).
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'jsr:@supabase/supabase-js@2'
import { corsHeaders, env, json, sanitizePath } from '../_shared/cors.ts'

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
const SLUG_RE = /^[a-z0-9]+(-[a-z0-9]+)*$/

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return json({ error: 'Método não permitido.' }, 405)

  const cfg = env()
  if (!cfg) return json({ error: 'Configuração Supabase incompleta.' }, 500)

  try {
    const adminClient = createClient(cfg.url, cfg.serviceKey)
    const body = await req.json().catch(() => ({}))
    const code = body.code
    const sistemaDestino = typeof body.sistema_destino === 'string' ? body.sistema_destino.trim() : ''

    if (typeof code !== 'string' || !UUID_RE.test(code) || !SLUG_RE.test(sistemaDestino)) {
      return json({ error: 'Código ou sistema inválido.' }, 400)
    }

    // Marca como usado na mesma instrucao que valida: dois pedidos simultaneos
    // com o mesmo codigo nao passam os dois.
    const { data: codeRow } = await adminClient
      .from('cross_system_session_codes')
      .update({ usado_em: new Date().toISOString() })
      .eq('code', code)
      .eq('sistema_destino', sistemaDestino)
      .is('usado_em', null)
      .gt('expira_em', new Date().toISOString())
      .select('usuario_id, contexto')
      .single()

    if (!codeRow) return json({ error: 'Código expirado, usado ou de outro sistema.' }, 401)

    // Revalida no momento da troca: o acesso pode ter sido retirado.
    const { data: podeAbrir } = await adminClient.rpc('hub_pode_executar_usuario', {
      p_usuario_id: codeRow.usuario_id,
      p_system_slug: sistemaDestino,
    })
    if (!podeAbrir) return json({ error: 'Sem acesso ao sistema de destino.' }, 403)

    const { data: usuario } = await adminClient
      .from('usuarios')
      .select('email')
      .eq('id', codeRow.usuario_id)
      .single()
    if (!usuario?.email) return json({ error: 'Usuário não encontrado.' }, 401)

    const { data: linkData, error: linkError } = await adminClient.auth.admin.generateLink({
      type: 'magiclink',
      email: usuario.email,
    })
    const tokenHash = linkData?.properties?.hashed_token
    if (linkError || !tokenHash) {
      console.error('exchange-cross-system-code: falha ao gerar link', linkError?.message)
      return json({ error: 'Falha ao criar sessão.' }, 500)
    }

    const { data: verifyData, error: verifyError } = await adminClient.auth.verifyOtp({
      token_hash: tokenHash,
      type: 'magiclink',
    })
    if (verifyError || !verifyData?.session) {
      console.error('exchange-cross-system-code: falha ao verificar OTP', verifyError?.message)
      return json({ error: 'Falha ao criar sessão.' }, 500)
    }

    return json({
      access_token: verifyData.session.access_token,
      refresh_token: verifyData.session.refresh_token,
      redirect_to: sanitizePath((codeRow.contexto as { redirect_to?: unknown } | null)?.redirect_to),
    })
  } catch (error) {
    console.error('exchange-cross-system-code: erro inesperado', error)
    return json({ error: 'Erro inesperado.' }, 500)
  }
})
