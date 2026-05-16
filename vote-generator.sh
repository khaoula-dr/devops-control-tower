#!/bin/bash

VOTE_URL="http://vote.devops.local"
TOTAL_VOTES=200
CATS_PERCENT=70  # 70% chats, 30% chiens

echo "🗳️ Génération de $TOTAL_VOTES votes..."
echo "🐱 Chats: $CATS_PERCENT% | 🐶 Chiens: $((100-CATS_PERCENT))%"

for i in $(seq 1 $TOTAL_VOTES); do
  RAND=$((RANDOM % 100))
  if [ $RAND -lt $CATS_PERCENT ]; then
    VOTE="a"  # Chats
  else
    VOTE="b"  # Chiens
  fi

  curl -s -X POST "$VOTE_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "vote=$VOTE" \
    -c /tmp/cookie_$i.txt \
    -b /tmp/cookie_$i.txt \
    > /dev/null

  if [ $((i % 20)) -eq 0 ]; then
    echo "✅ $i/$TOTAL_VOTES votes envoyés..."
  fi

  sleep 0.3
done

echo "🎉 Done! $TOTAL_VOTES votes générés !"
echo "🔗 Résultats : http://result.devops.local"
