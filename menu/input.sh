#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

import_libs input_util module_param gesture

list_serial_devices() {
  local mods
  echo "PCI serial devices:"
  for slot in $(get_slots_by_pci_type "serial"); do
    pci_device_info $slot
    mods=$(get_device_kernel_modules $slot)
    if [ -z "${mods}" ]; then
      WarnMsg "Your serial driver might be faild, try ${_YELLOW}Add flag nocrs${_NC} to fix it"
    fi
  done  
}

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

set_pci_nocrs() {
  save_command "set_module_parameter pci=nocrs" "Set PCI nocrs to fix some ACPI memory conflict which prevent intel-lpss from loading"
}

unset_pci_nocrs() {
  save_command "unset_module_parameter pci=nocrs" "Unset PCI nocrs to recovery system original config"
}

input_show_menu() {
  local dev_type mod dev_name edev
  local -A mods
  list_serial_devices
  print_line "."
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
  if [ -n "$(cat /proc/cmdline | grep 'pci=nocrs')" ];then
    register_item_and_description "unset_pci_nocrs" \
        "Remove flag nocrs"
  else
    register_item_and_description "set_pci_nocrs" \
        "Add flag nocrs to fix memory conflict"
  fi
}

input_show_help() {
  echo "Tuning your input device driver and edit the gesture configuration file to smooth the input."
}
