#!/bin/bash

#IMG_DIR="openwrt/mr16"
IMG_DIR=""

SCRIPT_DIR=/home/labby/Desktop/MeshHardware/hardware/platforms/Meraki/MR16/flashing/

cd SCRIPT_DIR

if test "x`id -u`" != "x0"; then
        #
        #  If there is no configured SU program run gpartedbin as
        #  non-root to display the graphical error about needing root
        #  privileges.
        #
        if test "xpkexec --disable-internal-agent" = "x"; then
                echo "Root privileges are required for running gparted."
                $BASE_CMD
                exit 1
        fi

        #
        # Interim workaround to allow GParted run by root access to the
        # X11 display server under Wayland.  If configured with
        # './configure --enable-xhost-root', the xhost command is
        # available and root has not been granted access to the X11
        # display via xhost, then grant access.
        #
        ENABLE_XHOST_ROOT=no
        GRANTED_XHOST_ROOT=no
        if test "x$ENABLE_XHOST_ROOT" = 'xyes' && xhost 1> /dev/null 2>&1; then
                if ! xhost | grep -qi 'SI:localuser:root$'; then
                        xhost +SI:localuser:root
                        GRANTED_XHOST_ROOT=yes
                fi
        fi

        #
        # Run gparted as root.
        #
        pkexec --disable-internal-agent '/home/labby/Desktop/FlashMerakis.sh' "$@"
        status=$?

        #
        # Revoke root access to the X11 display, only if we granted it.
        #
        if test "x$GRANTED_XHOST_ROOT" = 'xyes'; then
                xhost -SI:localuser:root
        fi
        exit $status
fi

if [[ "$EUID" != "0" ]]  ; then
    echo "You must be root to run this."
    exit 1;
fi

if [[ -f "/home/labby/Desktop/flashmr.pid" ]] ; then
	sudo kill `cat /home/labby/Desktop/flashmr.pid`
	sudo rm /home/labby/Desktop/flashmr.pid
	sudo pkill flash-MR16
	exit
fi

echo "$$" > /home/labby/Desktop/flashmr.pid

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
