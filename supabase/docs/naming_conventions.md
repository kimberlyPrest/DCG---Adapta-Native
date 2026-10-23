# Convenções de nomes

## Migrations

```text
YYYYMMDD_NNN_nome_do_grupo/
  README.md
  001_area.sql
  002_area.sql
```

`NNN` é sequencial no repositório inteiro, não por dia.

## Tabelas e colunas

- `snake_case`, português, sem acento (`valido_ate`, não `valido_até`).
- Mestres sem prefixo (`lojas`, `industrias`). Tabelas de um sistema com prefixo quando o nome for genérico: `books_`, `crm_`, `mr_` (Margem Real), `dp_` (Central DP), `io_`.
- Chave estrangeira: `<entidade_singular>_id` (`loja_id`, `industria_id`, `colaborador_id`).
- Auditoria mínima: `criado_em`, `atualizado_em` (trigger `set_atualizado_em`), `criado_por` quando importar quem fez.
- Situação/estado: coluna `situacao` ou `status` com `CHECK (... IN (...))`; listas que o cliente muda viram tabela de configuração.
- CNPJ/CPF: só dígitos, com `CHECK`.

## Slugs e chaves de permissão

- `systems.slug`: `kebab-case` (`margem-real`).
- `modulos.chave`, ações e `papeis.chave`: `snake_case` (`fechamento_mensal`, `aprovar`).

## Configuração

Regras que o cliente pode mudar ficam em tabela de configuração editável pela UI: SLA, responsáveis, áreas de direcionamento, política de validade, frequência de visita, papéis e permissões.
