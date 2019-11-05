#!/bin/bash

custom_kernel()
{
  apt-get -y remove $(dpkg -l | grep linux-image | gawk '{print $2}')
  apt-get install -y apt-transport-https gnupg
  wget -qO - https://raw.githubusercontent.com/1000001101000/Debian_on_Buffalo/master/PPA/KEY.gpg | apt-key add -
  echo "deb https://raw.githubusercontent.com/1000001101000/Debian_on_Buffalo/master/PPA/ $version main" > /etc/apt/sources.list.d/tsxl_kernel.list
  apt-get update
  apt-get install -y linux-image-$1
}

version="$(grep VERSION_CODENAME /etc/os-release | cut -d '=' -f 2)"

echo "BOOT=local" > /usr/share/initramfs-tools/conf.d/localboot
echo "MODULES=dep" > /etc/initramfs-tools/conf.d/modules
echo mtdblock >> /etc/modules
echo m25p80 >> /etc/modules

machine=`sed -n '/Hardware/ {s/^Hardware\s*:\s//;p}' /proc/cpuinfo`
case $machine in
        *"Device Tree)")
        machine=$(cat /proc/device-tree/model)
        ;;
esac

mount -t proc none /proc
mount -t sysfs none /sys

udevadm trigger

run_size="$(busybox df -m /run | busybox tail -n 1 | busybox awk '{print $2}')"

##increase /run if default is too low
if [ $run_size -lt 20 ]; then
  echo "tmpfs /run tmpfs nosuid,noexec,size=26M,nr_inodes=4096 0  0" >> /etc/fstab
  mount -o remount tmpfs
fi

if [ "$(busybox grep -c "Marvell Armada 370/XP" /proc/cpuinfo)" == "0" ]; then
   case $machine in
        "Buffalo Nas WXL")
	has_pci="$(lspci | wc -c)"
	if [ $has_pci -ne 0 ]; then
           custom_kernel tsxl
	else
	   custom_kernel tswxl
	fi
	;;
	"Buffalo Terastation Pro II/Live")
	if [ "$version" == "stretch" ]; then
	   apt-get install -y linux-image-marvell
	else
	   custom_kernel tsxl
	fi
	;;
        *)
        apt-get install -y linux-image-marvell;;
   esac
else
    ln -s /usr/local/bin/ifup-mac.sh /etc/network/if-pre-up.d/ifup_mac
fi

if [ "$(/usr/local/bin/micro-evtd -s 0003 | tail -n 1)" == "0" ]; then
	ln -s /usr/local/bin/micon_scripts/micon_shutdown.py /lib/systemd/system-shutdown/micon_shutdown.py

	systemctl enable micon_boot.service
	systemctl enable micon_fan_daemon.service

	##signal restart rather than shutdown
	/usr/local/bin/micro-evtd -s 013500,0003,000c,014618
fi

grep LS4 /proc/device-tree/model > /dev/null
is_ls400=$?
grep TS12 /proc/device-tree/model > /dev/null
is_ts1200=$?
grep VL /proc/device-tree/model > /dev/null
is_vseries=$?
grep XL /proc/device-tree/model > /dev/null
is_xseries=$?
if [ $is_ls400 -eq 0 ] || [ $is_ts1200 -eq 0 ] || [ $is_vseries -eq 0 ] || [ $is_xseries -eq 0 ]; then
      ln -s /usr/local/bin/phy_restart.sh /lib/systemd/system-shutdown/phy_restart.sh
fi

if [ "$machine" == "Buffalo Linkstation LS441D" ] || [ "$machine" == "Buffalo Linkstation LS-QVL" ]; then
   /usr/local/bin/phytool write eth0/0/22 3 && /usr/local/bin/phytool write eth0/0/16 0x0981
   /usr/local/bin/phytool write eth0/0/22 0
fi

apt-get install -y flash-kernel
echo "" | update-initramfs -u

exit 0
