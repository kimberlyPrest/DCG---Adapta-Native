#!/usr/bin/env bash
# Registra os sistemas de 04-Sistemas como submodules do repo central.
# Rodar uma vez, depois de `git init` + remote do repo central (privado).
# Pula pastas com mudancas locais nao commitadas: commitar/pushar no repo do
# sistema antes, senao o ponteiro aponta para algo que ninguem consegue clonar.
set -euo pipefail

cd "$(dirname "$0")/.."

# Bases Skip (Supabase unico). O legado PocketBase em _legado-pocketbase/
# nao vira submodule: e so fonte de codigo para portar.
SISTEMAS=(
  "sistema-1-io"
  "sistema-2-books"
  "sistema-3-crm"
  "sistema-4-margem-real"
  "sistema-5-central-dp"
)

for s in "${SISTEMAS[@]}"; do
  path="04-Sistemas/$s"
  if [ ! -d "$path/.git" ]; then
    echo "PULADO $s: sem .git"
    continue
  fi
  if [ -n "$(git -C "$path" status --porcelain)" ]; then
    echo "PULADO $s: mudancas locais nao commitadas"
    continue
  fi
  if [ -n "$(git -C "$path" log --oneline '@{u}..' 2>/dev/null)" ]; then
    echo "PULADO $s: commits locais nao enviados"
    continue
  fi
  url="$(git -C "$path" remote get-url origin)"
  git submodule add "$url" "$path"
  echo "OK $s -> $url"
done
