#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

declare -Ag _DMI_CRITICAL_TITLES=(
    [bios]="BIOS Information"
    [system]="System Information"
    [memory]="Memory Device"
    )
get_dmi_info() {
  local tag=$1
  local begin=false
  while read -s line; do
    if [[ "$line" =~ "${_DMI_CRITICAL_TITLES[$tag]}" ]]; then
      begin=true
      continue
    elif [[ -z "$line" ]]; then
      begin=false
      continue
    fi
    if $begin; then
      echo $line | xargs
    fi
  done <<< $(sudo dmidecode -t $tag)
}

get_bios_info() {
  get_dmi_info bios 2>/dev/null | grep -i "bios\|uefi" --color=never
}

get_system_info() {
  get_dmi_info system | grep -v "UUID\|Serial\ Number"
}

get_memory_info() {
  get_dmi_info memory |grep "Size\|Bank" --color=never
}

show_dmi_info() {
  printf "${_WHITE}[\tSYSTEM INFORMATION\t]${_NC}\n" 
  get_system_info
  echo ""
  printf "${_WHITE}[\tBIOS INFORMATION\t]${_NC}\n" 
  get_bios_info 
  echo ""
  printf "${_WHITE}[\tMEMORY INFORMATION\t]${_NC}\n"
  get_memory_info 
}
