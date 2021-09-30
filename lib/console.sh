#!/bin/bash
# Copyright 2021 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Author: Yang Tsao<yang@fydeos.io>

declare -g _APP_NAME="Default App Name"
declare -ag _APP_VERSION=( 1 0 0 )
declare -ag _CONSOLE_STACK
# the index numbers are hotkeys and the command include function name and parameters
declare -ag _NUMERICAL_HOTKEYS
declare -ag _SAVED_COMMANDS
declare -ag _SAVED_COMMANDS_DESCRIPTION
declare -Ag _LETTER_HOTKEYS=(
  [b]=go_back
  [r]=go_root
  [h]=show_help
  [x]=exit_without_save
  [e]=exit_with_save
  [c]=show_command_list
  [d]=remove_latest_saved_command
  [m]=show_menu
)

show_hotkey() {
  local key=$1
  local key_len=${#key}
  local msg="$(echo $2|sed 's/_/ /g')"
  local i
  for i in `seq 0 $((${#msg} -1))`; do
    if [ "${msg:$i:$key_len}" == "$key" ]; then
      printf "($_WHITE$key$_NC)${msg:$((i+1))}"
      break
    else
      printf "${msg:$i:1}"
    fi
  done
}

show_hotkeys() {
  for key in ${!_LETTER_HOTKEYS[@]}; do
    show_hotkey $key ${_LETTER_HOTKEYS[$key]}
    printf ' | '
  done
  echo
  printf "Screen Control: [${_YELLOW}Shift-PgUp${_NC}]Scroll up | [${_YELLOW}Shift-PgDn${_NC}]Scroll down\n"
}

print_line() {
  local chr=${1:-"*"}
  printf "${chr}"'%.0s' $(eval "echo {1..$(tput cols)}")
}

apply_console_func() {
  local funcname=$1
  declare -fp ${_CONSOLE_STACK[-1]}_console_$funcname 2>/dev/null 1>/dev/null
  if [ $? -eq 0 ]; then
    ${_CONSOLE_STACK[-1]}_console_$funcname
  fi
}

apply_console_out() {
  apply_console_func "out"
}

apply_console_in() {
  apply_console_func "in"
}

apply_console_exit() {
  while [ ${#_CONSOLE_STACK[@]} -gt 0 ]; do
    apply_console_func "exit"
    unset _CONSOLE_STACK[-1]
  done
}

go_back() {
  if [ ${#_CONSOLE_STACK[@]} -gt 1 ]; then
    apply_console_out
    unset _CONSOLE_STACK[-1]
  fi
  show_menu
}

go_root() {
  apply_console_out
  _CONSOLE_STACK=( ${_CONSOLE_STACK[0]} )
  show_menu
}

show_path() {
  local vpath
  printf "Path: "
  for vpath in ${_CONSOLE_STACK[@]}; do
    printf "$_BG_GREEN$vpath$_NC>" 
  done
  printf "\n"
}

show_menu() {
  _NUMERICAL_HOTKEYS=() 
  $DEBUG_MODE || clear
  printf "\t\t$_WHITE$_APP_NAME$_NC\t\tVersion:$_GREEN${_APP_VERSION[0]}.${_APP_VERSION[1]}.${_APP_VERSION[2]}$_NC\n"
  print_line
  ${_CONSOLE_STACK[-1]}_show_menu 
  show_path
  listen_user_input
}

show_help() {
  ${_CONSOLE_STACK[-1]}_show_help
}

exit_without_save() {
  apply_console_exit
  exit 0
}

exit_with_save() {
  echo "Run commands:"
  for exe in "${_SAVED_COMMANDS[@]}"; do
    $exe
    if [ $? -eq 0 ]; then
      OkMsg "$exe"
    else
      WarnMsg "$exe"
    fi
  done
  apply_console_out
  apply_console_exit
  exit 0
}

show_command_list() {
  echo "Saved command list:"
  for index in ${!_SAVED_COMMANDS_DESCRIPTION[@]}; do
    echo $index "${_SAVED_COMMANDS_DESCRIPTION[$index]}"
  done
  echo "End command list"
}

remove_latest_saved_command() {
  unset _SAVED_COMMANDS[-1]   
  unset _SAVED_COMMANDS_DESCRIPTION[-1]
  show_command_list
}

save_command() {
  local cmd="$1"
  local cmd_dec="$2"
  _SAVED_COMMANDS+=( "$1" )
  _SAVED_COMMANDS_DESCRIPTION+=(" $2 ")
  show_command_list
}

listen_user_input() {
  local hotkey="h"
  print_line "="
  show_hotkeys
  while read -p "Input hotkey or index number of menu:" hotkey; do
    echo
    hotkey=${hotkey:-zz}
    if [ -n "${_LETTER_HOTKEYS[$hotkey]}" ]; then
      ${_LETTER_HOTKEYS[$hotkey]}
    elif [ -n "${_NUMERICAL_HOTKEYS[$hotkey]}" ]; then
      DbMsg "${_NUMERICAL_HOTKEYS[$hotkey]}"
      eval "${_NUMERICAL_HOTKEYS[$hotkey]}"
    else
      WarnMsg "Hotkey/Index:$hotkey isn't exist"
    fi
    print_line "="
    show_hotkeys
  done
}

register_console() {
  local vpath=$1
  _CONSOLE_STACK+=( "$vpath" )
  apply_console_in
  show_menu
}

set_appname() {
  _APP_NAME=${1:-$_APP_NAME}
}

set_appversion() {
  _APP_VERSION=( $@ )
}

_register_numerical_hotkey() {
  _NUMERICAL_HOTKEYS+=( "$1" )
}

_show_item() {
  printf  "($_WHITE${#_NUMERICAL_HOTKEYS[@]}$_NC) $@ \n"
}

_get_numerical_hotkey_index() {
  echo  ${#_NUMERICAL_HOTKEYS[@]}
}

register_item_and_description() {
  local cmd="$1"
  local item_description="$2"
  _show_item "$item_description"
  _register_numerical_hotkey "$cmd"  
}
