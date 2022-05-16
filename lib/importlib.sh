#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

declare -a _LIB_IMPORTED
declare -g DEBUG_MODE=false

if [ ${#_LIB_IMPORTED} -ne 0 ]; then
  return
fi

ErrMsg() {
  printf "\033[0;31mERROR:\033[0m $@\n"  >&2
}

WarnMsg() {
  printf "\033[1;33mWARNING:\033[0m $@\n" >&2
}

OkMsg() {
  printf "\033[0;32mOK:\033[0m $@\n" >&2
}

DbMsg() {
 $DEBUG_MODE && caller
 $DEBUG_MODE && printf "\033[1;33mDEBUG:\033[0m $@\n" >&2
}

get_current_dir() {
  local relative_path=$(dirname ${BASH_SOURCE[0]})
  if [ -n "$relative_path" ]; then
    pushd $(dirname ${BASH_SOURCE[0]}) 2>&1 1>/dev/null
    pwd
    popd 2>&1 1>/dev/null
  else
    pwd
  fi
}

_LIB_ROOT=$(get_current_dir)

find_lib_source() {
  local libname=$1
  find $_LIB_ROOT/../ -name $libname.sh | head -n1
}

is_lib_imported() {
  local libname=$1
  local in_list=0
  for lib in "${_LIB_IMPORTED[@]}"; do
    if [ ${libname} == $lib ];then
      in_list=1
      break
    fi
  done
  [ $in_list -eq 1 ]
}

register_lib() {
  local lib_name=$1
  _LIB_IMPORTED[${#_LIB_IMPORTED[@]}]=$lib_name 
}

import_lib() {
  local libname=$1
  if is_lib_imported $libname; then
    #WarnMsg "lib:$libname is already loaded"
    return
  fi
  local libsource=$(find_lib_source $1)
  if [ -z "$libsource" ]; then
    ErrMsg "can't find lib:$libname"
    return
  fi
  source $libsource
  register_lib $libname
  #OkMsg "import $libname"
}

import_libs() {
  for libname in $@; do
    import_lib $libname
  done
}

register_lib importlib
