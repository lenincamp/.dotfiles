#!/usr/bin/env bash

FONT_FACE="Maple Mono NF"
# make sure it's executable with:
# chmod +x ~/.config/sketchybar/plugins/aerospace.sh
colors=(
  "0xfff4dbd6" # Rosewater
  "0xfff0c6c6" # Flamingo
  "0xfff5bde6" # Pink
  "0xffcba6f7" # Mauve
  "0xff8bd5ca" # Teal
  "0xffed8796" # Red
  "0xffee99a0" # Maroon
  "0xffa6da95" # Green
  "0xffeed49f" # Yellow
  "0xfffab387" # Peach
  "0xfff5a97f" # Lavender
  "0xff8aadf4" # Blue
  "0xff91d7e3" # Sky
  "0xff7dc4e4" # Sapphire
)

SID=$1
MEDIUM_FONT_SIZE=$2
LARGE_FONT_SIZE=$3

# Selecciona un color aleatorio
random_color="${colors[$((RANDOM % ${#colors[@]}))]}"
if [ "$SID" = "$FOCUSED_WORKSPACE" ]; then
  # sketchybar --set $NAME background.drawing=on background.color="$random_color" label.color=0xff24273a label.font="$FONT_FACE:Bold:$MEDIUM_FONT_SIZE"
  sketchybar --set $NAME background.drawing=on label.color="$random_color" label.font="$FONT_FACE:Bold:$LARGE_FONT_SIZE"
else
  # sketchybar --set $NAME background.drawing=off label.color=0xffcdd6f4 label.font="$FONT_FACE:Medium:$MEDIUM_FONT_SIZE"
  sketchybar --set $NAME background.drawing=off label.color=0xffcdd6f4 label.font="$FONT_FACE:Medium:$MEDIUM_FONT_SIZE"
fi
