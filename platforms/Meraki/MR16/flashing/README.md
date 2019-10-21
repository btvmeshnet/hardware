# Flashing the MR16

The scripts in this directory require:
- Perl5
- `libexpect-perl`
- `microcom`
- `zenity`
- `tftpd-hpa` to be setup
  - basically:
    ```
    apt-get install tftpd-hpa
    cd /var/lib/tftpboot/
    wget https://downloads.openwrt.org/releases/18.06.2/targets/ar71xx/generic/openwrt-18.06.2-ar71xx-generic-mr16-squashfs-kernel.bin
    wget https://downloads.openwrt.org/releases/18.06.2/targets/ar71xx/generic/openwrt-18.06.2-ar71xx-generic-mr16-squashfs-rootfs.bin
	ip link # ... and find your ethernet interface's name
    ifconfig $ETH_INTERFACE_NAME 192.168.1.101/24
    ```

## [`Flash-MR16.md`](./Flash-MR16.md`)
A guide for doing this manually.

## `FlashMerakis.sh`
Must be run as root. Checks kernel log for serial consoles, pulls up a Zenity window to let you fix things up, then calls `./flash-mr16.pl` to do its dirty work.

Note that it sets the `IMG_DIR` variable, which is the directory under the main `tftp` root directory from which files should be pulled. Note that you may want to change this.

## `flash-mr16.pl`
Interacts with the serial console in order to flash.

