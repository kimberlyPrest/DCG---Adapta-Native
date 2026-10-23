# Submodules dos Sistemas

Mesma decisão do Lucenera: cada sistema é submodule em `04-Sistemas/`. O central guarda o ponteiro; o código é commitado no repo do sistema.

## Situação em 2026-10-23

O repositório central ainda **não tem git**. As 4 bases Skip (`sistema-1-io` ... `sistema-4-margem-real`) estão clonadas em `04-Sistemas/` e são elas que viram submodules. O legado PocketBase (`_legado-pocketbase/`) não vira submodule. Antes de registrar:

1. Tornar privados os repos `Sistema-1..4` e os do legado (B-01, SEG-01).
2. Criar o repo central no GitHub (privado), `git init`, adicionar remote.
4. `./scripts/submodules-register.sh` — pula sistema com mudança local ou commit não enviado.

Atenção: o repositório central fica no Google Drive. Git dentro de pasta sincronizada pelo Drive pode corromper `.git` em sincronização simultânea. Recomendação: clone de trabalho fora do Drive (ex.: `~/Documents/DCG - Adapta Native`), e o Drive só como espelho de leitura.

## Clonar tudo

```bash
git clone --recurse-submodules <URL_DO_REPO_CENTRAL> "DCG - Adapta Native"
```

## Atualizar depois de pull

```bash
git pull
git submodule sync --recursive
git submodule update --init --recursive --jobs 8
```

## Mudar código de um sistema

```bash
cd "04-Sistemas/<sistema>"
git checkout main && git pull
# alterar, testar
git add <arquivos> && git commit -m "feat: ..." && git push
cd ../..
git add "04-Sistemas/<sistema>" CHANGELOG.md "03-Projeto/SPECs/<SPEC>.md"
git commit -m "chore: update <sistema> submodule"
```

Nunca commitar no central ponteiro para commit não enviado ao GitHub do sistema.
