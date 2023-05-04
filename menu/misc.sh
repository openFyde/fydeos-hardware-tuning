#!/usr/bin/env bash

import_libs suspend_mode

ls_pci()
{
    sudo lspci -nn
}

ls_usb()
{
    sudo lsusb
}

ls_hid()
{
    sudo dmesg | grep -i "hid"
}

show_dmesg()
{
    sudo dmesg --level=err,warn
}

ip_addrs()
{
    ip addr
}

list_misc_info()
{
    display_header "HID DEVICES"
    ls_hid
    echo ""

    display_header "PCI DEVICES"
    ls_pci
    echo ""

    display_header "USB DEVICES"
    ls_usb
    echo ""

    display_header "DMESG WARN/ERROR"
    show_dmesg | grep -v audit
    echo ""

    display_header "IP ADDRESSES"
    ip_addrs
    echo ""
}


misc_show_menu() {
  register_item_and_description "init_suspend_mode_and_show" \
    "Switch suspend mode"
}

misc_menu_supported() {
  is_setting_suspend_mode_support
}
