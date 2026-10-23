# Contexto de banco — <NOME DO SISTEMA> (`<slug>`)

> Preencher a partir da SPEC do sistema. Manter curto: só o recorte que este sistema usa.

## Módulos e ações registrados

| Módulo (`modulos.chave`) | Ações | Tela/rota |
|---|---|---|
| | | |

## Tabelas que este sistema escreve

| Tabela | Policy de escrita | Observação |
|---|---|---|
| | `hub_pode_executar('<slug>', '<modulo>', '<acao>')` | |

## Tabelas que este sistema só lê

| Tabela | Dono | Para quê |
|---|---|---|
| `lojas` | io | |
| `industrias` | io / crm | |

## Funções e Edge Functions usadas

| Nome | Para quê |
|---|---|
| `hub_pode_executar`, `hub_minhas_permissoes` | gate e UI (pacote src/auth) |

## Regras de negócio que afetam o banco

-

## Origem (sistema PocketBase antigo)

| Coleção antiga | Destino no Supabase | Observação |
|---|---|---|
| | | |
