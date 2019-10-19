# Hardware

This is a project to identify and document possible hardware opportunities and resources for the purpose of building community networks.

This project intends to consolidate many other repositories into one.

## Table of Contents

### `platforms/`

A list of complete hardware platforms to work with, organized by vendor and then product in subdirectories. Examples are Meraki MR16's, Raspberry Pi's and so on.

#### `meraki/`

Everything about modding / using Meraki cloud-managed APs (and other hardware).

### `adapters/`

A list of additional adapters, organized first under interface type (`usb/`, `mpcie/`, `ngff/`), and then common name, core chipset or driver standard name in subdirectories. See, for example, `adapters/usb/rtl8812au/README.md`.

#### `802.11s-adapters/`

A repository crammed under this one for cosolidation purposes by `git subtree add`ding it - see https://github.com/tomeshnet/802.11s-adapters; this is primarily the work of phillymesh and tomesh.
