#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

import_libs input_util gesture_conf_util

init_gesture_and_show() {
  set_current_gesture_device "$1"
  set_current_input_device "$1"
  register_console gesture
}

gesture_console_in() {
  init_gesture_config 
  insert_driver_gesture_base
}

gesture_console_out() {
  local answer
  read -n 1 -p "Would you like to save your gesture configration to the system? Press [y] for yes, others to skip:" answer
  if [ "$answer" == "y" ];then
    echo ""
    if [ $(save_gesture_config) -eq 0 ]; then
      OkMsg "Reboot or restart UI to reload the gesture configrations."
    else
      WarnMsg "Nothing has changed."
    fi
  fi
}

edit_gesture_option() {
  local option="$1"
  read -p "Please input the value for the option \"$option\", an empty value will remove the option from configration:" value
  edit_option_of_gesture "$option" "$value"
  show_menu
}

edit_gesture_manually() {
  local option
  read -p "Input the Option caption:" option
  if [ -n "$option" ]; then
    edit_gesture_option "$option"
  else
    WarnMsg "No caption input."
    show_menu
  fi
}

gesture_show_menu() {
  local -A combarray
  local option keys
  printf "${_WHITE}Current Device:${_NC}$(input_device_event_dev) ${_WHITE}Driver:${_NC}$(input_device_name)\n"
  printf "${_BG_GREEN}Gesture Options:${_NC}\n"
  print_line '.'
  get_gesture_config_from_tmp
  print_line
  while read option; do
    [ -n "$option" ] && combarray["$option"]=1
  done <<< $(get_gesture_options_caption)
  keys="${_GESTURE_TYPE_OPTIONS[$(input_device_type)]}"
  if [ -z "$keys" ]; then
    keys="$(seq 0 $((${#_GESTURE_OPTIONS[@]}-1)))"
  fi
  for key in $keys; do
    combarray["${_GESTURE_OPTIONS[$key]}"]=1
  done
  for key in "${!combarray[@]}"; do
    register_item_and_description "edit_gesture_option \"$key\"" \
      "Edit option: $key"
  done
  if [ "$(input_device_type)" == "Touchpad" ]; then
    register_item_and_description "insert_tap_as_click" \
      "Add some options to apply the feature: Tap-As-Click"
  fi 
  register_item_and_description "edit_gesture_manually" \
    "Add new option"
}

gesture_show_help() {
  echo "Reference url: [https://www.x.org/releases/current/doc/man/man5/xorg.conf.5.xhtml#heading9]" 
}
