#!/bin/bash
# TEST POSITIF — Vérifier que les flux AUTORISES fonctionnent
# Prérequis : pass-compliance.yaml doit être appliqué
#   kubectl apply -f tests-security/pass-compliance.yaml
#   kubectl wait --for=condition=Ready pod/test-security-compliant -n voting --timeout=60s

echo "=============================================="
echo "✅ TEST PASS — Flux réseau autorisés"
echo "=============================================="
echo ""

NAMESPACE="voting"
POD="test-security-compliant"
PASS=0
FAIL=0

# Fonction de test
test_connection() {
  local label=$1
  local host=$2
  local port=$3
  local netpol=$4

  echo "--- Test : $label ---"
  echo "    NetPol : $netpol"
  echo -n "    Connexion vers $host:$port ... "

  kubectl exec -n "$NAMESPACE" "$POD" -- \
    sh -c "nc -zv $host $port" 2>/dev/null

  if [ $? -eq 0 ]; then
    echo "    ✅ AUTORISÉ — flux fonctionnel"
    PASS=$((PASS + 1))
  else
    echo "    ❌ BLOQUÉ — vérifier la NetPol"
    FAIL=$((FAIL + 1))
  fi
  echo ""
}

# Test 1 : vote → redis (port 6379)
test_connection \
  "vote → redis" \
  "redis" \
  "6379" \
  "allow-vote-to-redis.yaml"

# Test 2 : DNS résolution (port 53)
test_connection \
  "DNS egress" \
  "kube-dns.kube-system.svc.cluster.local" \
  "53" \
  "allow-dns-egress.yaml"

echo "=============================================="
echo "Résultat : $PASS tests réussis / $((PASS + FAIL)) total"
if [ $FAIL -eq 0 ]; then
  echo "✅ Tous les flux autorisés fonctionnent"
else
  echo "❌ $FAIL flux en erreur — vérifier les NetPols"
fi