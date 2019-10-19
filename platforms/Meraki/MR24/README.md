
# MR24
Working on MR24 (3x3 bgn + 3x3 abgn, APM82121)

## PCIe speculation
On 30 Aug 2018, `91.13.120.222` added [a comment](https://wikidevi.com/w/index.php?title=Cisco_Meraki_MR24&diff=162611&oldid=149198) to the WikiDevi article for the MR24. They noted that the mPCIe slots on the MR24 were non-standard, saying simply:

> The two minipcie ports are non-standard as only the supplied Wi-Fi cards will work in them.

With only superficial knowledge of how device initialization works in OpenWrt, it may appear this is correct. For example, see [this post entitlted *PCI-E External Storage methods?*](https://forum.openwrt.org/t/pci-e-external-storage-methods/41351). This person wanted to add storage to their router, but unfortunately no PCI IDs even came up that correspond to a USB 3.0 or SATA controller via PCIe ( `[168c:0030]` is one of the Atheros WLAN cards, and `[111d:8039]` is the [IDT PCIe switch](https://html.alldatasheet.com/html-pdf/198622/IDT/89HPES3T3/56/1/89HPES3T3.html) [^hint-pci-ids]. The solver of that thread goes on to say that it is likely not initializing because:

> The PCIe bus on some Atheros chips is not a full implementation. It only has the functionality required to support wifi cards.

... but as this board contains no Atheros-based PCI hosts, this is impossible! Indeed, other boards like the Netgear WNDR4700 [^tech-renasas] have other PCI devices that they can use despite having nearly identical hardware.

With some knowledge it's clear that in order for the devices to show up, the [device tree has to be populated](https://openwrt.org/docs/guide-developer/defining-firmware-partitions) in order to bring things up correctly after the kernel loads.

U-boot, which this router runs on, has a few ways of demonstrating that it knows about and is working on devices:

- It allows you to manipulate them before boot using some u-boot commands (see e.g. [this mailing list entry](https://lists.denx.de/pipermail/u-boot/2009-March/048565.html))

- It actually lists out PCI device IDs (as vendor:product pairs) at boot-time -- see how it shows up in the [MR24 u-boot log](https://openwrt.org/toh/meraki/mr24) and in the [WNDR4700 u-boot log](https://openwrt.org/toh/netgear/wndr4700). (The WNDR4700 is mentioned as it has a very similar processor, same architecture, a very similar PCI switch AND processor, but additionally has the ubiquitous Renasas PCI to USB 3.0 chip [^tech-renasas].)

[^tech-renasas]: http://en.techinfodepot.shoutwiki.com/wiki/Netgear_WNDR4700

[^hint-pci-ids]: Search through `/usr/share/misc/pci.ids` (most Linux machines have this) to identify devices.
