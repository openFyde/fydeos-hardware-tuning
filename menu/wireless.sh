#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

import_libs bus_pci_scan module_param wireless_util connection

list_wireless_pci_info() {
  echo "System wireless pci devices list:"
  for slot in $(get_slots_by_pci_type "wireless"); do
    pci_device_info $slot
  done  
}

list_wlan_info() {
  echo "System current wlan device:"
  for wlan in $(list_current_wireless_devices); do
    printf "$wlan\tdriver:$(get_wireless_device_module $wlan)\t\
      status:$(get_wireless_device_status $wlan)\tip:$(get_wireless_device_ip4 $wlan)\n"
  done
}

show_connection_panel() {
  local dev="$1"
  set_current_wlan $dev
  register_console connection
}

wireless_list_info() {
  list_wireless_pci_info
  list_wlan_info
}

wireless_show_menu() {
  wireless_list_info
  print_line "*"
  local msgfilter="\"wireless"
  for slot in $(get_slots_by_pci_type "wireless"); do
    for mod in $(get_device_kernel_modules $slot); do
       msgfilter+="\|$mod"
      register_item_and_description "init_module_param_and_show $mod" \
        "Tuning kernel module: ($mod) params."
      register_block_or_unblock_item $mod
    done
  done
  for wlan in $(list_current_wireless_devices); do
    if ! is_pcibus_wireless_device $wlan; then
      local mod=$(get_wireless_device_module $wlan)
      register_item_and_description "init_module_param_and_show $mod" \
        "Tuning kernel module: ($mod) params."
      register_block_or_unblock_item $mod
      msgfilter+="\|$mod"
    fi
    register_item_and_description "show_connection_panel $wlan" \
      "Connecting network with device:$wlan"
  done

}

wireless_show_help() {
  echo "wireless device/driver/connection utils all in one"  
}
