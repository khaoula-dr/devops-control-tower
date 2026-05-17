#!/bin/bash
# Script de scan Trivy local — à utiliser avant de pousser
# Usage: ./trivy-report.sh <image:tag>

IMAGE=${1:-"votingapp/vote:latest"}

echo "=== Scan Trivy de l'image: $IMAGE ==="
trivy image \
  --severity CRITICAL,HIGH \
  --exit-code 0 \
  --format table \
  "$IMAGE"

echo ""
echo "=== Scan avec exit-code 1 (bloquant) ==="
trivy image \
  --severity CRITICAL \
  --exit-code 1 \
  --ignore-unfixed \
  "$IMAGE"

if [ $? -eq 0 ]; then
  echo "✅ Aucune vulnérabilité CRITICAL — image approuvée"
else
  echo "❌ Vulnérabilité CRITICAL détectée — push bloqué"
  exit 1
fi