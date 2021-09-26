#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

import_libs bus_pci_scan graphic_device kernel_module_util module_param

list_graphic_pci_info() {
  echo "System graphic device list:"
  for slot in $(get_slots_by_pci_type "graphic"); do
    pci_device_info $slot
  done
  WarnMsg "Suggestions from fydeos:"
  echo "Best compatiable devices:" ${_BEST_COMPATIABLE_GCARDS[@]}  
  echo "Basic compatiable devices:" ${_BASIC_COMPATIABLE_GCARDS[@]}
}

graphic_show_menu() {
  list_graphic_pci_info
  print_line "*"
  local IFS=','
  for slot in $(get_slots_by_pci_type "graphic"); do
    DbMsg "slot:$slot"
    for mod in $(get_device_kernel_modules $slot); do
      DbMsg "mod:$mod"
      register_item_and_description "init_module_param_and_show $mod" \
        "Tuning kernel module: ($mod) params."
      register_block_or_unblock_item $mod
    done 
  done
  register_item_and_description 'sudo dmesg | grep -i \"drm\|i915\|amdgpu\|nouveau\" |grep -i err' \
    "Search kernel message for graphic driver error"
}

graphic_show_help() {
  echo "FydeOS can only running on one graphic device at the moment. If there are two or more graphic devices in system,\
     Fydoos will pick one randomly. You need block the unused devices to make system stable."
  WarnMsg "If you blocked the wrong device, you may get black screen."
}
