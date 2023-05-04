#!/bin/bash

declare -gr SET_SUSPEND_MODE_SCRIPT="/usr/sbin/set_suspend_mode.sh"

init_suspend_mode_and_show() {
  register_console "suspend_mode"
} 

set_suspend_mode() {
  local mode="$1"
  "$SET_SUSPEND_MODE_SCRIPT" "$mode"
  show_menu
}

get_current_suspend_mode() {
  local mode=""
  mode=$("$SET_SUSPEND_MODE_SCRIPT" | grep "current suspend mode" | awk -F ':' '{print $2}' | tr -d ' ')
  echo "$mode"
}

set_suspend_mode_desc() {
  local title="$1"
  local mode="$2"
  local current_mode="$3"
  if [ "$mode" == "$current_mode" ]; then
    echo "$title (current)"
  else
    echo "$title"
  fi
}

suspend_mode_show_menu() {
  local current_mode=""
  current_mode=$(get_current_suspend_mode)
  register_item_and_description "set_suspend_mode s2idle" "$(set_suspend_mode_desc "S2Idle" "s2idle" "$current_mode")"
  register_item_and_description "set_suspend_mode deep" "$(set_suspend_mode_desc "Deep" "deep" "$current_mode")"
}

is_setting_suspend_mode_support() {
  [[ -x "$SET_SUSPEND_MODE_SCRIPT" ]]
}
