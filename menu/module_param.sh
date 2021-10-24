#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import_lib grub_commandline

declare -g _CURRENT_MODULE=""

set_current_module() {
    _CURRENT_MODULE=$1
    DbMsg "set module:$1"
}

modify_param_value() {
  local param="$1"
  local val
  read -p "Input $param value and press ENTER, no value will remove it from configration:" val
  val=$(echo $val|xargs)
  if [ -n "$val" ]; then
    save_command "set_module_parameter $_CURRENT_MODULE.$param=$val" "Set module:$_CURRENT_MODULE parameter:$param value:$val"
  else
		save_command "unset_module_parameter $_CURRENT_MODULE.$param" "Unset module:$_CURRENT_MODULE parameter:$param"
  fi 
}

test_param_value() {
  local param="$1"
  local val
  read -p "Input $param value and press ENTER, an empty value will reload module with default parameter:" val
  val=$(echo $val|xargs)
  sudo rmmod $_CURRENT_MODULE
  if [ -z "$val" ]; then
		sudo modprobe $_CURRENT_MODULE
  else
    sudo modprobe $_CURRENT_MODULE "$param=$val"
  fi
}

force_modify_param() {
  local val
  read -p "Input [param] or [param=value] to write parameter to kernel driver configration; [-param] to remove it from configration(\"[]\" is not needed):" val
  val=$(echo $val|xargs)
  if [ -z "$val" ]; then
    WarnMsg "Input empty string, Nothing changed."
	elif [ ${val:0:1} == "-" ]; then
		save_command "unset_module_parameter $_CURRENT_MODULE.${val:1}" "Unset module:$_CURRENT_MODULE parameter:${val:1}"
  else
    save_command "set_module_parameter $_CURRENT_MODULE.$val" "Set module:$_CURRENT_MODULE parameter:$val"
  fi
}

module_param_show_menu() {
  local p1 param detail value
  local nomodule=true
  local isblocked=false
  is_blocked_in_system $_CURRENT_MODULE && isblocked=true
  printf "Module:[ ${_WHITE}$_CURRENT_MODULE${_NC} ]\n"
  while IFS=":" read -s p1 param detail; do
    param=$(echo $param | xargs)
    if [ -z "$param" ];then
      break
    fi
    nomodule=false
		$isblocked || printf	" ${_WHITE}$param${_NC}:$(sudo cat /sys/module/$_CURRENT_MODULE/parameters/$param)\n"
    printf "$detail\n"
    register_item_and_description "modify_param_value $param" \
			"Modify $param in system configuration"
    if ! $isblocked ; then
      register_item_and_description "test_param_value $param" \
			  "Reload kernel module with new $param but not changing system configuration" 
    fi
    print_line "."
  done <<< $(sudo modinfo $_CURRENT_MODULE 2>/dev/null|grep parm)
  if $nomodule; then
    WarnMsg "No module or the module have no parameters. The driver maybe compiled in kernel, you can still change it"
    register_item_and_description "force_modify_param" \
			"input \$param=value to set system configuration"
  fi
}

module_param_show_help() {
  echo "None ensure it's safe for modifying kernel driver parameters, be caution."
}

init_module_param_and_show() {
  local module=$1
  set_current_module $module
  register_console module_param
}
