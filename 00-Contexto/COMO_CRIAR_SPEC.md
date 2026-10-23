# Como criar SPEC

1. Copiar `03-Projeto/SPECs/_TEMPLATE_SPEC.md` para `SPEC-NNN_Titulo_Curto.md` (próximo número livre em `03-Projeto/00_INDICE.md`).
2. Preencher antes de codar: problema, sistemas, banco (tabelas, módulos, ações, policies), critérios de aceite testáveis, rollback.
3. Toda SPEC que cria tabela lista os módulos/ações novos e quem escreve/lê.
4. Registrar no `00_INDICE.md` com status (`rascunho`, `aprovada`, `em implementação`, `aplicada`).
5. Ao terminar: marcar checklist, preencher "Realizado" e "Pendências", atualizar `CHANGELOG.md`.

As SPECs de negócio por fase (escopo v2.x) continuam em `../Plano — 3a0e27a1/03-Projeto/02-Plano_de_acao/`. As SPECs deste repositório são técnicas: banco, permissão, integração entre sistemas. Quando uma SPEC de fase gerar mudança técnica, a SPEC técnica cita a de fase.
