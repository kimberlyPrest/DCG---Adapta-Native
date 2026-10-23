// Destino: src/components/ProtectedRoute.tsx das bases Skip.
import type { ReactNode } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from '@/hooks/use-auth'

interface ProtectedRouteProps {
  children: ReactNode
  /** Opcional: exige um modulo/acao especifico alem do acesso ao sistema. */
  modulo?: string
  acao?: string
}

/** Gate obrigatorio de todo sistema DCG: sessao + hub_pode_executar(SISTEMA_SLUG). */
export function ProtectedRoute({ children, modulo, acao = 'visualizar' }: ProtectedRouteProps) {
  const { estado, pode } = useAuth()
  const location = useLocation()

  if (estado === 'carregando') return <p role="status">Carregando…</p>
  if (estado === 'sem_sessao') return <Navigate to="/" replace state={{ de: location.pathname }} />
  if (estado === 'erro') return <p role="alert">Não foi possível verificar seu acesso. Tente recarregar a página.</p>
  if (estado === 'sem_acesso' || (modulo && !pode(modulo, acao))) {
    return (
      <div role="alert">
        <h1>Acesso negado</h1>
        <p>Seu usuário não tem permissão para esta área. Peça acesso ao administrador na Central DP.</p>
      </div>
    )
  }
  return <>{children}</>
}
