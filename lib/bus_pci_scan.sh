#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

import_lib format_color array_util

declare -Ag _PCI_DEVICES
declare -r -Ag _CRITICAL_DEVICE_CLASS=(
  ["graphic"]="VGA compatible controller"
  ["display"]="Display controller"
  ["usb"]="USB controller"
  ["sata"]="SATA controller"
  ["audio"]="Audio device"
  ["ethernet"]="Ethernet controller"
  ["nvme"]="Non-Volatile memory controller"
  ["wireless"]="Network controller"
  ["serial"]="Serial bus controller [0c80]"
  ["media"]="Multimedia controller"
)

declare -rg _KERNEL_DRIVER_IN_USE="Kernel driver in use: "
declare -rg _KERNEL_MODULES="Kernel modules: "

init_pci_bus_devices() {
  clear_array _PCI_DEVICES
  local d1 d2 d3
  while IFS="\"" read -s d1 d2 d3; do
    _PCI_DEVICES["$d2"]+="$d1"
  done <<< $(sudo lspci -m) 
}

pci_device_info() {
  local slot=$1
  sudo lspci -s $slot -k
  if device_driver_module_conflict $slot; then
    WarnMsg "Potential conflict: $(get_device_kernel_modules $slot) "
  fi
}

get_device_driver_name() {
  local device_slot=$1
  local name=$(sudo lspci -k -s $device_slot | grep "$_KERNEL_DRIVER_IN_USE")
  echo ${name#*$_KERNEL_DRIVER_IN_USE}
}

get_device_kernel_modules() {
  local device_slot=$1
  local name=$(eval "sudo lspci -k -s $device_slot | grep \"$_KERNEL_MODULES\"")
  echo ${name#*$_KERNEL_MODULES} | sed 's/,//g' 
}

get_slots_by_pci_type() {
  local type="$1"
  echo ${_PCI_DEVICES["${_CRITICAL_DEVICE_CLASS[$type]}"]}
}

get_slots_by_pci_types() {
  local slots=""
  for type in $@; do
    slots+="${_PCI_DEVICES["${_CRITICAL_DEVICE_CLASS[$type]}"]} "
  done
  echo $slots
}

device_driver_installed() {
  local device_slot=$1
  [ -n "$(get_device_driver_name $device_slot)" ]  
}

device_driver_module_conflict() {
  local device_slot=$1
  local modules=($(get_device_kernel_modules $device_slot))
  [ ${#modules[@]} -gt 1 ]  
}

scan_device_problem() {
  local index=$1
  local type="$2"
  local device_slot=$3
  local problem=""
  if ! device_driver_installed $device_slot; then 
    problem="${_RED}NO DRIVER INSTALLED${_NC}"
  else
    if device_driver_module_conflict $device_slot; then
      problem="${_YELLOW}DRIVERS CONFLECT${_NC}: $(get_device_kernel_modules $device_slot)"
    fi
  fi
  printf "[$index] $type:$device_slot "
  if [ -z "$problem" ]; then
    printf "${_GREEN}DRIVER LOADED${_NC}\n"
  else
    printf "${problem}\n"
  fi
}

scan_critical_devices_problem() {
  local -a handle_slots
  local type slot slots
  for type in "${_CRITICAL_DEVICE_CLASS[@]}"; do
    slots="${_PCI_DEVICES["$type"]}"
    if [ -n "$slots" ]; then
      for slot in $slots; do
        handle_slots+=($slot)
        scan_device_problem $((${#handle_slots[@]} - 1)) "$type" $slot
      done
    fi
  done
  echo ${handle_slots[@]}
}

scan_all_devices_problem() {
  local -a handle_slots
  local type slot slots
  for type in "${!_PCI_DEVICES[@]}"; do
    slots="${_PCI_DEVICES["$type"]}"
    if [ -n "$slots" ]; then
      for slot in $slots; do
        handle_slots+=($slot)
        scan_device_problem $((${#handle_slots[@]} - 1)) "$type" $slot
      done
    fi
  done
  echo ${handle_slots[@]}
}

