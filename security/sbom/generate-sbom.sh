#!/bin/bash
# Génère le SBOM pour toutes les images de la Voting App
# Usage: ./generate-sbom.sh <docker-hub-username> <tag>

HUB_USER=${1:-"khaoula-dr"}
TAG=${2:-"latest"}
OUTPUT_DIR="security/sbom/reports"
mkdir -p "$OUTPUT_DIR"

IMAGES=("vote" "result" "worker")

for img in "${IMAGES[@]}"; do
  echo "📦 Génération SBOM pour ${HUB_USER}/${img}:${TAG}..."
  
  syft "${HUB_USER}/${img}:${TAG}" \
    -o spdx-json \
    --file "${OUTPUT_DIR}/${img}-sbom.spdx.json"
  
  echo "✅ SBOM généré: ${OUTPUT_DIR}/${img}-sbom.spdx.json"
done

echo ""
echo "=== SBOMs disponibles ==="
ls -lh "$OUTPUT_DIR/"