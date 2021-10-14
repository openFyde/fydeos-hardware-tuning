#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

declare -g _RO_MODULE_PARAMS="moduleparams="
declare -g _RO_MODULE_VAR="\$moduleparams"
declare -g _RO_BLACKLIST="module_blacklist"
declare -g GRUB_MNT="/tmp/grub_mnt"
declare -g CURRENT_GRUB_FILE
declare -g CURRENT_MODULE_PARAMS

get_module_params() {
  local grubfile=${1:-$CURRENT_GRUB_FILE}
  local module_params=$(cat $grubfile | grep $_RO_MODULE_PARAMS)
  module_params=${module_params#*=}
  echo ${module_params} | sed "s/\"//g"
}

# set module params value in gurb config file
save_module_params() {
  local grubfile=${1:-$CURRENT_GRUB_FILE}
  local module_params="${2:-$CURRENT_MODULE_PARAMS}"
  if [ ! -e $grubfile.orig ]; then
    sudo cp $grubfile $grubfile.orig
  fi
  if [ -n "$(cat $grubfile | grep $_RO_MODULE_PARAMS)" ]; then
    DbMsg "sed \"/$_RO_MODULE_PARAMS/  c $_RO_MODULE_PARAMS\\\"$module_params\\\"\"  $grubfile > $grubfile.new"
    sudo sh -c "sed \"/$_RO_MODULE_PARAMS/  c $_RO_MODULE_PARAMS\\\"$module_params\\\"\"  $grubfile > $grubfile.new"
  else
    sudo sh -c  "sed \"1 i $_RO_MODULE_PARAMS\\\"$module_params\\\"\" $grubfile > $grubfile.new"
  fi
  if [ -z "$(cat $grubfile.new | grep $_RO_MODULE_VAR)" ]; then
    sudo sed "s/ linux.*/& $_RO_MODULE_VAR/"  -i $grubfile.new 
  fi
  sudo mv $grubfile $grubfile.bak
  sudo mv $grubfile.new $grubfile
}

get_param_from_module_params() {
  local module_params="$1"
  local param="$2"
  for arg in $module_params; do
    if [ "${arg%=*}" == "$param" ]; then
      echo $arg
      break
    fi
  done
}

set_param_to_module_params() {
  local module_params="$1"
  local param="$2"
  local find_param=false
  local result=""
  for arg in $module_params; do
    arg=$(echo $arg| xargs)
    if [ -z "$arg" ];then
      continue
    fi
    if [ "${arg%=*}" == "${param%=*}" ]; then
      find_param=true
      result+="$param "
    else
      result+="$arg "
    fi
  done
  if ! $find_param; then
    result+="$param "
  fi
  echo ${result% }
}

unset_param_to_module_params() {
  local module_params="${1:-$CURRENT_MODULE_PARAMS}"
  local param="$2"
  local result=""
  for arg in $module_params; do
    if [ "${arg%=*}" != "${param%=*}" ]; then
      result+="$arg "
    fi
  done
  echo ${result% }
}

#get module blacklist in module flags
get_blacklist() {
  local module_params="${1:-$CURRENT_MODULE_PARAMS}"
  local blacklist=$(get_param_from_module_params "$module_params" $_RO_BLACKLIST)
  echo ${blacklist#*=}
}

set_blacklist() {
  local module_params="$1"
  local blacklist="$2"
  set_param_to_module_params "$module_params" "$_RO_BLACKLIST=$blacklist"
}

is_module_blocked() {
  local blacklist=$1
  local name=$2
  local find_name=false
  local IFS=","
  for module in $blacklist; do
    if [ "$name" == "$module" ]; then
      find_name=true
      break
    fi
  done
  IFS=""
  $find_name
}

set_blacklist_name() {
  local blacklist=$1
  local name=$2
  local find_name=false
  local result=""
  local IFS=","
  for module in $blacklist; do
    if [ "$name" == "$module" ]; then
      find_name=true
    fi
    result+="$module,"
  done
  IFS=""
  if $find_name; then
    echo ${result%,}
  else
    echo $result$name
  fi
}

unset_blacklist_name() {
  local blacklist=$1
  local name=$2
  local IFS=","
  local result=""
  for module in $blacklist; do
    if [ "$name" != "$module" ]; then
      result+="$module,"
    fi
  done
  IFS=""
  echo ${result%,}
}

#----- context support ------
init_grub_mnt() {
  [ -d $GRUB_MNT ] || mkdir $GRUB_MNT
  if [ -n "$(cat /proc/cmdline |grep fydeos_dualboot)" ]; then
    local dualboot_part=$(sudo cgpt find -l FYDEOS-DUAL-BOOT)
    dualboot_part=$(udevadm info -q path $dualboot_part)
    dualboot_part=$(dirname $dualboot_part)
    dualboot_part=$(basename $dualboot_part)
    dualboot_part=$(sudo cgpt find -t efi /dev/$dualboot_part | head -n1)
    sudo mount $dualboot_part $GRUB_MNT
    CURRENT_GRUB_FILE=$GRUB_MNT/efi/fydeos/grub.cfg
  else
    [ -n "$(sudo mount | grep $GRUB_MNT)" ] || \
      sudo mount $(ls $(rootdev -d){12,p12} 2>/dev/null) $GRUB_MNT
    CURRENT_GRUB_FILE=$GRUB_MNT/efi/boot/grub.cfg
  fi
  CURRENT_MODULE_PARAMS="$(get_module_params)"
  DbMsg CURRENT_MODULE_PARAMS:$CURRENT_MODULE_PARAMS
}

release_grub_mnt() {
  local params=$(get_module_params $CURRENT_GRUB_FILE)
  if [ "${CURRENT_MODULE_PARAMS}" != "$params" ]; then
    save_module_params "$CURRENT_GRUB_FILE" "$CURRENT_MODULE_PARAMS"
    WarnMsg "The kernel module configration is changed, reboot to apply the change."
  fi
  sudo umount $GRUB_MNT 
}

block_module() {
  local modname=$1
  local bl=$(get_blacklist "${CURRENT_MODULE_PARAMS}")
  bl=$(set_blacklist_name "$bl" "$modname")
  CURRENT_MODULE_PARAMS="$(set_blacklist "${CURRENT_MODULE_PARAMS}" "$bl")"
}

unblock_module() {
  local modname=$1
  local bl=$(unset_blacklist_name "$(get_blacklist "${CURRENT_MODULE_PARAMS}")" $modname)
  CURRENT_MODULE_PARAMS="$(set_blacklist "${CURRENT_MODULE_PARAMS}" "$bl")"
}

set_module_parameter() {
  local param="$1"
  CURRENT_MODULE_PARAMS="$(set_param_to_module_params "$CURRENT_MODULE_PARAMS" "$param")"
}

unset_module_parameter() {
  local param="$1"
  CURRENT_MODULE_PARAMS="$(unset_param_to_module_params "$CURRENT_MODULE_PARAMS" "$param")"
}

is_blocked_module() {
  local search_module="$1"
  local bl=$(get_blacklist "${CURRENT_MODULE_PARAMS}")
  is_module_blocked $bl $search_module
}
