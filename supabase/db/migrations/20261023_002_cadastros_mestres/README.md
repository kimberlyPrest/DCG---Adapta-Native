# Migration 20261023_002 - SPEC-002 (Cadastros mestres compartilhados)

## Contexto

Ver `03-Projeto/SPECs/SPEC-002_Cadastros_Mestres_Compartilhados.md`. Depende de `20261023_001`.

## Arquivos

| Arquivo | Função |
|---|---|
| `001_tabelas.sql` | `empresas_dcg`, `redes`, `lojas`, `industrias`, `produtos`, `colaboradores`, `cadastro_aliases`, `usuario_industrias`. |
| `002_modulos_e_rls.sql` | Módulos donos (`io/cadastros`, `crm/clientes`, `margem-real/empresa`), `pode_ver_industria()`, RLS. |

## Estado

Escrita em 2026-10-23. **Ainda não aplicada.** Nenhum dado é carregado aqui: a carga vem da migração de dados dos sistemas PocketBase (SPEC própria, com importação rastreável e sem CPF/PIX).

## Verificação pós-aplicação

- Usuário `tipo = industria` com uma linha em `usuario_industrias`: `SELECT count(*) FROM industrias` retorna 1; `colaboradores` retorna 0.
- Usuário interno sem `io/cadastros`: lê `lojas`, recebe erro de RLS ao inserir.
- Usuário com `crm/clientes/criar`: insere em `industrias`, não insere em `lojas`.
