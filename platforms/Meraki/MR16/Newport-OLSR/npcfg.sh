#!/bin/ash
# This is the auto-configuration script for Newport Mesh's MR16
# Updated for OpenWrt SNAPSHOT r6726-fdf2e1f, to be migrated to 18.05 when released.  FIXME

# © 2018 Meta Mesh Wireless Communities. All rights reserved. FIXME
# Licensed under the terms of the MIT license. FIXME
#
# AUTHORS
# * Justin Goetz
# * Adam Longwill
# * Evie Vanderveer
# * Martin Kenedy

# Update where OpenWRT pulls updates from. - AWAITING NEW RELEASE BEFORE MIRRORING ON OUR SERVER
# TODO
# Relink the following to another mirror for mr16 ...?
#rm /etc/opkg/distfeeds.conf
#echo src/gz chaos_calmer_base http://openwrt.metamesh.org/a150/openwrt/ar71xx/clean/1.0/packages/base>> /etc/opkg.conf
#echo src/gz chaos_calmer_luci http://openwrt.metamesh.org/a150/openwrt/ar71xx/clean/1.0/packages/luci>> /etc/opkg.conf
#echo src/gz chaos_calmer_management http://openwrt.metamesh.org/a150/openwrt/ar71xx/clean/1.0/packages/management>> /etc/opkg.conf
#echo src/gz chaos_calmer_packages http://openwrt.metamesh.org/a150/openwrt/ar71xx/clean/1.0/packages/packages>> /etc/opkg.conf
#echo src/gz chaos_calmer_routing http://openwrt.metamesh.org/a150/openwrt/ar71xx/clean/1.0/packages/routing>> /etc/opkg.conf
#echo src/gz chaos_calmer_telephony http://openwrt.metamesh.org/a150/openwrt/ar71xx/clean/1.0/packages/telephony>> /etc/opkg.conf
#echo src/gz pittmesh http://openwrt.metamesh.org/pittmesh>> /etc/opkg.conf

cat <<'EOF' > /tmp/mm-mac2ipv4.sh
#!/bin/sh

#
# © 2016 Meta Mesh Wireless Communities. All rights reserved.
# Licensed under the terms of the MIT license.
#
# AUTHORS
# * Jason Khanlar
#

# Check for --list-all, otherwise proceed

    while getopts ":-:" opt; do
	if [ $OPTARG = "list-all" ]; then
            mac1=DC
            mac2=9F
            mac3=DB
            mac4=00
            mac5=00
            mac6=00
	
            ip1=100
            ip2=64
            ip3=0
            ip4=0

            for octet in `seq 0 255`;do
		ip2=$(expr $octet % 32 + 96)
		
		mac4=$(printf "%02X\n" $ip2)
		
		# Format IP address
		ip="$ip1.$ip2.$ip3.$ip4"
		
		# Format MAC address
		mac="$mac1:$mac2:$mac3:$mac4:$mac5:$mac6"
		
		# Pad with space
		space=`printf '%*s' "$((15 - ${#ip}))"`
		
		# Output matching IP address and MAC address
		echo "$ip $space=> $mac"
            done
	    
            exit
	fi
    done

    # Proceed if not --list-all

    # Get # of arguments passed to this script
    args=$#

    # # of arguments should be 1 or 6
    # 1 -> DC:9F:DB:CE:13:57 -or- DC-9F-DB-CE-13-57
    # 6 -> DC 9F DB CE 13 57

    if [ $args -eq 1 -a ${#1} -eq 17 ]; then
	# Split 1 argument into 6 separate arguments, 1 for each octet
	# and pass the 6 arguments to a new instance of this script
	$0 `echo $1 | tr ":-" " "`
	# After the new instance completes, make sure to end this one
	exit
    elif [ $args -eq 6 ]; then
	mac1=$(echo $1|tr '[a-z]' '[A-Z]')
	mac2=$(echo $2|tr '[a-z]' '[A-Z]')
	mac3=$(echo $3|tr '[a-z]' '[A-Z]')
	mac4=$(echo $4|tr '[a-z]' '[A-Z]')
	mac5=$(echo $5|tr '[a-z]' '[A-Z]')
	mac6=$(echo $6|tr '[a-z]' '[A-Z]')
    else
	echo "Usage: $0 <MAC address>"
	echo "Usage: $0 --list-all"
	echo
	echo "examples:"
	echo "  $0 DC:9F:DB:CE:13:57"
	echo "  $0 DC-9F-DB-CE-13-57"
	echo "  $0 DC 9F DB CE 13 57"
	echo "  $0 dc 9f db ce 13 57"
	exit 1
    fi

    # Ensure nothing
    
    # Convert last three hexadecimal octets to decimal values
    ip1=100
    ip2=$(printf "%d" "0x$mac4")
    ip3=$(printf "%d" "0x$mac5")
    ip4=$(printf "%d" "0x$mac6")
    
    ip2=$(expr $ip2 % 32 + 96)
    ip4=$(expr $ip4 - $(expr $ip4 % 64 - $ip4 % 32))
    
    echo "$ip1.$ip2.$ip3.$ip4"
EOF

uci set dhcp.lan.ignore='1'
uci commit dhcp

uci set network.lan.proto='dhcp'
uci delete network.lan.ipaddr
uci commit network

/etc/init.d/network reload

# . ./lib.NewportMeshConfigCustom.sh
opkg update # || die "Could not run opkg update";

# New packages based on this article:
# https://justingoetz.net/display/PB/2019/04/10/Comprehensive+guide+to+running+OLSR+over+WPA2+on+OpenWRT

opkg remove iw --force-depends
opkg install iw-full
opkg remove wpad-mini

opkg install luci-app-olsr luci-app-olsr-services luci-app-olsr-viz olsrd \
     olsrd-mod-arprefresh olsrd-mod-bmf olsrd-mod-dot-draw olsrd-mod-dyn-gw \
     olsrd-mod-dyn-gw-plain olsrd-mod-httpinfo olsrd-mod-mdns \
     olsrd-mod-nameservice olsrd-mod-p2pd olsrd-mod-pgraph olsrd-mod-secure \
     olsrd-mod-txtinfo olsrd-mod-watchdog olsrd-mod-quagga wireless-tools \
     luci-lib-json kmod-ipip wpad authsae iperf3

# Set Hostname
uci set system.@system[0].hostname=mr16-STRING-2401

# Disable the RFC1918 filter in the webserver which would prevent you from accessing 100. mesh nodes.
uci set uhttpd.main.rfc1918_filter=0; uci commit uhttpd

# Restart uhttpd webserver and it will generate a new 1024 bit key.
/etc/init.d/uhttpd restart

# Disable ipv6 dhcp requests because we don't use them and they cause noise.
# We use them @ 12-22North testbed, I think -MIK
# /etc/init.d/odhcpd disable

# Set the timeserver to a node host on Mount Oliver who has a stratum 0 time server and set logs to go to Meta Mesh.
uci set system.@system[0].timezone=EST5EDT,M3.2.0,M11.1.0
uci set system.@system[0].zonename="America/New York"
uci set system.ntp=timeserver
uci set system.ntp.enabled=1
uci set system.ntp.enable_server=1

uci commit system

# Forward all DNS requests to a public DNS server.
uci set dhcp.@dnsmasq[0].server=1.1.1.1
uci commit dhcp

# Download the mm-mac2ipv4 conversion to convert your MAC address to IP's so that you can be sure they are unique on the mesh.
#wget https://raw.githubusercontent.com/pittmesh/ip-calculator/master/mm-mac2ipv4.sh
chmod +x /tmp/mm-mac2ipv4.sh

ipMESH=$(/tmp/mm-mac2ipv4.sh $(cat /sys/class/net/eth0/address));
ipLAN=$(echo "10.$(echo $ipMESH|cut -d "." -f 3-4).1");
ipHNA=$(echo "10.$(echo $ipMESH|cut -d "." -f 3-4).0");
ipETHERMESH=100.$(expr $(echo $ipMESH|cut -d "." -f 4) % 64 + 64).$(echo $ipMESH|cut -d "." -f 3).$(echo $ipMESH|cut -d "." -f 2)

# Set up interfaces and use the mm-mac2ipv4 script's conversions as IP addresses.
uci set network.mesh=interface
uci set network.mesh.proto=static
uci set network.mesh.ipaddr=`echo $ipMESH` # Why `echo`?
uci set network.mesh.netmask=255.192.0.0

#Set up ethermesh interface
uci set network.ethermesh=interface
uci set network.ethermesh.proto=static
uci set network.ethermesh.ifname=eth0
uci set network.ethermesh.netmask=255.192.0.0
uci set network.ethermesh.ipaddr=$ipETHERMESH

# Note: because we originally wrote the script for another device, we're calling the wlan variable. on ar150's the wlan and lan are bridged.
uci set network.lan=interface
uci set network.lan.proto=static
uci set network.lan.ipaddr=`echo $ipLAN`
uci set network.lan.netmask=255.255.255.0
uci set network.lan._orig_ifname=eth0
uci set network.lan._orig_bridge=true
uci set network.lan.force_link=1
uci set network.lan.bridge=1
uci commit network

# Set DHCP server to give out leases over the bridged wlan and lan interface for 1 hour from 10-253 and force it.
uci delete dhcp.lan.ignore
uci set dhcp.lan.start=10
uci set dhcp.lan.limit=253
uci set dhcp.lan.leasetime=1h
uci set dhcp.lan.force=1
uci commit dhcp

# Set up the WiFi. Please change the SSID to PittMesh-youraddress-2401 for the first device, PittMesh-youraddress-2402 for the second device and so on. Max TX rate for the ar150 is 18dBm.
uci delete wireless.radio0.disabled
uci set wireless.radio0.country=US
NEWVIF=`uci add wireless wifi-iface`
uci rename wireless.$NEWVIF=backhaul2g
uci set wireless.backhaul2g.device=radio0
uci set wireless.backhaul2g.encryption=psk2+aes
uci set wireless.backhaul2g.key='testkeys'
uci set wireless.backhaul2g.ssid=PittMesh-Backhaul
uci set wireless.backhaul2g.mode=adhoc
uci set wireless.backhaul2g.network=mesh
uci set wireless.@wifi-iface[0].network='lan'
uci set wireless.@wifi-iface[0].ssid=PittMesh-MR16-2401
uci set wireless.@wifi-iface[0].disabled=0

uci delete wireless.radio1.disabled
uci set wireless.radio1.country=US
uci set wireless.radio1.txpower='22'
uci set wireless.radio1.htmode='HT40'
NEWVIF=`uci add wireless wifi-iface`
uci rename wireless.$NEWVIF=backhaul5g
uci set wireless.backhaul5g.device=radio1
uci set wireless.backhaul5g.encryption=psk2+aes
uci set wireless.backhaul5g.key='testkeys'
uci set wireless.backhaul5g.ssid=PittMesh-Backhaul
uci set wireless.backhaul5g.mode=adhoc
uci set wireless.backhaul5g.network=mesh
uci set wireless.@wifi-iface[1].network='lan'
uci set wireless.@wifi-iface[1].ssid=PittMesh-MR16-5180
uci set wireless.@wifi-iface[1].disabled=0
uci commit wireless

# Set HNA announcements for the LAN and Internet
NEWOLSR=`uci add olsrd Hna4`
uci rename olsrd.$NEWOLSR=localnet
uci set olsrd.localnet.netaddr=`echo $ipHNA`
uci set olsrd.localnet.netmask=255.255.255.0

NEWOLSR=`uci add olsrd Hna4`
uci rename olsrd.$NEWOLSR=gateway
uci set olsrd.gateway.netaddr=0.0.0.0
uci set olsrd.gateway.netmask=0.0.0.0
uci rename olsrd.@Interface[0]='if0'
uci set olsrd.@Interface[0].ignore=0
uci set olsrd.@Interface[0].Mode=mesh
uci set olsrd.@Interface[0].interface='mesh'

NEWOLSRDEFAULT=`uci add olsrd InterfaceDefaults`
uci rename olsrd.$NEWOLSRDEFAULT='if0mode'
uci set olsrd.if0mode.Mode=mesh

NEWOLSRIF=`uci add olsrd Interface`
uci rename olsrd.$NEWOLSRIF='if1'
uci set olsrd.if1.ignore=0
uci set olsrd.if1.Mode=ether
uci set olsrd.if1.interface=ethermesh
uci set olsrd.@olsrd[0].LinkQualityAlgorithm=etx_ffeth

# Enable olsrd plugins
echo "config LoadPlugin" >> /etc/config/olsrd
echo "    option library olsrd_mdns.so.1.0.1" >> /etc/config/olsrd
pluginNum=$(uci show|grep olsrd.@LoadPlugin|grep olsrd_mdns.so.1.0.1|sed "s|.*\[\([0-9]*\)\].*|\1|")
uci set olsrd.@LoadPlugin[$pluginNum].ignore=0

# You need jsoninfo for this
echo "config LoadPlugin" >> /etc/config/olsrd
echo "    option library olsrd_jsoninfo.so.1.1" >> /etc/config/olsrd
pluginNum=$(uci show|grep olsrd.@LoadPlugin|grep olsrd_jsoninfo.so.1.1|sed "s|.*\[\([0-9]*\)\].*|\1|")
uci set olsrd.@LoadPlugin[$pluginNum].ignore=0

uci commit olsrd

# Set iptables rules to allow forwarding between interfaces.
uci set firewall.@defaults[0].forward=ACCEPT
uci set firewall.@zone[1].input=ACCEPT
uci set firewall.@zone[1].forward=ACCEPT
uci add firewall zone
uci set firewall.@zone[2].input=ACCEPT
uci set firewall.@zone[2].forward=ACCEPT
uci set firewall.@zone[2].output=ACCEPT
uci set firewall.@zone[2].name=mesh
uci set firewall.@zone[2].network='ethermesh mesh'
uci add firewall forwarding
uci set firewall.@forwarding[1].dest=mesh
uci set firewall.@forwarding[1].src=lan
uci add firewall forwarding
uci set firewall.@forwarding[2].dest=lan
uci set firewall.@forwarding[2].src=mesh
uci add firewall forwarding
uci set firewall.@forwarding[3].dest=wan
uci set firewall.@forwarding[3].src=mesh
uci add firewall forwarding
uci set firewall.@forwarding[4].dest=lan
uci set firewall.@forwarding[4].src=wan
uci add firewall forwarding
uci set firewall.@forwarding[5].dest=mesh
uci set firewall.@forwarding[5].src=wan
uci commit firewall

reboot
