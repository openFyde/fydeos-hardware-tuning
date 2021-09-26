#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

declare -ag _BASIC_COMPATIABLE_GCARDS=(
  "amdgpu"
  "nouveau"
)

declare -ag _BEST_COMPATIABLE_GCARDS=(
  "i915"
)

find_pci_vga_cards() {
  local slot tag tmpvar cards
  while read -s slot tag tmpvar; do
    if [ "$tag" == "VGA" ]; then
      cards+="$slot " 
    fi 
  done <<< $(sudo lspci)  
  echo $cards
}

list_vga_cards_detail() {
  for cards in $(find_pci_vga_cards); do
    sudo lspci -s $cards
  done
}
