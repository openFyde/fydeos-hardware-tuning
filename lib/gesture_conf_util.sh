#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

import_lib input_util

declare -rg _USER_GESTURE_CONF="/mnt/stateful_partition/unencrypted/gesture/60-user-defined-devices.conf"
declare -rg _TMP_GESTURE_CONF="/tmp/user_defined_gesture.conf"
declare -ag _GESTURE_OPTIONS=(
  "Mouse CPI"
  "Force Scroll Wheel Emulation"
  "Pressure Calibration Offset"
  "Pressure Calibration Slope"
  "Tap Minimum Pressure"
  "Two Finger Vertical Close Distance Thresh"
)
declare -Ag _GESTURE_TYPE_OPTIONS=(
  ["Mouse"]="0 1"
  ["Touchpad"]="2 3 4 5"
)

# same type as _CURRENT_INPUT_DEV like /sys/class/input/inputX
declare -g _CURRENT_GESTURE_DEVICE=""

set_current_gesture_device() {
  _CURRENT_GESTURE_DEVICE="$1"
}

init_gesture_config() {
  local dir_gesture=$(dirname $_USER_GESTURE_CONF)
  if [ ! -d $dir_gesture ]; then
    sudo mkdir $dir_gesture
  fi
  if [ ! -f $_USER_GESTURE_CONF ]; then
    sudo touch $_USER_GESTURE_CONF
  fi
  cat $_USER_GESTURE_CONF > $_TMP_GESTURE_CONF
}

save_gesture_config() {
  if [ ! -f $_TMP_GESTURE_CONF ]; then
    return
  fi
  local md5tmp=$(md5sum $_TMP_GESTURE_CONF)
  local md5target=$(md5sum $_USER_GESTURE_CONF)
  if [ "${md5tmp% *}" == "${md5target% *}" ]; then
    echo 1
    return
  fi
  sudo sh -c "cat $_USER_GESTURE_CONF > $_USER_GESTURE_CONF.bak" >/dev/null
  sudo cp $_TMP_GESTURE_CONF $_USER_GESTURE_CONF >/dev/null
  echo 0
}

get_gesture_config_from_tmp() {
  local dev="${1:-$_CURRENT_GESTURE_DEVICE}"
  local devname="$(input_device_name $dev| sed 's/\//\\\//g')"
  sed -e "/$devname/,/EndSection/ p" -n $_TMP_GESTURE_CONF | head -n -1
}

get_gesture_options_caption() {
  local dev="${1:-$_CURRENT_GESTURE_DEVICE}"
  local IFS="\""
  while read d1 d2 d3 d4; do
    echo $d2
  done <<< $(get_gesture_config_from_tmp $dev | grep Option)
}

insert_driver_gesture_base() {
  local dev="${1:-$_CURRENT_GESTURE_DEVICE}"
  local devname="$(input_device_name $dev)"
  if [ -n "$(get_gesture_config_from_tmp $dev)" ]; then
    return
  fi
  printf "
#This section is create by a script, do not change it manually
Section \"InputClass\"
    Identifier      \"$devname Profile\"
    MatchProduct    \"$devname\"
    " >> $_TMP_GESTURE_CONF
  if [ "$(input_device_type $dev)" == "Touchpad" ]; then
    printf "MatchIsTouchpad \"on\"" >> $_TMP_GESTURE_CONF
  fi
  printf "
    MatchDevicePath \"/dev/input/event*\"
    Driver          \"$(input_device_driver_name $dev)\"
EndSection
" >> $_TMP_GESTURE_CONF
}

edit_option_of_gesture() {
  local option="$1"
  local value="$2"
  local dev=${3:-$_CURRENT_GESTURE_DEVICE}
  local devname="$(input_device_name $dev | sed 's/\//\\\//g')"
  if [ -z "$value" ]; then
    sed -e "/$devname/,/EndSection/! b" \
      -e "/$option/d" \
      -i $_TMP_GESTURE_CONF
    return
  fi
  if [ -n "$(get_gesture_options_caption $dev | grep "$option")" ]; then
    sed -e "/$devname/,/EndSection/! b" \
      -e "/$option/ c \    Option          \"$option\" \"$value\"" \
      -i $_TMP_GESTURE_CONF
  else
    sed -e "/$devname/,/EndSection/! b" \
      -e "/Driver/ a \    Option          \"$option\" \"$value\"" \
      -i $_TMP_GESTURE_CONF
  fi
}

insert_tap_as_click() {
  local dev=${1:-$_CURRENT_GESTURE_DEVICE}
  edit_option_of_gesture "Pressure Calibration Offset" "0" $dev
  edit_option_of_gesture "Tap Minimum Pressure" "1.0" $dev
}
