#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

import_libs bus_pci_scan kernel_module_util module_param

list_sound_pci_info() {
  echo "System sound device list:"
  for slot in $(get_slots_by_pci_types "audio" "media"); do
    pci_device_info $slot
  done
}

sound_list_info() {
  list_sound_pci_info
}

sound_show_menu() {
  sound_list_info
  print_line "*"
  local msgfilter="\"alsa"
  for slot in $(get_slots_by_pci_types "audio" "media"); do
    for mod in $(get_device_kernel_modules $slot); do
      msgfilter+="\|$mod"
      register_item_and_description "init_module_param_and_show $mod" \
        "Tuning kernel module: ($mod) params."
      register_block_or_unblock_item $mod
    done
  done
  msgfilter+="\""
  register_item_and_description "sudo dmesg | grep -i $msgfilter |grep -i err" \
    "Search kernel message for sound driver error"
}

sound_show_help() {
  echo "If one sound device is supported by two drivers such as hda_intel_* and soc_intel_*.\
     System may pick the wrong one to load. You may try to block the in-use module to load the other one."
  WarnMsg "If you block the wrong driver, your PC will be muted."
}
