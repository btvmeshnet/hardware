# Headers for Raspbian
note `apt-get install linux-headers` no longer works

```
apt-get update
apt-get upgrade
reboot
apt-get update
apt-get install raspberrypi-kernel-headers

```

# Headers for Armbian

```
apt-get update
apt-get upgrade
reboot
apt-get install linux-headers-next-sunxi
```

# ulli-kroll driver

*Note* On orange pi the network manager seems to crash when using this driver.  Disable with network-manager.

```
git clone https://github.com/ulli-kroll/mt7610u.git
cd mt7610u
make ARCH=arm
make installfw
insmod mt7610u.ko
```


Patch to compile
```
diff --git a/include/rtmp.h b/include/rtmp.h
index 6ddf855..a3f1907 100644
--- a/include/rtmp.h
+++ b/include/rtmp.h
@@ -5719,7 +5719,7 @@ typedef struct __attribute__ ((packed)) _ieee80211_radiotap_header {
                                         */
 }ieee80211_radiotap_header ;
 
-enum ieee80211_radiotap_type {
+/* enum ieee80211_radiotap_type {
     IEEE80211_RADIOTAP_TSFT = 0,
     IEEE80211_RADIOTAP_FLAGS = 1,
     IEEE80211_RADIOTAP_RATE = 2,
@@ -5735,7 +5735,7 @@ enum ieee80211_radiotap_type {
     IEEE80211_RADIOTAP_DB_ANTSIGNAL = 12,
     IEEE80211_RADIOTAP_DB_ANTNOISE = 13
 };
-
+*/
 #define WLAN_RADIOTAP_PRESENT (                        \
        (1 << IEEE80211_RADIOTAP_TSFT)  |       \
        (1 << IEEE80211_RADIOTAP_FLAGS) |       \
```
