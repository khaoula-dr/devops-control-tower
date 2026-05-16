#!/bin/bash

WEBHOOK="https://discord.com/api/webhooks/1505259903495835890/NgVHAl10sdZMZiF_u9BPwlwksNdtEI5F1DCiu1MDMATACEiecKD5rfseCeqYKsPC6IAM"

send_alert() {
  local color=$1
  local title=$2
  local message=$3
  curl -s -H "Content-Type: application/json" \
    -X POST \
    -d "{
      \"embeds\": [{
        \"title\": \"$title\",
        \"description\": \"$message\",
        \"color\": $color,
        \"footer\": {\"text\": \"DevOps Control Tower | $(date '+%d/%m/%Y %H:%M:%S')\"}
      }]
    }" \
    $WEBHOOK > /dev/null
}

echo "Surveillance des pods demarree..."

ALERTED_PODS=""
SYSTEM_OK=true

while true; do
  CURRENT_STATE=$(kubectl get pods -n voting --no-headers 2>/dev/null)
  NOT_RUNNING=$(echo "$CURRENT_STATE" | grep -v "Running" | grep -v "Completed" | grep -v "^$")
  TOTAL=$(echo "$CURRENT_STATE" | grep -c ".")
  RUNNING=$(echo "$CURRENT_STATE" | grep -c "Running")

  # Alerter seulement pour les nouveaux pods en difficulte
  if [ -n "$NOT_RUNNING" ]; then
    while IFS= read -r line; do
      POD_NAME=$(echo "$line" | awk '{print $1}')
      STATUS=$(echo "$line" | awk '{print $3}')
      
      # Envoyer alerte seulement si pas deja alerté
      if [[ "$ALERTED_PODS" != *"$POD_NAME"* ]]; then
        send_alert 15158332 \
          "ALERTE - Pod en difficulte !" \
          "Pod **$POD_NAME** est en status **$STATUS**\nNamespace: voting\nArgoCD va auto-reparer..."
        ALERTED_PODS="$ALERTED_PODS $POD_NAME"
        SYSTEM_OK=false
        echo "Alerte envoyee : $POD_NAME ($STATUS)"
      fi
    done <<< "$NOT_RUNNING"
  fi

  # Envoyer alerte recuperation une seule fois
  if [ "$TOTAL" -gt 0 ] && [ "$TOTAL" -eq "$RUNNING" ] && [ "$SYSTEM_OK" = false ]; then
    send_alert 3066993 \
      "SYSTEME RECUPERE !" \
      "Tous les pods sont de nouveau Running ($RUNNING/$TOTAL)\nArgoCD self-heal a fonctionne !\nNamespace: voting"
    ALERTED_PODS=""
    SYSTEM_OK=true
    echo "Systeme recupere - alerte envoyee"
  fi

  sleep 10
done
