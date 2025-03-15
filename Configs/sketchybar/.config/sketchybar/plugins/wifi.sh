#!/bin/bash

update() {
  # Verifica si el WiFi está activado
  if [[ $(networksetup -getairportpower en0) == *"Off"* ]]; then
    sketchybar --set "$NAME" icon="􀙇" label="Off"
    exit 0
  fi

  # Extrae el primer valor de "Signal / Noise:" (RSSI)
  SIGNAL=$(system_profiler SPAirPortDataType | grep "Signal / Noise:" | head -n 1 | awk '{print $4}')

  # Si no se obtiene la señal, mostrar N/A
  if [ -z "$SIGNAL" ]; then
    sketchybar --set "$NAME" icon="󰤯 " label="N/A"
    exit 0
  fi

  # Determina el ícono según la intensidad de la señal
  if [ "$SIGNAL" -ge -50 ]; then
    ICON="󰤨 " # Señal fuerte
  elif [ "$SIGNAL" -ge -70 ]; then
    ICON="󰤢 " # Señal media
  else
    ICON="󰤟 " # Señal débil
  fi

  sketchybar --set "$NAME" icon="$ICON"
}

case "$SENDER" in
"routine" | "forced")
  update
  ;;
esac
