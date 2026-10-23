"""Gera as migrations de dominio (004..009) do banco unico a partir dos schema.json de
producao dos 4 PocketBase (04-Sistemas/_legado-pocketbase/_schemas-producao/).

Regra (PLANO-UNIFICACAO-BANCO.md):
- cada colecao vira <prefixo>_<nome original>, com os mesmos nomes de campo;
- colecoes de cadastro mestre gravam a identidade no mestre (SPEC-002) e o resto
  dos campos numa tabela de extensao 1:1 (<prefixo>_<colecao>, com <mestre>_id);
- relacao -> uuid com FK (para o mestre quando a colecao alvo e mestre);
- todo registro guarda legado_id (id do PocketBase) para o ETL ser idempotente;
- RLS por sistema/modulo via hub_pode_executar; pode_ver_industria quando ha FK
  para industrias.

Uso: python3 -I scripts/unificacao/gerar_migrations.py <raiz-do-repo-central>
"""
import json
import os
import re
import sys

SISTEMAS = ["io", "books", "crm", "mr"]

# Colecao -> mestre (identidade compartilhada). As demais colunas vao para a extensao.
MESTRES = {
    ("io", "networks"): "redes",
    ("io", "stores"): "lojas",
    ("io", "industry_registry"): "industrias",
    ("io", "industry_product_mix"): "produtos",
    ("io", "promoters"): "colaboradores",
    ("io", "supervisors"): "colaboradores",
    ("books", "stores"): "lojas",
    ("books", "brands"): "industrias",
    ("books", "skus"): "produtos",
    ("books", "promoters"): "colaboradores",
    ("crm", "clients"): "industrias",
    ("crm", "redes"): "redes",
    ("crm", "lojas"): "lojas",
    ("crm", "industrias"): "industrias",
    ("crm", "promotores"): "colaboradores",
    ("crm", "capacidade_operacional"): "colaboradores",
    ("crm", "entidades_juridicas"): "empresas_dcg",
    ("mr", "clientes"): "industrias",
    ("mr", "promotores"): "colaboradores",
    ("mr", "cnpjs"): "empresas_dcg",
    ("mr", "lojas"): "lojas",
}

# Campos que viram coluna do mestre (nao repetem na extensao). Valor = coluna no mestre.
CORE = {
    ("io", "networks"): {"nome": "nome", "cnpj": "cnpj", "ativo": "ativo", "codigo_externo": "codigo_externo"},
    ("io", "stores"): {"nome": "nome", "codigo_externo": "codigo_tradepro", "razao_social": "razao_social", "cnpj": "cnpj",
                       "cidade": "cidade", "estado": "uf", "ativo": "ativo", "network_id": "rede_id", "regiao": "regiao"},
    ("io", "industry_registry"): {"nome": "nome", "razao_social": "razao_social", "cnpj": "cnpj", "status": "situacao",
                                  "segmento": "segmento", "tradepro_client_id": "tradepro_client_id"},
    ("io", "industry_product_mix"): {"industry_id": "industria_id", "codigo_produto": "sku", "cod_barras": "ean",
                                     "nome_produto": "descricao", "categoria": "categoria", "familia": "familia",
                                     "sabor": "sabor", "gramatura": "gramatura", "embalagem": "embalagem",
                                     "shelf_life_dias": "shelf_life_dias"},
    ("io", "promoters"): {"nome": "nome", "codigo_externo": "codigo_tradepro", "telefone": "telefone",
                          "supervisor_id": "supervisor_id", "regiao": "regiao"},
    ("io", "supervisors"): {"nome": "nome", "codigo_externo": "codigo_tradepro", "telefone": "telefone", "regiao": "regiao"},
    ("books", "stores"): {"name": "nome", "address": "endereco"},
    ("books", "brands"): {"name": "nome"},
    ("books", "skus"): {"brand": "industria_id", "code": "sku", "name": "descricao"},
    ("books", "promoters"): {"name": "nome", "phone": "telefone"},
    ("crm", "clients"): {"company": "nome", "cnpj": "cnpj", "segment": "segmento"},
    ("crm", "redes"): {"nome": "nome"},
    ("crm", "lojas"): {"nome": "nome", "rede": "rede_id", "cnpj": "cnpj", "cidade": "cidade", "estado": "uf",
                       "endereco": "endereco", "bairro": "bairro", "cep": "cep", "latitude": "latitude", "longitude": "longitude"},
    ("crm", "industrias"): {"nome": "nome"},
    ("crm", "promotores"): {"nome": "nome", "telefone": "telefone", "user_id": "usuario_id", "participant_jid": "whatsapp_jid"},
    ("crm", "capacidade_operacional"): {"nome": "nome"},
    ("crm", "entidades_juridicas"): {"razao_social": "razao_social", "nome_fantasia": "nome_fantasia", "cnpj": "cnpj"},
    ("mr", "clientes"): {"nome": "nome"},
    ("mr", "promotores"): {"nome": "nome"},
    ("mr", "cnpjs"): {"razao_social": "razao_social", "cnpj": "cnpj", "ativo": "ativo"},
    ("mr", "lojas"): {"nome": "nome", "cidade": "cidade", "estado": "uf", "endereco": "endereco", "bairro": "bairro", "cep": "cep"},
}

FK_MESTRE = {"redes": "rede_id", "lojas": "loja_id", "industrias": "industria_id", "produtos": "produto_id",
             "colaboradores": "colaborador_id", "empresas_dcg": "empresa_id"}

# Nao viram tabela.
FORA = {
    ("io", "users"), ("books", "users"), ("crm", "users"), ("mr", "users"),
    ("io", "store_aliases"), ("io", "network_aliases"),          # -> cadastro_aliases (ETL)
    ("io", "operational_data_backups"), ("io", "user_audit_log"),  # backup/arquivo
    ("books", "integrations"),                                  # segredo -> cofre
    ("crm", "execucoes_operacao"), ("crm", "wx_debug"), ("crm", "acessos_log"),
}

# Destino e modulo. Prefixo padrao = sistema; excecoes por colecao.
DESTINO_ESPECIAL = {
    ("crm", "ocorrencias"): ("dp_ocorrencias", "hub", "ocorrencias"),
    ("crm", "tratativas"): ("dp_tratativas", "hub", "ocorrencias"),
    ("crm", "mensagens_whatsapp"): ("dp_mensagens_whatsapp", "hub", "ocorrencias"),
    ("crm", "representantes"): ("dp_representantes", "hub", "ocorrencias"),
    ("crm", "lembretes"): ("dp_lembretes", "hub", "ocorrencias"),
    ("crm", "ia_treino"): ("dp_ia_treino", "hub", "ocorrencias"),
    ("crm", "regras_direcionamento"): ("dp_regras_direcionamento", "hub", "ocorrencias"),
    ("crm", "whatsapp_instances"): ("wa_whatsapp_instances", "hub", "whatsapp"),
    ("crm", "conversations"): ("wa_conversations", "hub", "whatsapp"),
    ("crm", "whatsapp_messages"): ("wa_whatsapp_messages", "hub", "whatsapp"),
    ("crm", "bot_config_grupos"): ("wa_bot_config_grupos", "hub", "whatsapp"),
    ("crm", "bot_sessoes"): ("wa_bot_sessoes", "hub", "whatsapp"),
    ("crm", "theo_ensinamentos"): ("wa_theo_ensinamentos", "hub", "whatsapp"),
    ("crm", "trocas"): ("trade_trocas", "crm", "trade"),
    ("crm", "conquistas"): ("trade_conquistas", "crm", "trade"),
    ("crm", "gamificacao"): ("trade_gamificacao", "crm", "trade"),
    ("crm", "metricas_pdv"): ("trade_metricas_pdv", "crm", "trade"),
    ("crm", "acompanhamentos"): ("trade_acompanhamentos", "crm", "trade"),
    ("crm", "rh_registros"): ("rh_registros", "crm", "rh"),
    ("crm", "qr_registros"): ("rh_qr_registros", "crm", "rh"),
}

SLUG = {"io": "io", "books": "books", "crm": "crm", "mr": "margem-real"}
PREFIXO = {"io": "io", "books": "books", "crm": "crm", "mr": "mr"}

MODULOS = {
    "io": {
        "validades": ["validades_imported", "validades_raw", "validades_base", "validades_corrections", "auditoria_pendencias",
                      "validity_zeroing_records", "validity_manual_updates", "manual_corrections"],
        "rupturas": ["rupturas_imports", "rupturas_base", "rupturas_historico", "operational_cross_evidence"],
        "devolucoes": ["devolucoes_casos", "devolucoes_itens", "devolucoes_timeline", "devolucoes_evidencias", "devolucoes_audit",
                       "devolucoes_import_batches", "devolucoes_mensagens_importadas", "devolucoes_solicitacoes_importadas",
                       "product_aliases"],
        "industrias": ["industry_registry", "industry_store_coverage", "industry_product_mix", "industry_research_config",
                       "industry_validity_policy", "industry_config_audit", "industry_store_product_mix",
                       "industry_tracking_tratativas"],
        "cadastros": ["networks", "stores", "promoters", "supervisors", "store_promoter_assignments", "cadastros_pendencias"],
        "visitas": ["operacional_visitas", "operacional_promotor_dia"],
        "integracoes": ["import_history", "sync_logs", "tradepro_connection_jobs", "tradepro_sync_jobs", "sync_schedule_config",
                        "fotos_tag_base", "fotos_sync_jobs", "tag_mapa_canonico"],
        "configuracoes": ["retention_policy"],
    },
    "books": {
        "books": ["books", "book_photos", "sku_classifications"],
        "cadastros": ["stores", "brands", "skus", "promoters"],
        "regras": ["audit_rules"],
        "sortimento": ["price_tables", "assortment_matrix"],
        "agenda": ["visit_schedules"],
        "rupturas": ["rupture_reports"],
    },
    "crm": {
        "clientes": ["clients", "industrias", "onboarding_itens", "implantacao_plano", "pesquisa_lojas"],
        "comercial": ["deals", "proposals", "contracts", "presentations", "orcamento_versoes", "metas_comerciais"],
        "inteligencia": ["redes", "lojas", "regras_operacionais", "tabela_comercial", "lojas_operacao", "importacoes",
                         "historico_importacoes", "homologacao_modelos_operacao", "auditoria_homologacao_modelos"],
        "operacao": ["capacidade_operacional", "alocacoes_operacao", "tempo_operacional", "necessidades_contratacao", "promotores"],
        "ia": ["ai_templates", "historico_ia"],
        "configuracoes": ["configuracoes_empresa", "entidades_juridicas"],
    },
    "mr": {
        "empresa": ["cnpjs"],
        "financeiro": ["plano_contas", "clientes", "lancamentos", "contas_receber", "contas_pagar", "fechamentos", "contas_bancarias",
                       "contratos", "lojas", "of_conexoes", "fechamento_mensal", "alertas"],
        "pessoal": ["promotores", "pagamentos", "documentos"],
    },
}

NOMES_MODULO = {
    "validades": "Validades", "rupturas": "Rupturas", "devolucoes": "Devoluções", "industrias": "Indústrias",
    "cadastros": "Cadastros", "visitas": "Visitas", "integracoes": "Integrações", "configuracoes": "Configurações",
    "books": "Books", "regras": "Regras de auditoria", "sortimento": "Sortimento e preços", "agenda": "Agenda de visitas",
    "clientes": "Clientes", "comercial": "Comercial", "inteligencia": "Inteligência comercial", "operacao": "Operação",
    "ia": "Assistentes de IA", "trade": "Trade (gamificação, PDV, trocas)", "rh": "RH", "empresa": "Minha empresa",
    "financeiro": "Financeiro", "pessoal": "Pessoal (folha e pagamentos)", "ocorrencias": "Ocorrências", "whatsapp": "WhatsApp",
}

# Campos legados cujo nome colide com as colunas de auditoria geradas.
RENOMEAR = {("io", "validity_manual_updates", "atualizado_em"): "atualizado_em_origem",
            ("io", "tag_mapa_canonico", "criado_em"): "criado_em_origem"}

RELACAO_MULTIPLA = {("books", "brands", "stores"), ("books", "brands", "analysts"), ("books", "brands", "supervisors"),
                    ("books", "promoters", "brands"), ("books", "promoters", "stores")}
ARQUIVO_MULTIPLO = {("crm", "contracts", "attachments"), ("crm", "trocas", "midia"), ("crm", "rh_registros", "anexo"),
                    ("crm", "conquistas", "foto"), ("crm", "ocorrencias", "midia"), ("mr", "documentos", "arquivo")}

# Arquivo de migration de cada destino.
def migration_de(sistema, destino):
    if destino.startswith("dp_") or destino.startswith("wa_"):
        return "008_central_dp_whatsapp"
    if destino.startswith("trade_") or destino.startswith("rh_"):
        return "009_trade_rh"
    return {"io": "004_io", "books": "005_books", "crm": "006_crm", "mr": "007_margem_real"}[sistema]


def tipo_sql(sistema, colecao, f):
    t = f["type"]
    if t == "relation":
        return "uuid[]" if (sistema, colecao, f["name"]) in RELACAO_MULTIPLA else "uuid"
    if t == "file":
        return "text[]" if (sistema, colecao, f["name"]) in ARQUIVO_MULTIPLO else "text"
    return {"text": "text", "editor": "text", "email": "text", "url": "text", "number": "numeric", "bool": "boolean",
            "date": "timestamptz", "json": "jsonb", "select": "text"}[t]


def ident(nome):
    return nome if re.fullmatch(r"[a-z_][a-z0-9_]*", nome) else f'"{nome}"'


def main(raiz):
    base_schemas = os.path.join(raiz, "04-Sistemas/_legado-pocketbase/_schemas-producao")
    schemas = {s: json.load(open(os.path.join(base_schemas, f"{s}.json")))["collections"] for s in SISTEMAS}
    colecoes = {(s, c["name"]): c for s in SISTEMAS for c in schemas[s]}

    # destino de cada colecao
    destino = {}
    modulo = {}
    for (s, n), c in colecoes.items():
        if (s, n) in FORA:
            continue
        if (s, n) in DESTINO_ESPECIAL:
            tabela, slug, mod = DESTINO_ESPECIAL[(s, n)]
        else:
            tabela, slug = f"{PREFIXO[s]}_{n}", SLUG[s]
            mod = next((m for m, lst in MODULOS[s].items() if n in lst), None)
            if mod is None:
                sys.exit(f"sem modulo: {s}.{n}")
        destino[(s, n)] = tabela
        modulo[(s, n)] = (slug, mod)

    def alvo_relacao(s, ref):
        if ref == "users":
            return "usuarios"
        if (s, ref) in MESTRES:
            return MESTRES[(s, ref)]
        return destino.get((s, ref))

    saida = {}
    modulos_usados = {}
    for (s, n), c in sorted(colecoes.items()):
        if (s, n) not in destino:
            continue
        tabela = destino[(s, n)]
        slug, mod = modulo[(s, n)]
        modulos_usados.setdefault(slug, set()).add(mod)
        mestre = MESTRES.get((s, n))
        core = CORE.get((s, n), {})
        linhas = ["  id uuid PRIMARY KEY DEFAULT gen_random_uuid()",
                  "  legado_id text UNIQUE"]
        if mestre:
            linhas.append(f"  {FK_MESTRE[mestre]} uuid NOT NULL REFERENCES public.{mestre}(id) ON DELETE CASCADE")
        comentarios = []
        col_industria = None
        indices_cols = set()
        for f in c["fields"]:
            if f.get("system") or f["name"] in ("id", "created", "updated") or f["type"] == "autodate" or f["name"] in core:
                continue
            nome = RENOMEAR.get((s, n, f["name"]), f["name"])
            tipo = tipo_sql(s, n, f)
            ref = ""
            if f["type"] == "relation" and not tipo.endswith("[]"):
                alvo = alvo_relacao(s, f.get("collectionRef"))
                if alvo:
                    ref = f" REFERENCES public.{alvo}(id) ON DELETE SET NULL"
                    if alvo == "industrias" and col_industria is None:
                        col_industria = nome
            padrao = " DEFAULT false" if tipo == "boolean" else ""
            linhas.append(f"  {ident(nome)} {tipo}{padrao}{ref}")
            indices_cols.add(nome)
            vals = f.get("selectValues") or f.get("values")
            if f["type"] == "select" and vals:
                comentarios.append(f"COMMENT ON COLUMN public.{tabela}.{ident(nome)} IS 'Valores: {' | '.join(vals)}';")
            if f["type"] == "relation":
                comentarios.append(f"COMMENT ON COLUMN public.{tabela}.{ident(nome)} IS 'Relação legada → {f.get('collectionRef')}';")
        linhas += ["  criado_em timestamptz NOT NULL DEFAULT now()", "  atualizado_em timestamptz NOT NULL DEFAULT now()"]
        if mestre:
            linhas.append(f"  UNIQUE ({FK_MESTRE[mestre]})")

        sql = [f"-- {s}.{n}" + (f" (identidade em {mestre})" if mestre else ""),
               f"CREATE TABLE public.{tabela} (\n" + ",\n".join(linhas) + "\n);",
               f"COMMENT ON TABLE public.{tabela} IS 'Origem: {s}.{n} (PocketBase). Dono: {slug}/{mod}.';"]
        sql += comentarios
        sql.append(f"CREATE TRIGGER trg_{tabela}_atualizado_em BEFORE UPDATE ON public.{tabela} "
                   f"FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();")

        # indices do PocketBase
        for idx in c.get("indexes", []):
            m = re.match(r"CREATE (UNIQUE )?INDEX [`\"]?(\w+)[`\"]? ON [`\"]?\w+[`\"]? \((.+?)\)( WHERE .*)?$", idx.replace("`", ""))
            if not m:
                continue
            cols = [x.strip() for x in m.group(3).split(",")]
            cols = [re.sub(r"\bcreated\b", "criado_em", re.sub(r"\bupdated\b", "atualizado_em", x)) for x in cols]
            nomes_cols = [x.split()[0] for x in cols]
            if not all(x in indices_cols or x in ("criado_em", "atualizado_em") for x in nomes_cols):
                continue
            unico = "UNIQUE " if m.group(1) else ""
            nome_idx = f"{tabela}_{'_'.join(nomes_cols)}_{'uk' if unico else 'idx'}"[:63]
            sql.append(f"CREATE {unico}INDEX {nome_idx} ON public.{tabela} ({', '.join(ident(x.split()[0]) + (' ' + ' '.join(x.split()[1:]) if len(x.split()) > 1 else '') for x in cols)});")

        # RLS
        def pode(acao):
            return f"(SELECT public.hub_pode_executar('{slug}', '{mod}', '{acao}'))"
        leitura = pode("visualizar")
        if col_industria:
            leitura += f" AND public.pode_ver_industria({ident(col_industria)})"
        sql += [
            f"ALTER TABLE public.{tabela} ENABLE ROW LEVEL SECURITY;",
            f"CREATE POLICY {tabela}_select ON public.{tabela} FOR SELECT TO authenticated USING ({leitura});",
            f"CREATE POLICY {tabela}_insert ON public.{tabela} FOR INSERT TO authenticated WITH CHECK ({pode('criar')});",
            f"CREATE POLICY {tabela}_update ON public.{tabela} FOR UPDATE TO authenticated USING ({pode('editar')}) WITH CHECK ({pode('editar')});",
            f"CREATE POLICY {tabela}_delete ON public.{tabela} FOR DELETE TO authenticated USING ({pode('deletar')});",
            f"REVOKE ALL ON TABLE public.{tabela} FROM anon;",
            f"GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.{tabela} TO authenticated;",
        ]
        saida.setdefault(migration_de(s, tabela), []).append((tabela, "\n".join(sql)))

    # ordem de criacao respeitando FKs dentro de cada arquivo
    def ordena(itens):
        nomes = {t for t, _ in itens}
        pendentes = dict(itens)
        feitos, ordem = set(), []
        while pendentes:
            avancou = False
            for t, sql in list(pendentes.items()):
                deps = set(re.findall(r"REFERENCES public\.(\w+)\(", sql)) & nomes - {t}
                if deps <= feitos:
                    ordem.append((t, sql))
                    feitos.add(t)
                    del pendentes[t]
                    avancou = True
            if not avancou:
                sys.exit(f"ciclo de FK: {list(pendentes)}")
        return ordem

    # modulos e acoes
    cab = {}
    for slug, mods in modulos_usados.items():
        valores = ", ".join(f"('{m}', '{NOMES_MODULO[m]}')" for m in sorted(mods))
        cab[slug] = (
            f"INSERT INTO public.modulos (system_id, chave, nome)\n"
            f"SELECT s.id, m.chave, m.nome FROM public.systems s\n"
            f"CROSS JOIN (VALUES {valores}) AS m(chave, nome)\n"
            f"WHERE s.slug = '{slug}'\n"
            f"ON CONFLICT (system_id, chave) DO UPDATE SET nome = EXCLUDED.nome;\n\n"
            f"INSERT INTO public.modulo_acoes (modulo_id, chave)\n"
            f"SELECT m.id, a.chave FROM public.modulos m JOIN public.systems s ON s.id = m.system_id\n"
            f"CROSS JOIN (VALUES ('visualizar'), ('criar'), ('editar'), ('deletar')) AS a(chave)\n"
            f"WHERE s.slug = '{slug}'\n"
            f"ON CONFLICT (modulo_id, chave) DO NOTHING;\n"
        )
    slug_do_arquivo = {"004_io": ["io"], "005_books": ["books"], "006_crm": ["crm"], "007_margem_real": ["margem-real"],
                       "008_central_dp_whatsapp": ["hub"], "009_trade_rh": []}

    pasta = os.path.join(raiz, "supabase/db/migrations")
    total = 0
    for arq, itens in sorted(saida.items()):
        grupo = f"20261024_{arq}"
        dir_ = os.path.join(pasta, grupo)
        os.makedirs(dir_, exist_ok=True)
        corpo = [f"-- Migration {grupo} — GERADA por scripts/unificacao/gerar_migrations.py. Não editar à mão:\n"
                 f"-- ajuste o gerador e gere de novo. Origem: schema.json de produção (2026-10-21/22).\n"]
        for slug in slug_do_arquivo[arq]:
            corpo.append(cab[slug])
        for t, sql in ordena(itens):
            corpo.append(sql + "\n")
        open(os.path.join(dir_, "001_tabelas.sql"), "w").write("\n".join(corpo))
        total += len(itens)
        print(f"{grupo}: {len(itens)} tabelas")
    print(f"total {total} tabelas; fora {len(FORA)}; colecoes {len(colecoes)}")
    json.dump({f"{s}.{n}": destino.get((s, n)) for (s, n) in sorted(colecoes)},
              open(os.path.join(raiz, "scripts/unificacao/mapa_destino.json"), "w"), ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main(sys.argv[1])
