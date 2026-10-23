# Banco de Dados — organização central

1. `current/`: fotografia do banco real (após a primeira aplicação).
2. `domains/`: explicação lógica por área.
3. `migrations/`: alterações centrais, agrupadas por objetivo.

## Ordem mental do banco

1. Identidade e acesso: usuários, sistemas, módulos, papéis, permissões, SSO.
2. Cadastros mestres: empresas DCG, redes, lojas, indústrias, produtos, colaboradores.
3. Central DP: itens de trabalho (inclui ocorrências), SLA, outbox de eventos.
4. IO: validades, rupturas, visitas, devoluções, integração Trade Pro.
5. Books: books, fotos, classificações, notas e ranking.
6. CRM: oportunidades, propostas, contratos, regras operacionais, capacidade.
7. Margem Real: plano de contas, lançamentos, contas a pagar/receber, rateio, fechamento.
