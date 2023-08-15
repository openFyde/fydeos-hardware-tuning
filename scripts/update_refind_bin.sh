#!/usr/bin/env bash

set -o errexit

declare -r EFI_PARTTYPE="c12a7328-f81f-11d2-ba4b-00a0c93ec93b"
declare -r FYDEOS_DUALLBOOT_FINGERPRINT=".fydeos_dualboot"
declare -r SUBDIR_IN_EFI="EFI"
declare -r REFIND_DIR_IN_EFI="refind"
declare -r REFIND_BAK_FILE="refind.backup.tar.gz"

declare USER_INTERACTION="true"

fatal() {
  log "$@"
  exit 1
}

log() {
  echo "$@" >&2
}

assert_fydeos_refind() {
  local dir="$1"
  local subdirs=("fydeos" "$REFIND_DIR_IN_EFI")
  for subdir in "${subdirs[@]}"; do
    if [[ ! -d "${dir}/${SUBDIR_IN_EFI}/${subdir}" ]]; then
      log "Missing ${dir}/${SUBDIR_IN_EFI}/${subdir}"
      return 1
    fi
  done

  if [[ ! -f "${dir}/${SUBDIR_IN_EFI}/${REFIND_DIR_IN_EFI}/${FYDEOS_DUALLBOOT_FINGERPRINT}" ]]; then
    log "No ${FYDEOS_DUALLBOOT_FINGERPRINT} file found"
    return 1
  fi

  return 0
}

backup_refind() {
  local dir="$1"
  local bak_file="${dir}/${SUBDIR_IN_EFI}/${REFIND_BAK_FILE}"
  if [[ -f "$bak_file" ]]; then
    log "Backup file $bak_file already exists, skip backup"
    return
  fi
  local source="${dir}/${SUBDIR_IN_EFI}/"
  tar czf "$bak_file" -C "$source" "${REFIND_DIR_IN_EFI}" || { return 1; }
  log "Backup rEFInd to $bak_file"
}

extract_refind() {
  local file="$1"
  local temp_dir="$2"
  tar xf "$file" -C "${temp_dir}"
  if [[ ! -d "${temp_dir}/${REFIND_DIR_IN_EFI}" ]]; then
    log "Unexpected, no refind directory found in $file"
    return 1
  fi
  log "Extracted rEFInd file ${file} to ${temp_dir}/${REFIND_DIR_IN_EFI}"
}

get_refind_version_in_dir() {
  local dir="$1"
  local version_file="$dir/.version"
  if [[ -f "$version_file" ]]; then
    cat "$version_file"
  else
    echo "0.0.0"
  fi
}

copy_refind() {
  local action="$1"
  local dir="$2"
  local refind_file="$3"

  local temp_dir_to_extract=""
  temp_dir_to_extract=$(mktemp -d -p /tmp -t update_fydeos_refind.XXXXXX)
  extract_refind "$refind_file" "$temp_dir_to_extract" || { log "Failed to extract rEFInd" ; return 1; }
  local temp_refind_dir="${temp_dir_to_extract}/${REFIND_DIR_IN_EFI}"
  local target="${dir}/${SUBDIR_IN_EFI}/"
  local v1=""
  local v2=""
  v1=$(get_refind_version_in_dir "$temp_refind_dir")
  v2=$(get_refind_version_in_dir "${target}${REFIND_DIR_IN_EFI}")
  if [[ "$v1" = "$v2" ]]; then
    log "rEFInd version is equal, skip copying"
    return 1
  fi
  if [[ "$action" = "update" ]]; then
    backup_refind "$dir" || { log "Failed to backup rEFInd in $part"; return 1; }
  fi

  if [[ ! -f "$temp_refind_dir/.version" ]]; then
    echo "0.0.0" > "$temp_refind_dir/.version"
  fi

  cp -fr "$temp_refind_dir" "$target"
  log "Copied rEFInd, ${target}${REFIND_DIR_IN_EFI}($v2) was replaced by ${temp_refind_dir}($v1)"
}

user_continue() {
  if [[ "$USER_INTERACTION" = "false" ]]; then
    return 0
  fi
  while true; do
    read -p "Do you want to continue? (Y/Yes/yes/N/No/no): " -r answer < /dev/tty

    if [[ $answer == "Y" || $answer == "Yes" || $answer == "yes" ]] || [[ "$answer" == "y" ]]; then
      return 0
    elif [[ $answer == "N" || $answer == "No" || $answer == "no" ]] || [[ "$answer" == "n" ]]; then
      return 1
    else
      echo "Please enter Y/Yes/yes or N/No/no"
    fi
  done
}

umount_partition() {
  local part="$1"
  local dir="$2"
  if [[ -d "$dir" ]]; then
    umount "$dir" > /dev/null 2>&1 || log "Failed to unmount $dir"
  fi
}

update_refind_after_mounted() {
  local part="$1"
  local dir="$2"
  local file="$3"
  log "Preparing to update rEFInd in $part"
  if ! user_continue; then
    log "Skip updating rEFInd in $part"
    return 1
  fi
  copy_refind "update" "$dir" "$file" || { log "Failed to update rEFInd in $part"; return 1; }
}

restore_refind_after_mounted() {
  local part="$1"
  local dir="$2"
  log "Preparing to restore rEFInd in $part"
  if ! user_continue; then
    log "Skip restoring rEFInd in $part"
    return 1
  fi
  local backup_file="${dir}/${SUBDIR_IN_EFI}/${REFIND_BAK_FILE}"
  if [[ ! -f "$backup_file" ]]; then
    log "No backup rEFInd file for $part"
    return 1
  fi
  copy_refind "restore" "$dir" "$backup_file" || { log "Failed to restore rEFInd in $part"; return 1; }
}

update_refind_in_partition() {
  local action="$1"
  local part="$2"
  local file="$3"
  local temp_efi_mountpoint="/tmp/efi"

  log "Mounting $part to $temp_efi_mountpoint"
  mkdir -p "$temp_efi_mountpoint"
  umount "$temp_efi_mountpoint" > /dev/null 2>&1 || true
  mount -o rw "$part" "$temp_efi_mountpoint" || { log "Failed to mount $part to $temp_efi_mountpoint"; return 1; }

  assert_fydeos_refind "$temp_efi_mountpoint" || { log "Not a FydeOS rEFInd partition: $part"; return 1; }

  local ret=0
  if [[ "$action" = "update" ]]; then
    if update_refind_after_mounted "$part" "$temp_efi_mountpoint" "$file"; then
      log "Successfully updated rEFInd in $part"
    else
      ret=1
    fi
  elif [[ "$action" = "restore" ]]; then
    if restore_refind_after_mounted "$part" "$temp_efi_mountpoint"; then
      log "Successfully restored rEFInd in $part"
    else
      ret=1
    fi
  fi

  log "Unmounting $part from $temp_efi_mountpoint"
  umount "$temp_efi_mountpoint" || log "Failed to unmount $temp_efi_mountpoint"
  return $ret
}

usage() {
  echo "Usage: $0 [-f refind_file] [-r] [-y]"
  echo "  -f refind_file: the rEFInd file to update"
  echo "  -r: restore rEFInd, -f is ignored"
  echo "  -y: assume yes"
  exit 1
}

main() {
  local refind_file=""
  local action=""
  if [[ -t 1 ]]; then
    USER_INTERACTION="true"
  else
    log "Not running in a terminal, no user interaction"
    USER_INTERACTION="false"
  fi
  while getopts "f:ry" opt; do
    case "$opt" in
      f)
        refind_file="$OPTARG"
        action="update"
        ;;
      r)
        refind_file=""
        action="restore"
        ;;
      y)
        USER_INTERACTION="false"
        ;;
      *)
        usage
        ;;
    esac
  done

  if [[ -z "$action" ]]; then
    usage
  fi

  if [[ ! -f "$refind_file" ]] && [[ "$action" = "update" ]]; then
    fatal "rEFInd file not found: $refind_file"
  fi

  local success=0
  while read -r efi_partition; do
    if [[ "$efi_partition" = "/dev/loop"* ]]; then
      continue
    fi
    if update_refind_in_partition "$action" "$efi_partition" "$refind_file"; then
      success=$((success + 1))
    fi
  done < <(lsblk -l -J -p -o name,type,ro,parttype,rm,mountpoint,tran,subsystems \
            | jq -r ".blockdevices[] | select(.parttype == \"${EFI_PARTTYPE}\") | .name")

  if [[ $success -gt 0 ]]; then
    log "Done, reboot to see the changes"
  else
    log "No rEFInd partition changed"
  fi
}

main "$@"
