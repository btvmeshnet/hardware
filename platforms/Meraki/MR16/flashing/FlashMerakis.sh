#!/bin/bash

IMG_DIR="openwrt/mr16"

if [[ "$(whoami)" != "root" ]]  ; then
    echo "You must be root to run this."
    exit 1;
fi

mkdir -p ./logs

tail -n 0 -f /var/log/kern.log \
    | grep 'converter now attached to tty' --line-buffered \
    | sed -u 's/.*converter now attached to \([^ ]*\).*/\/dev\/\1/' \
    | ( while read CONSOLE ; do

            mac_and_ip="$(/usr/bin/zenity --forms --title="Flash Meraki MR16" --text="Serial port detected on $CONSOLE" --add-entry="Set Meraki MAC address to: " --add-entry="Set Meraki IP to: " 2>/dev/null)"

            [[ "$?" -ne "0" ]] && continue

            MERAKI_MAC="$(echo "$mac_and_ip" | sed 's/|.*//')"
            IP_ADDR="$(echo "$mac_and_ip" | sed 's/.*|//')"

            export CONSOLE MERAKI_MAC IP_ADDR IMG_DIR
            nohup ./flash-MR16.pl -o logs/$MERAKI_MAC.nohup.out &

        done )
