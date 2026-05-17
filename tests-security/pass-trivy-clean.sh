#!/bin/bash
# TEST POSITIF — Trivy ne doit trouver AUCUNE CRITICAL sur l'image de prod
# Image utilisée : python:3.9-slim (image de base du service vote)
#
# Résultat attendu :
#   Total: 0 (CRITICAL: 0)
#   exit code 0

echo "=============================================="
echo "✅ TEST PASS — Scan Trivy image propre"
echo "=============================================="
echo ""

IMAGE="python:3.9-slim"
echo "Image cible : $IMAGE"
echo ""

trivy image \
  --severity CRITICAL \
  --exit-code 1 \
  --ignore-unfixed \
  --no-progress \
  "$IMAGE"

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo "✅ TEST REUSSI : 0 vulnérabilité CRITICAL non corrigée"
  echo "   → Cette image est approuvée pour le déploiement"
else
  echo "❌ Des CRITICAL ont été trouvées sur $IMAGE"
  echo "   → Changer d'image de base ou appliquer les patchs"
  exit 1
fi