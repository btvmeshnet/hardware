#!/usr/bin/perl -w
use Expect;
use Time::HiRes;

my $timeout = 5;

my $img_dir = ($ENV{'TFTP_IMG_DIR'}) ? $ENV{'TFTP_IMG_DIR'} : "";
my $ip_addr = ($ENV{'IP_ADDR'}) ? $ENV{'IP_ADDR'} : "192.168.1.2";
my $console = ($ENV{'CONSOLE'}) ? $ENV{'CONSOLE'} : "/dev/ttyUSB0";
my $meraki_mac = ($ENV{'MERAKI_MAC'}) ? $ENV{'MERAKI_MAC'} : "00:18:0a:12:34:56";
$meraki_mac = lc($meraki_mac);

my $patidx;

# create an Expect object by spawning another process
my $exp = Expect->spawn("/usr/bin/microcom", "--port", "$console", "--speed", "115200")
    or die "Cannot spawn $command: $!\n";

&getPrompt;

&carefullySend("setenv ipaddr $ip_addr;");
$patidx = $exp->expect(1, "ar7100> ");
die "Failed to set ip addr" if (!$patidx);

Time::HiRes::sleep(1.0);
&carefullySend("tftpboot 0x80010000 ${img_dir}openwrt-18.06.2-ar71xx-generic-mr16-squashfs-kernel.bin;");
$patidx = $exp->expect(10, "ar7100> ");

Time::HiRes::sleep(1.0);
&carefullySend("erase 0xbfda0000 +0x240000;");
$patidx = $exp->expect(30, "ar7100> ");

Time::HiRes::sleep(1.0);
&carefullySend("cp.b 0x80010000 0xbfda0000 0x240000;");
$patidx = $exp->expect(30, "ar7100> ");

Time::HiRes::sleep(1.0);
&carefullySend("tftpboot 0x80010000 ${img_dir}openwrt-18.06.2-ar71xx-generic-mr16-squashfs-rootfs.bin;");
$patidx = $exp->expect(10, "ar7100> ");

Time::HiRes::sleep(1.0);
&carefullySend("erase 0xbf080000 +0xD20000;");
$patidx = $exp->expect(120, "ar7100> ");

Time::HiRes::sleep(1.0);
&carefullySend("cp.b 0x80010000 0xbf080000 0xD20000;");
$patidx = $exp->expect(120, "ar7100> ");

Time::HiRes::sleep(1.0);
&carefullySend("setenv bootcmd bootm 0xbfda0000;");
$patidx = $exp->expect($timeout, "ar7100> ");

Time::HiRes::sleep(1.0);
&carefullySend("saveenv;");
$patidx = $exp->expect($timeout, "ar7100> ");

Time::HiRes::sleep(1.0);
&carefullySend("boot;");
$patidx = $exp->expect(120, "Please press Enter to activate this console.");
die "Failed to achieve console" if (!$patidx);

Time::HiRes::sleep(1.0);
$hasConsole = '';
while (!$hasConsole) {
  $exp->send("\n");
  $patidx = $exp->expect($timeout, 'root@OpenWrt:/# ');
  $hasConsole = $patidx;
}

Time::HiRes::sleep(1.0);
&carefullySend("mtd erase mac");
$patidx = $exp->expect($timeout, 'root@OpenWrt:/# ');

Time::HiRes::sleep(1.0);
my $echo_mac = $meraki_mac;
$echo_mac =~ s/^/\\x/;
$echo_mac =~ s/:/\\x/g;
&carefullySend("echo -n -e '$echo_mac' > /dev/mtd5");
$patidx = $exp->expect($timeout, 'root@OpenWrt:/# ');


Time::HiRes::sleep(15.0);
&carefullySend("sync && reboot");

$exp->soft_close();
exit;

sub carefullySend {
  my $string = shift;
  my $typed_right = '';
  while (!$typed_right) {
    $exp->send("\cC");
    Time::HiRes::sleep(0.3);
    $exp->send("$string");
    $typed_right = $exp->expect(1, "$string");
  }
  $exp->send("\n");
}

sub getPrompt {
  my $has_console = 0;
  while (!$has_console) {
    $exp->send("\n");
    $has_console = $exp->expect(0, "ar7100> ");
    Time::HiRes::sleep(0.3);
  }
}
