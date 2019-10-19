Information about the Meraki MR16 dual-band wireless router

# Information

## Wireless
[This paper](https://conferences.sigcomm.org/sigcomm/2015/pdf/papers/p153.pdf) confirms that the radios are AR9220 and AR9223. It appears that in many ways, the MR16 is similar to the [MR66](https://wikid
evi.com/wiki/Meraki_MR66) without antennas. 

TXPower appears to be limited by the EEPROM chip(s) under the shield. This could be removed.

### Tasks
- [x] Determine what is limiting the txpower
  - It is the EEPROM. The wireless chipsets are probably both AR9220 and are both limited by the EEPROM's programming.
- [ ] Pop open the RF shield (following [this guide](https://www.evaluationengineering.com/applications/emc-emi-rfi/article/13002990/removable-shielding-technologies-for-pcbs)
- [ ] Locate EEPROM chips under the shield
- [ ] Flush the content of EEPROM

### EEPROM
ar9287_eeprom

#### Flashing
Check out some resources:
- https://forums.kali.org/showthread.php?28874-ALFA-AWUS036NHA-hacking-EEPROM-via-UART-JTAG

## Images

### Tasks
- [ ] Document images

### Tasks
- [ ] Take closeup images of the MR16
  - This will help us figure out what pinouts might be available for extensibility.

# Resources

## Flashing

- [OpenWrt link where OP is trying to flash the MR16.](https://forum.archive.openwrt.org/viewtopic.php?id=71884)

# Modifications

## USB

Would like to find USB headers on the board of the device. It uses an AR7161, which has two USB MAC/PHYs according to [the datasheet](https://github.com/Deoptim/atheros/blob/master/AR7100_nowatermark.pdf).

- This will not be easy. The AR7161 is a BGA, and while [the datasheet](https://github.com/Deoptim/atheros/blob/master/AR7100_nowatermark.pdf) shows the USB PHY headers as being right on the edge of the BGA package, the USB appears to require an external 12MHz crystal clock to run.
- It's not impossible to attach said signal, and if we can do it reliably, we can offload some operations to an external device with a much stronger processor (like an Orange Pi Zero).

