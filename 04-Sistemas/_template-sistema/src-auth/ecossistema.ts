// Pacote de auth do ecossistema DCG (SPEC-001). Destino: src/lib/ecossistema.ts
// das bases Skip. Usa o client gerado pelo Skip (nao criar outro).
// Contrato: supabase/docs/permissoes_e_login.md do repo central.
import { supabase } from '@/lib/supabase/client'

/** Slug do sistema em public.systems: 'hub' | 'io' | 'books' | 'crm' | 'margem-real'. */
export const SISTEMA_SLUG = 'io'

export interface Permissao {
  modulo: string
  acao: string
}

interface TrocaSsoResposta {
  access_token: string
  refresh_token: string
  redirect_to: string
}

/**
 * Se a URL tiver ?sso_code=, troca o codigo por sessao e devolve o caminho de
 * destino. Remove o codigo da URL em qualquer caso. Retorna null sem codigo.
 */
export async function consumirSsoDaUrl(): Promise<string | null> {
  const url = new URL(window.location.href)
  const code = url.searchParams.get('sso_code')
  if (!code) return null

  url.searchParams.delete('sso_code')
  window.history.replaceState(null, '', url.pathname + url.search + url.hash)

  const { data, error } = await supabase.functions.invoke<TrocaSsoResposta>('exchange-cross-system-code', {
    body: { code, sistema_destino: SISTEMA_SLUG },
  })
  if (error || !data) return null

  const { error: sessionError } = await supabase.auth.setSession({
    access_token: data.access_token,
    refresh_token: data.refresh_token,
  })
  return sessionError ? null : data.redirect_to
}

/** Abre outro sistema DCG ja logado. url vem de hub_sistemas_permitidos(). */
export async function abrirSistema(destinoSlug: string, destinoUrl: string, redirectTo = '/'): Promise<void> {
  const { data, error } = await supabase.functions.invoke<{ code: string }>('generate-cross-system-code', {
    body: { sistema_origem: SISTEMA_SLUG, sistema_destino: destinoSlug, redirect_to: redirectTo },
  })
  if (error || !data) throw new Error('Não foi possível abrir o sistema. Verifique seu acesso.')

  const alvo = new URL(destinoUrl)
  alvo.searchParams.set('sso_code', data.code)
  window.open(alvo.toString(), '_blank', 'noopener')
}

export async function carregarAcesso(): Promise<{ temAcesso: boolean; permissoes: Permissao[] }> {
  const [acesso, permissoes] = await Promise.all([
    supabase.rpc('hub_pode_executar', { p_system_slug: SISTEMA_SLUG }),
    supabase.rpc('hub_minhas_permissoes', { p_system_slug: SISTEMA_SLUG }),
  ])
  if (acesso.error) throw new Error('Falha ao verificar acesso.')
  return {
    temAcesso: acesso.data === true,
    permissoes: (permissoes.data ?? []) as Permissao[],
  }
}
