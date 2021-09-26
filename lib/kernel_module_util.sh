#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

import_lib console grub_commandline

list_kernel_module_params() {
  local module=$1
  local p1 param detail value
  local -i index=0
  printf "Module:[ ${_WHITE}$module${_NC} ]\n"
  while IFS=":" read -s p1 param detail; do
    param=$(echo $param | xargs)
    if [ -z "$param" ];then
      break
    fi
    printf "($((index++))) ${_WHITE}$param${_NC}: $(sudo cat /sys/module/$module/parameters/$param)\n"
    printf "$detail\n"
  done <<< $(sudo modinfo $module 2>/dev/null|grep parm)
}

block_module_command() {
  local mod=$1
  save_command "block_module $mod" "Block driver:$mod to prevent the driver to be used by system."
  WarnMsg "The blocking command was saved temporarily, you can revoke it by remove latest saved command."
}

unblock_module_command() {
  local mod=$1
  save_command "unblock_module $mod" "Unblock driver:$mod to prevent the driver to be used by system."
  WarnMsg "The unblocking command was saved temporarily, you can revoke it by remove latest saved command."
}

register_block_or_unblock_item() {
  local mod=$1
  if is_blocked_module $mod; then
    register_item_and_description "unblock_module_command $mod" \
      "Unblock kernel driver/module: ($mod)." 
  else
    register_item_and_description "block_module_command $mod" \
      "Block kernel driver/module: ($mod)."
  fi
}
