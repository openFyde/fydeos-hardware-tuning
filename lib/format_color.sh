#!/bin/base
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

if [[ ! "$COLOR" = "false" ]]; then
  declare -g _GREEN='\033[0;32m'
  declare -g _RED='\033[0;31m'
  declare -g _YELLOW='\033[1;33m'
  declare -g  _NC='\033[0m'
  declare -g _WHITE="\033[1;37m"
  declare -g _BG_GREEN="\e[48;5;28m${_WHITE}"
  declare -g _BG_RED="\e[48;5;124m${_WHITE}"
  declare -g _BG_YELLOW="\e[48;5;208m${_WHITE}"
fi
