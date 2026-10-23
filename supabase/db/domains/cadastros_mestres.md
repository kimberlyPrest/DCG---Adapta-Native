# Domínio: Cadastros mestres

## Papel

Uma versão de cada entidade de campo e comercial, compartilhada pelos 5 sistemas. IO é a fonte de verdade operacional (integra com Trade Pro e já reconcilia cadastros com aliases e pendências).

## Objetos

`empresas_dcg`, `redes`, `lojas`, `industrias`, `produtos`, `colaboradores`, `cadastro_aliases`, `usuario_industrias`. Donos em `supabase/docs/relationships.md`.

## Regras

- `industrias.situacao`: `prospect` (nasce no CRM) → `ativa` (atendida em campo) → `inativa`.
- Nome vindo de fonte externa que não bate com o cadastro vira `cadastro_aliases`, não registro novo.
- `colaboradores` guarda só dado operacional. Pagamento fica no Margem Real.
- `lojas.codigo_tradepro` e `colaboradores.codigo_tradepro` ligam à API do Trade Pro.

## Origem nos sistemas antigos

| Mestre | IO | Books | CRM | Margem Real | Ocorrências |
|---|---|---|---|---|---|
| `redes` | `networks` + `network_aliases` | texto em `stores` | `redes` | texto em `lojas` | texto |
| `lojas` | `stores` + `store_aliases` | `stores` | `lojas`, `lojas_operacao` | `lojas` | `lojas` |
| `industrias` | `industry_registry` | `brands` | `clients`, `industrias` | `clientes` | `industrias` |
| `produtos` | `industry_product_mix` + `product_aliases` | `skus` | — | — | texto |
| `colaboradores` | `promoters`, `supervisors` | `promoters` | `promotores` | `promotores` | `promotores` |
| `empresas_dcg` | — | — | `entidades_juridicas`? | `cnpjs` | — |
