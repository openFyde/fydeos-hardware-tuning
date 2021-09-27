#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>
declare -g SYS_CLASS_NET_PATH="/sys/class/net"
declare -g _CURRENT_WLAN=""

list_current_wireless_devices() {
  pushd $SYS_CLASS_NET_PATH >/dev/null
  ls -d wlan* 2>/dev/null
  popd >/dev/null
}

is_pcibus_wireless_device() {
  local dev=${1:-$_CURRENT_WLAN}
  local module=$(udevadm info -q property $SYS_CLASS_NET_PATH/$dev |grep ID_BUS)
  [ "${module#*=}" == "pci" ]
}

set_current_wlan() {
  if [ -e "$SYS_CLASS_NET_PATH/$1" ]; then
    _CURRENT_WLAN=$1
  fi
  if [ -z "$_CURRENT_WLAN" ]; then
     _CURRENT_WLAN=$(list_current_wireless_devices | head -n1)
  fi
  if [ -z "$_CURRENT_WLAN" ]; then
    ErrMsg "No wireless interfece found like wlan0 etc."
  fi
}

wpa_cli_run() {
  local cmd="$1"
  local dev=${2:-$_CURRENT_WLAN}
  sudo runuser -u wpa -- wpa_cli -i $dev $cmd
}

get_wireless_device_module() {
  local dev=${1:-$_CURRENT_WLAN}
  local module=$(udevadm info -q property $SYS_CLASS_NET_PATH/$dev | grep ID_NET_DRIVER)
  echo ${module#*=}
}

get_wireless_device_status() {
  local dev=${1:-$_CURRENT_WLAN}
  local status=$(wpa_cli_run status $dev | grep wpa_state)
  echo ${status#wpa_state=}
}

get_wireless_device_ip4() {
  local dev=${1:-$_CURRENT_WLAN}
  local status=$(wpa_cli_run status $dev | grep ip_address)
  echo ${status#ip_address=}
}

scan_wirless_networks() {
  local dev=${1:-$_CURRENT_WLAN}
  wpa_cli_run scan $dev
}

scan_result_ssid_from_device() {
  local dev=${1:-$_CURRENT_WLAN}
  while read d1 d2 d3 d4 d5; do
    echo $d5
  done <<< $(wpa_cli_run scan_result $dev | tail -n +2)
 }

list_dev_networks() {
  local dev=${1:-$_CURRENT_WLAN}
  wpa_cli_run list_networks $dev | tail -n +2
}

number_of_networks() {
  local dev=${1:-$_CURRENT_WLAN}
  while read d1 d2; do
    echo $d1
  done <<< $(list_dev_networks | wc)
}

connect_ssid_from_dev() {
  local ssid="$1"
  local psk="$2"
  local dev=${3:-$_CURRENT_WLAN}
  local network_id=$(wpa_cli_run "add_network" $dev)
  wpa_cli_run "set_network $network_id ssid \"$ssid\"" $dev
  wpa_cli_run "set_network $network_id psk \"$psk\"" $dev
  wpa_cli_run "select_network $network_id" $dev
}
