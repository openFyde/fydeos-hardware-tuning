#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

import_libs input_util module_param gesture

list_input_devices() {
  local dev_type dev edev
  echo "Input devices list:"
  for dev in $(list_input_devices_path); do
    edev=$(input_device_event_dev $dev)
    dev_type=$(input_device_type $dev)
    printf "Type:${dev_type:-Standard}\t$edev\t[$(input_device_name $dev)]\tDriver:$(input_device_driver_name $dev)\n"
  done
}

test_input_device() {
  local dev=$1
  evtest
  show_menu
}

input_show_menu() {
  local dev_type mod dev_name edev
  local -A mods
  list_input_devices
  print_line "*"
  for dev in $(list_input_devices_path); do
    dev_type=$(input_device_type $dev)
    mod=$(input_device_driver_name $dev)
    dev_name=$(input_device_name $dev)
    edev=$(input_device_event_dev $dev)
    if [[ -n "$edev" && -n  "$mod" ]]; then
      mods["$mod"]+="${edev##*/} "
    fi
    if [ -n "$dev_type" ]; then
			register_item_and_description "init_gesture_and_show $dev" \
				"Edit gesture configration for device:$(input_device_event_dev $dev)"
    fi
  done
  for mod in ${!mods[@]}; do
    register_item_and_description "init_module_param_and_show $mod" \
		  "Tuning kernel module: ($mod) params for devices:${mods[$mod]}"
  done
  register_item_and_description "test_input_device" \
      "Test deviceis with evtest"
}

input_show_help() {
  echo "Tuning your input device driver and edit the gesture configuration file to smooth the input."
}
