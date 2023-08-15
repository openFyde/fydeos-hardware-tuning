#!/bin/bash

init_update_refind_and_show() {
  register_console "update_refind"
}

UPDATE_REFIND_SCRIPT_BIN=""
UPDATE_REFIND_FILE=""

do_update_refind() {
  sh -c "$UPDATE_REFIND_SCRIPT_BIN -f $UPDATE_REFIND_FILE"
}

do_restore_refind() {
  sh -c "$UPDATE_REFIND_SCRIPT_BIN -r"
}

update_refind_show_menu() {
  local path=""
  path=$(dirname "${BASH_SOURCE[0]}")
  UPDATE_REFIND_SCRIPT_BIN="$path/../scripts/update_refind_bin.sh"
  UPDATE_REFIND_FILE="$path/../scripts/refind_fydeos_v17_0.14.1.tar.gz"
  if [[ -x "$UPDATE_REFIND_SCRIPT_BIN" ]] && [[ -f "$UPDATE_REFIND_FILE" ]]; then
    register_item_and_description "do_update_refind" "Update rEFInd to version 0.14.1"
    register_item_and_description "do_restore_refind" "Restore rEFInd"
  else
    WarnMsg "Can't find update_refind bin or refind_fydeos_v17_0.14.1.tar.gz"
  fi
}
