#!/bin/bash
# Warten bis rkdeveloptool ein Maskrom-Gerät meldet
# und danach Flash-Befehle ausführen.

INTERVAL="${1:-2}"  # Sekunden zwischen Versuchen
LOADER="output/uboot/rk3588_spl_loader_v1.19.113.bin"
IMAGE="output/radxa_debian.img"

PATTERN='DevNo=1[[:space:]]+Vid=0x2207,Pid=0x350b,LocationID=209[[:space:]]+Maskrom'

echo "🔍 Warte auf Gerät im Maskrom-Modus..."

while true; do
  output="$(sudo rkdeveloptool ld 2>&1 || true)"
  output="${output//$'\r'/}"
  echo "$output"

  if grep -qE "$PATTERN" <<<"$output"; then
    echo "✅ Gerät gefunden (Maskrom)"
    break
  fi

  echo "❌ Noch kein Gerät, warte..."
  sleep "$INTERVAL"
done

echo "🚀 Lade SPL Loader..."
if sudo rkdeveloptool db "$LOADER"; then
  sleep 5
  echo "📦 Schreibe Image..."
  if sudo rkdeveloptool wl 0 "$IMAGE"; then
    sleep 5
    echo "🔄 Neustart..."
    sudo rkdeveloptool rd
    echo "🎉 Flash-Vorgang abgeschlossen."
  else
    echo "⚠️ Fehler beim Schreiben des Images!"
    exit 2
  fi
else
  echo "⚠️ Fehler beim Laden des Loaders!"
  exit 1
fi
