#!/bin/bash

set -euo pipefail

CATALOG_REPO="git@github.com:fnsousa/sdd-central-skills.git"
BRANCH="main"

SPECIFY_DIR=".specify"
SKILLS_DIR="${SPECIFY_DIR}/skills"
SKILLS_FILE="${SPECIFY_DIR}/skills.yaml"

if [ ! -f "$SKILLS_FILE" ]; then
    echo "Arquivo ${SKILLS_FILE} não encontrado."
    exit 1
fi

TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

echo "Baixando catálogo..."

git clone \
    --depth 1 \
    --branch "$BRANCH" \
    "$CATALOG_REPO" \
    "$TEMP_DIR"

mkdir -p "$SKILLS_DIR"

EXPECTED_SKILLS=$(mktemp)

grep '^[[:space:]]*-' "$SKILLS_FILE" | while read -r line
do
    skill=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//')

    NAME=$(echo "$skill" | cut -d'@' -f1)
    VERSION=$(echo "$skill" | cut -d'@' -f2)

    SOURCE="${TEMP_DIR}/${NAME}/${VERSION}.md"

    echo "Processando ${NAME}@${VERSION}..."

    if [ ! -f "$SOURCE" ]; then
        echo ""
        echo "Skill não encontrada:"
        echo "  ${NAME}@${VERSION}"
        exit 1
    fi

    TARGET_DIR="${SKILLS_DIR}/${NAME}"
    TARGET_FILE="${TARGET_DIR}/skill.md"

    mkdir -p "$TARGET_DIR"

    cp "$SOURCE" "$TARGET_FILE"

    echo "$TARGET_DIR" >> "$EXPECTED_SKILLS"

    echo "✓ ${NAME}@${VERSION}"
done

echo ""
echo "Removendo skills não utilizadas..."

find "$SKILLS_DIR" -type f -name "skill.md" | while read -r skill_file
do
    skill_dir=$(dirname "$skill_file")

    if ! grep -Fxq "$skill_dir" "$EXPECTED_SKILLS"; then
        echo "🗑 Removendo $(realpath --relative-to="$SKILLS_DIR" "$skill_dir" 2>/dev/null || echo "$skill_dir")"
        rm -rf "$skill_dir"
    fi
done

rm -f "$EXPECTED_SKILLS"

echo ""
echo "Bootstrap concluído."