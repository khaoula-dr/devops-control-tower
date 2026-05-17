#!/bin/bash
# Lance tous les tests de sécurité dans l'ordre
# Usage : bash tests-security/run-all-tests.sh
# Prérequis : k3s running, OPA Gatekeeper installé, namespace voting créé

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS_COUNT=0
FAIL_COUNT=0
ERRORS=()

log_section() { echo ""; echo "══════════════════════════════════════"; echo "  $1"; echo "══════════════════════════════════════"; }
log_ok()      { echo "✅ $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
log_fail()    { echo "❌ $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); ERRORS+=("$1"); }

# ── PREREQUIS ──────────────────────────────────────────────
log_section "Vérification prérequis"

command -v kubectl   &>/dev/null && log_ok  "kubectl disponible" || log_fail "kubectl manquant"
command -v trivy     &>/dev/null && log_ok  "trivy disponible"   || log_fail "trivy manquant"
command -v gitleaks  &>/dev/null && log_ok  "gitleaks disponible" || log_fail "gitleaks manquant"

kubectl get ns voting &>/dev/null && log_ok "namespace voting existe" || log_fail "namespace voting manquant"

# ── TEST 1 : OPA bloque le pod non conforme ────────────────
log_section "TEST 1 — OPA Gatekeeper bloque fail-opa-policy"
OUTPUT=$(kubectl apply -f "$SCRIPT_DIR/fail-opa-policy.yaml" 2>&1)
if echo "$OUTPUT" | grep -q "denied\|Forbidden"; then
  log_ok "OPA a bloqué le pod non conforme"
  echo "   Message OPA : $(echo "$OUTPUT" | grep -o '\[.*\]' | head -3)"
else
  log_fail "OPA n'a PAS bloqué — vérifier que Gatekeeper est installé"
fi

# ── TEST 2 : OPA accepte le pod conforme ──────────────────
log_section "TEST 2 — OPA Gatekeeper accepte pass-compliance"
OUTPUT=$(kubectl apply -f "$SCRIPT_DIR/pass-compliance.yaml" 2>&1)
if echo "$OUTPUT" | grep -q "created\|configured"; then
  log_ok "OPA a accepté le pod conforme"
  kubectl wait --for=condition=Ready pod/test-security-compliant \
    -n voting --timeout=60s &>/dev/null && log_ok "Pod Ready en moins de 60s"
else
  log_fail "Le pod conforme a été rejeté : $OUTPUT"
fi

# ── TEST 3 : NetPol bloque le pod non autorisé ───────────
log_section "TEST 3 — NetPol bloque fail-network-policy"
kubectl apply -f "$SCRIPT_DIR/fail-network-policy.yaml" &>/dev/null
sleep 5
OUTPUT=$(kubectl exec -n voting test-netpol-failure -- \
  sh -c "nc -zv redis 6379 -w 3" 2>&1)
if echo "$OUTPUT" | grep -qiE "timed out|refused|bad address|no route"; then
  log_ok "NetPol a bloqué le pod non autorisé vers Redis"
else
  log_fail "NetPol n'a PAS bloqué — connexion Redis réussie depuis pod non autorisé"
fi

# ── TEST 4 : NetPol autorise le flux vote→redis ──────────
log_section "TEST 4 — NetPol autorise flux vote→redis"
bash "$SCRIPT_DIR/pass-network-flow.sh" &>/dev/null
[ $? -eq 0 ] && log_ok "Flux autorisés fonctionnels" || log_fail "Flux autorisés bloqués"

# ── TEST 5 : Gitleaks détecte les secrets ────────────────
log_section "TEST 5 — Gitleaks détecte fail-gitleaks-secrets.txt"
OUTPUT=$(gitleaks detect \
  --source="$SCRIPT_DIR/fail-gitleaks-secrets.txt" \
  --config=security/gitleaks-config/.gitleaks.toml \
  --no-git 2>&1)
if [ $? -ne 0 ]; then
  log_ok "Gitleaks a détecté les faux secrets (exit 1)"
else
  log_fail "Gitleaks n'a PAS détecté les secrets"
fi

# ── TEST 6 : Gitleaks ne bloque pas le code propre ───────
log_section "TEST 6 — Gitleaks valide le code propre"
bash "$SCRIPT_DIR/pass-gitleaks-clean.sh" &>/dev/null
[ $? -eq 0 ] && log_ok "Code propre validé par Gitleaks" || log_fail "Faux positif Gitleaks"

# ── TEST 7 : Trivy détecte image vulnérable ──────────────
log_section "TEST 7 — Trivy détecte vulnérabilités CRITICAL"
bash "$SCRIPT_DIR/fail-trivy-image.sh" &>/dev/null
[ $? -eq 0 ] && log_ok "Trivy a bien détecté des CRITICAL" || log_fail "Trivy n'a pas détecté de CRITICAL"

# ── TEST 8 : Trivy valide image propre ───────────────────
log_section "TEST 8 — Trivy valide image propre"
bash "$SCRIPT_DIR/pass-trivy-clean.sh" &>/dev/null
[ $? -eq 0 ] && log_ok "Image propre validée par Trivy" || log_fail "Trivy a trouvé des CRITICAL sur image propre"

# ── CLEANUP ───────────────────────────────────────────────
log_section "Nettoyage pods de test"
kubectl delete pod test-opa-failure test-netpol-failure test-security-compliant \
  -n voting --ignore-not-found &>/dev/null
log_ok "Pods de test supprimés"

# ── RAPPORT FINAL ─────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════"
echo "  RAPPORT FINAL — Tests sécurité M4"
echo "══════════════════════════════════════════════"
echo "  ✅ Réussis  : $PASS_COUNT"
echo "  ❌ Échoués  : $FAIL_COUNT"
echo "──────────────────────────────────────────────"
if [ $FAIL_COUNT -eq 0 ]; then
  echo "  🎯 Tous les tests sont passés — prêt pour la démo jury"
  exit 0
else
  echo "  ⚠️  Erreurs détectées :"
  for err in "${ERRORS[@]}"; do echo "     → $err"; done
  exit 1
fi