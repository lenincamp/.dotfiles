#!/bin/sh

# Some events send additional information specific to the event in the $INFO
# variable. E.g. the front_app_switched event sends the name of the newly
# focused application in the $INFO variable:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting
ICON_PADDING_RIGHT=5
case "$INFO" in
"Firefox" | "Safari" | "Arc" | "Chrome" | "Brave Browser")
  ICON=󰖟
  ;;
"Calendar")
  ICON=
  ICON_PADDING_RIGHT=3
  ;;
"Discord")
  ICON=
  ;;
"FaceTime")
  ICON_PADDING_RIGHT=5
  ICON=
  ;;
"Finder")
  ICON=󰀶
  ;;
"Messages")
  ICON=
  ;;
"Notion")
  ICON=󰎚
  ICON_PADDING_RIGHT=6
  ;;
"Preview")
  ICON=
  ICON_PADDING_RIGHT=3
  ;;
"TextEdit")
  ICON=
  ICON_PADDING_RIGHT=4
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
  ICON_PADDING_RIGHT=2
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
  ICON=
  ICON_PADDING_RIGHT=2
  ;;
esac
if [ "$SENDER" = "front_app_switched" ]; then
  # sketchybar --set "$NAME" icon.padding_left=20 icon="$ICON" label="$INFO" icon.color=0xfffab387
  sketchybar --set $NAME icon=$ICON icon.padding_right=$ICON_PADDING_RIGHT
  sketchybar --set $NAME.name label="$INFO"
fi
