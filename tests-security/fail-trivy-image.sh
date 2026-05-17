#!/bin/bash
# TEST NEGATIF — Trivy doit DETECTER des vulnérabilités CRITICAL
# On scanne une vieille image connue pour être vulnérable
#
# Résultat attendu :
#   CRITICAL: N vulnérabilités détectées
#   exit code 1 → pipeline bloqué

echo "=============================================="
echo "❌ TEST FAIL — Scan image vulnérable"
echo "=============================================="
echo "Image cible : python:3.4-slim (ancienne, pleine de CVE)"
echo ""

trivy image \
  --severity CRITICAL \
  --exit-code 1 \
  --ignore-unfixed \
  --no-progress \
  python:3.4-slim

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -ne 0 ]; then
  echo "✅ TEST REUSSI : Trivy a bien détecté des vulnérabilités CRITICAL"
  echo "   → Dans le pipeline CI, ce build aurait été BLOQUÉ"
else
  echo "⚠️  Aucune CRITICAL trouvée sur cette image (essaie avec nginx:1.14)"
fi