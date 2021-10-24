#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

import_lib wireless_util

connection_info() {
  printf "[$_GREEN$_CURRENT_WLAN$_NC]\n"
  wpa_cli_run status
  print_line "*"
  echo "Scan result:"
  wpa_cli_run scan_result
}

wait_seconds() {
  for second in `seq $1`; do
    printf "\rPlease wait...$second s"
    sleep 1
  done
}

scanning_network() {
  scan_wirless_networks
  wait_seconds 5
  show_menu
}

connect_ssid() {
  local ssid="$1"
  local psk
  read -p "Input the password to connect to [$ssid] with $_CURRENT_WLAN:" psk
  connect_ssid_from_dev "$ssid" "$psk"
  wait_seconds 5
  show_menu
}

connection_show_menu() {
  connection_info
  print_line "*"
  register_item_and_description "scanning_network" "Scanning network with $_CURRENT_WLAN"
  for ssid in $(scan_result_ssid_from_device); do
    register_item_and_description "connect_ssid \"$ssid\"" "Connect to the network[$ssid]"
  done
}

connection_show_help() {
  echo "Help: scanning and connecting network, Press m to refresh menu panel." 
}
