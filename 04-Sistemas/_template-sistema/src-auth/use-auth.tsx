// Substitui src/hooks/use-auth.tsx das bases Skip. Mantem a API que as telas
// do Skip ja usam (user, session, loading, signIn, signOut, resetPassword),
// remove signUp (cadastro so por convite) e acrescenta o gate do ecossistema.
import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import type { AuthError, Session, User } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase/client'
import { carregarAcesso, consumirSsoDaUrl, type Permissao } from '@/lib/ecossistema'

export type EstadoAcesso = 'carregando' | 'sem_sessao' | 'sem_acesso' | 'liberado' | 'erro'

interface AuthContextType {
  user: User | null
  session: Session | null
  loading: boolean
  estado: EstadoAcesso
  /** Destino vindo do SSO, para o router navegar uma vez apos o login. */
  redirectSso: string | null
  pode: (modulo: string, acao: string) => boolean
  signIn: (email: string, password: string) => Promise<{ error: AuthError | null }>
  signOut: () => Promise<{ error: AuthError | null }>
  resetPassword: (email: string) => Promise<{ error: AuthError | null }>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth must be used within an AuthProvider')
  return context
}

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [session, setSession] = useState<Session | null>(null)
  const [estado, setEstado] = useState<EstadoAcesso>('carregando')
  const [permissoes, setPermissoes] = useState<Permissao[]>([])
  const [redirectSso, setRedirectSso] = useState<string | null>(null)
  const [ssoPronto, setSsoPronto] = useState(false)
  const [sessaoCarregada, setSessaoCarregada] = useState(false)

  // 1. Consome ?sso_code= antes de olhar a sessao.
  useEffect(() => {
    let ativo = true
    consumirSsoDaUrl()
      .then((destino) => {
        if (ativo && destino) setRedirectSso(destino)
      })
      .finally(() => {
        if (ativo) setSsoPronto(true)
      })
    return () => {
      ativo = false
    }
  }, [])

  // 2. Acompanha a sessao. O callback do Supabase precisa ser sincrono:
  //    chamar o client dentro dele pode travar a sessao.
  useEffect(() => {
    if (!ssoPronto) return
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, s) => {
      setSession(s)
      setSessaoCarregada(true)
    })
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session)
      setSessaoCarregada(true)
    })
    return () => subscription.unsubscribe()
  }, [ssoPronto])

  // 3. Reavalia acesso quando muda o usuario (fora do callback). Renovacao de
  //    token troca o objeto session mas nao o usuario: nao recarrega.
  const userId = session?.user.id ?? null
  useEffect(() => {
    if (!sessaoCarregada) return
    if (!userId) {
      setPermissoes([])
      setEstado('sem_sessao')
      return
    }
    let ativo = true
    setEstado('carregando')
    carregarAcesso()
      .then((acesso) => {
        if (!ativo) return
        setPermissoes(acesso.permissoes)
        setEstado(acesso.temAcesso ? 'liberado' : 'sem_acesso')
      })
      .catch(() => {
        if (ativo) setEstado('erro')
      })
    return () => {
      ativo = false
    }
  }, [sessaoCarregada, userId])

  const value = useMemo<AuthContextType>(() => {
    const chaves = new Set(permissoes.map((p) => `${p.modulo}:${p.acao}`))
    return {
      user: session?.user ?? null,
      session,
      loading: estado === 'carregando',
      estado,
      redirectSso,
      pode: (modulo, acao) => chaves.has(`${modulo}:${acao}`),
      signIn: async (email, password) => {
        const { error } = await supabase.auth.signInWithPassword({ email, password })
        return { error }
      },
      signOut: async () => {
        const { error } = await supabase.auth.signOut()
        return { error }
      },
      resetPassword: async (email) => {
        const { error } = await supabase.auth.resetPasswordForEmail(email, {
          redirectTo: `${window.location.origin}/`,
        })
        return { error }
      },
    }
  }, [session, estado, redirectSso, permissoes])

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
