# Decisões pendentes de banco

| # | Decisão | Impacto | Quem decide | Default até decidir |
|---|---|---|---|---|
| PD-01 | Papéis iniciais e matriz por sistema (diretoria, supervisão, financeiro, comercial, analista books, indústria...) | Seed da matriz pela UI | Champion (gate do escopo, seção 19) | Só `admin` existe |
| PD-02 | Indústria e cliente contratual são a mesma entidade? | `industrias` única com `situacao` | Comercial + operação | Uma tabela `industrias` |
| PD-03 | CPF de colaborador: precisa estar no mestre para casar com Trade Pro? | Coluna sensível em `colaboradores` | Operação + LGPD | Fora do mestre |
| PD-04 | CRM pode criar/editar loja (importação de base do cliente, geolocalização)? | Policy de `lojas` | Comercial + IO | Só `io/cadastros` escreve |
| PD-05 | Provedor único de WhatsApp (D-02 do escopo) | Tabelas de mensagens e webhooks | Diretoria | Nenhuma tabela criada |
| PD-06 | Domínio dos sistemas (subdomínios de um domínio DCG permitiriam sessão por cookie) | Simplifica SSO | TI DCG | SSO por código |
| PD-07 | Outbox de eventos para a Central DP | Formato único para EV-IO/BK/CRM/MR | SPEC da Central DP | — |
| PD-08 | Quando criar a 5ª base Skip (Central DP) | Telas de usuários/permissões | Adapta + champion | Painel/SQL até lá |
| PD-09 | Rotacionar a senha do banco e a `service_role` key (ficaram registradas no log da sessão de 2026-10-23; senha do banco é fraca) | Segurança | Responsável pelo projeto Supabase | — |
