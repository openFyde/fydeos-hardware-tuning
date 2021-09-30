#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

declare -g SYS_CLASS_INPUT_PATH="/sys/class/input"
declare -Ag _INPUT_TYPES=(
  ["Touchpad"]="ID_INPUT_TOUCHPAD=1"
  ["PointingStick"]="ID_INPUT_POINTINGSTICK=1"
  ["Mouse"]="ID_INPUT_MOUSE=1"
  ["Touchscreen"]="ID_INPUT_TOUCHSCREEN=1"
  ["Tablet"]="ID_INPUT_TABLET=1"
)
declare -g _CURRENT_INPUT_DEV=""

set_current_input_device() {
  _CURRENT_INPUT_DEV=$1
}

list_input_devices_path() {
  ls -d $SYS_CLASS_INPUT_PATH/input* 2>/dev/null
}

input_device_name() {
  local dev_path=${1:-$_CURRENT_INPUT_DEV}
  cat $dev_path/name
}

input_device_event_dev() {
  local dev_path=${1:-$_CURRENT_INPUT_DEV}
  local evname=$(basename $(ls -d $dev_path/event*))
  echo /dev/input/$evname
}

input_device_evtest() {
  local dev_path=${1:-$_CURRENT_INPUT_DEV}
  evtest $(input_device_event_dev $dev_path)
}

input_device_properties() {
  local dev_path=${1:-$_CURRENT_INPUT_DEV}
  udevadm info -q property $dev_path 
}

input_device_type() {
  local dev_path=${1:-$_CURRENT_INPUT_DEV}
  for key in "${!_INPUT_TYPES[@]}"; do
    if [ -n "$(input_device_properties $dev_path | grep ${_INPUT_TYPES["$key"]})" ];then
      echo $key
      break
    fi
  done
}

input_device_driver_name() {
  local dev_path=${1:-$_CURRENT_INPUT_DEV}
  local dname=$(udevadm info -q property $dev_path/device |grep "DRIVER=")
  echo ${dname#DRIVER=}
}
