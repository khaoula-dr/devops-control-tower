#!/bin/bash
# TEST POSITIF — Gitleaks ne doit trouver AUCUN secret
# L'exclusion de fail-gitleaks-secrets.txt est dans .gitleaks.toml (allowlist)
#
# Résultat attendu :
#   No leaks found
#   exit code 0

echo "=============================================="
echo "✅ TEST PASS — Scan Gitleaks propre"
echo "=============================================="
echo ""

# On lance depuis la racine du repo
REPO_ROOT="$(git rev-parse --show-toplevel)"

gitleaks detect \
  --source="$REPO_ROOT" \
  --config="$REPO_ROOT/security/gitleaks-config/.gitleaks.toml" \
  --no-git \
  --verbose

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo "✅ TEST REUSSI : Aucun secret détecté dans le repo"
  echo "   → Le pre-commit hook aurait laissé passer ce commit"
else
  echo "❌ Des secrets ont été trouvés hors du fichier de test"
  echo "   → Nettoyez ces fichiers avant de pusher"
  exit 1
fi
