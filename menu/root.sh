#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

import_libs dmi_util bus_pci_scan
import_libs graphic sound wireless input kernel_module
import_libs misc

show_kernel_params_console() {
  local module
  read -p "You have to input the module name:" module
  module=$(echo $module | xargs)
  if [ -n "$module" ]; then
    set_current_module $module
    register_console kernel_params
  else
    WarnMsg "none module name input."
  fi
}

root_show_menu() {
  show_dmi_info
  init_pci_bus_devices
  print_line "*" 
  register_item_and_description "register_console graphic" \
      "Diagnose graphic hardware and driver tuning"
  register_item_and_description "register_console sound" \
      "Diagnose sound hardware and driver tuning"
  register_item_and_description "register_console wireless" \
      "Diagnose wireless hardware and driver tuning"
  register_item_and_description "register_console input" \
      "Diagnose input devices and driver tuning"
  if misc_menu_supported; then
    register_item_and_description "register_console misc" \
        "Misc devices and driver tuning"
  fi
  register_item_and_description "show_kernel_params_console" \
      "Edit kernel params manually"
}

display_header() {
  printf "${_WHITE}[\t${1}\t]${_NC}\n"
}

root_display_all() {
  show_dmi_info
  init_pci_bus_devices
  echo ""

  display_header "WIRELESS INFORMATION"
  wireless_list_info
  echo ""

  display_header "SOUND INFORMATION"
  sound_list_info
  echo ""

  display_header "GESTURE INFORMATION"
  gesture_list_info
  echo ""

  display_header "GRAPHIC INFORMATION"
  graphic_list_info
  echo ""

  display_header "MISC INFORMATION"
  echo ""
  list_misc_info
  echo ""
}

root_show_help() {
  echo "Basic menu for hardware tuning"
  WarnMsg "If you have no idea of what you are doing, close this app immediately. Or it may damage your hardware. **Expert Only**"
}

root_console_exit() {
  release_grub_mnt
}
