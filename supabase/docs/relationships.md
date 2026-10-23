# Relacionamentos e donos de tabela

"Dono" = sistema/módulo cuja permissão libera escrita. Os demais sistemas leem (respeitando RLS) e referenciam por FK.

## Identidade e acesso (dono: `hub`)

```text
auth.users 1─1 usuarios
usuarios 1─N usuario_papeis N─1 papeis 1─N papel_permissoes N─1 systems
                                                papel_permissoes N─1 modulos (opcional)
systems 1─N modulos 1─N modulo_acoes
usuarios 1─N usuario_permissao_excecoes N─1 systems / modulos
usuarios 1─N usuario_industrias N─1 industrias
usuarios 1─N cross_system_session_codes N─1 systems(slug)
```

## Cadastros mestres

| Tabela | Dono (escrita) | Leitura | Substitui |
|---|---|---|---|
| `empresas_dcg` | `margem-real/empresa` | interno | `cnpjs` (MR) |
| `redes` | `io/cadastros` | todo ativo | `networks` (IO), `redes` (CRM), texto em Books/Ocorrências/MR |
| `lojas` | `io/cadastros` | todo ativo | `stores` (IO, Books), `lojas` (CRM, Ocorrências, MR) |
| `industrias` | `io/cadastros` ou `crm/clientes` | escopo por indústria | `industry_registry`, `brands`, `clients`, `industrias`, `clientes` |
| `produtos` | `io/cadastros` | escopo por indústria | `industry_product_mix`, `skus` |
| `colaboradores` | `io/cadastros` | interno | `promoters`, `supervisors`, `promotores` (×4) |
| `cadastro_aliases` | `io/cadastros` | interno | `store_aliases`, `network_aliases`, `product_aliases` |

```text
redes 1─N lojas
industrias 1─N produtos
colaboradores 1─N colaboradores (supervisor_id)
colaboradores 0..1─1 usuarios
cadastro_aliases N─1 {rede|loja|industria|produto|colaborador} (polimórfico por entidade/entidade_id)
```

## Regra para tabela de sistema que estende um mestre

Cria tabela própria com FK para o mestre e o dado específico. Exemplos previstos:

- Books: `books_produto_referencia (produto_id → produtos, imagem, preco_normal, preco_promocional, exige_splash)`.
- Margem Real: `mr_colaborador_pagamento (colaborador_id → colaboradores, salario, encargos, pix, banco)` — restrito a `margem-real`.
- CRM: `crm_lojas_operacao (loja_id → lojas, regras de atendimento)`.

Atualizar esta página ao criar cada uma.
