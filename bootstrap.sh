#!/bin/bash

set -e

CATALOG_REPO="git@github.com:fnsousa/sdd-central-skills.git"
BRANCH="main"

SPECIFY_DIR=".specify"
SKILLS_DIR="${SPECIFY_DIR}/skills"
SKILLS_FILE="${SPECIFY_DIR}/skills.yaml"

if [ ! -f "$SKILLS_FILE" ]; then
    echo "Arquivo ${SKILLS_FILE} não encontrado."
    exit 1
fi

mkdir -p "$SKILLS_DIR"

cd "$SKILLS_DIR"

if [ ! -d ".git" ]; then
    git init
    git remote add origin "$CATALOG_REPO"
fi

git sparse-checkout init --cone

SPARSE_PATHS=""

while IFS= read -r skill
do
    skill=$(echo "$skill" | xargs)

    if [ -n "$skill" ]; then
        SPARSE_PATHS="${SPARSE_PATHS} skills/${skill}"
    fi

done < <(grep '^  - ' "../../${SKILLS_FILE}")

git sparse-checkout set $SPARSE_PATHS

git pull origin "$BRANCH"

echo ""
echo "Skills carregadas:"
echo "$SPARSE_PATHS"