# Pacote de auth DCG (para as bases Skip)

Feito sobre o template Skip das bases `Sistema-1..4` (React + Vite + shadcn, client em `src/lib/supabase/client.ts`, variáveis `VITE_SUPABASE_URL` e `VITE_SUPABASE_PUBLISHABLE_KEY`).

| Arquivo deste pacote | Destino na base Skip | Faz |
|---|---|---|
| `ecossistema.ts` | `src/lib/ecossistema.ts` | Troca de `sso_code`, `abrirSistema()`, `carregarAcesso()`. Só muda `SISTEMA_SLUG`. |
| `use-auth.tsx` | `src/hooks/use-auth.tsx` (substitui) | Mesma API do hook Skip, sem `signUp`, com `estado` e `pode(modulo, acao)` |
| `ProtectedRoute.tsx` | `src/components/ProtectedRoute.tsx` | Sem sessão → `/` (login); sem acesso → "Acesso negado" |

Não editar `src/lib/supabase/client.ts` nem `types.ts`: são gerados pelo Skip.

```tsx
<Route path="/" element={<Index />} />               {/* login */}
<Route element={<ProtectedRoute><Layout /></ProtectedRoute>}>
  <Route path="/dashboard" element={<Dashboard />} />
  <Route path="/contratos/*" element={<ProtectedRoute modulo="contratos"><Contratos /></ProtectedRoute>} />
</Route>

const { pode } = useAuth()
{pode('contratos', 'aprovar') && <Button>Aprovar</Button>}
```

Regras: sem tela de cadastro (remover qualquer uso de `signUp`); sem `role === 'admin'` no código; links para outros sistemas por `abrirSistema()`. Esconder botão é conforto. A proteção é a RLS.

Depende das migrations `20261023_001` e `20261023_002` aplicadas. Antes disso, `hub_pode_executar` não existe e todo usuário cai em "erro".
