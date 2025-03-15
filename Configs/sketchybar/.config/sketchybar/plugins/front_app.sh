#!/bin/sh

# Some events send additional information specific to the event in the $INFO
# variable. E.g. the front_app_switched event sends the name of the newly
# focused application in the $INFO variable:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting
case "$INFO" in
"Firefox" | "Safari" | "Arc" | "Chrome")
  ICON=󰖟
  ;;
"Slack")
  ICON=󰒱
  ;;
"Terminal" | "iTerm2" | "Ghostty" | "Warp")
  ICON=
  ;;
"Visual Studio Code")
  ICON=󰨞
  ;;
"Spotify")
  ICON=󰓇
  ;;
"Finder")
  ICON=
  ;;
"Mail")
  ICON=
  ;;

"IntelliJ IDEA")
  ICON=󰬷
  ;;
"WebStorm")
  ICON=
  ;;
"DataGrip" | "DBeaver" | "DBeaver Community")
  ICON=
  ;;
"System Settings")
  ICON=
  ;;
*)
  # Icon por defecto para otras aplicaciones
  ICON=
  ;;
esac
if [ "$SENDER" = "front_app_switched" ]; then
  sketchybar --set "$NAME" icon.padding_left=20 icon="$ICON" label="$INFO" icon.color=0xfffab387
fi
