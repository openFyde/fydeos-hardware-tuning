#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

is_idarray() {
  [[ "$(declare -p $1 2>&1)" =~ "declare -a" ]] 
}

is_assarray() {
  [[ "$(declare -p $1 2>&1)" =~ "declare -A" ]]
}

idarray_to_json() {
  local -n arr=$1
  local jsonstr="["
  local val
  for val in ${arr[@]}; do
    jsonstr+=\"$val\"\,
  done
  echo "${jsonstr%,}]"
}

assarray_to_json() {
  local -n assarr=$1
  local jsonstr="{"
  local name
  for name in "${!assarr[@]}"; do
    jsonstr+=\""$name"\"\:\"${assarr["$name"]}\"\,
  done
  echo "${jsonstr%,}}"
}

clear_array() {
  if is_idarray $1;then
    unset $1
    declare -ga $1
  elif is_assarray $1;then
    unset $1
    declare -gA $1
  fi
}
