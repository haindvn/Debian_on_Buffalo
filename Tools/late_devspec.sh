##special stuff for devices with microcontroller
if [ "$(/source/micro-evtd -s 0003 | tail -n 1)" == "0" ]; then
	cp /source/micro-evtd /target/usr/local/bin/
	cp -r /source/micon_scripts "/target/usr/local/bin/"
	cp /source/micon_scripts/*.service /target/etc/systemd/system/
	chmod 755 /target/usr/local/bin/micon_scripts/*.py
fi

mkdir -p /target/etc/flash-kernel/dtbs/
mkdir -p /target/usr/share/flash-kernel/db/
cp /source/phytool /target/usr/local/bin/
cp /source/*.dtb /target/etc/flash-kernel/dtbs/
cp /source/*.db /target/usr/share/flash-kernel/db/
cp /source/in_target_finish.sh /target/tmp/

grep LS4 /proc/device-tree/model > /dev/null
is_ls400=$?
grep TS12 /proc/device-tree/model > /dev/null
is_ts1200=$?
grep VL /proc/device-tree/model > /dev/null
is_vseries=$?
grep XL /proc/device-tree/model > /dev/null
is_xseries=$?
if [ $is_ls400 -eq 0 ] || [ $is_ts1200 -eq 0 ] || [ $is_vseries -eq 0 ] || [ $is_xseries -eq 0 ]; then
      cp /source/phy_restart.sh /target/usr/local/bin/
fi

machine=`sed -n '/Hardware/ {s/^Hardware\s*:\s//;p}' /proc/cpuinfo`
case $machine in
	*"Device Tree)")
	machine=$(cat /proc/device-tree/model)
	;;
esac
case $machine in
	"Buffalo Linkstation Pro/Live" | "Buffalo/Revogear Kurobox Pro")
	echo "/dev/mtdblock1 0x00000 0x10000 0x10000" > /target/etc/fw_env.config ;;
	"Buffalo Terastation Pro II/Live")
	echo "/dev/mtdblock0 0x0003f000 0x1000 0x1000" > /target/etc/fw_env.config ;;
	"Buffalo Linkstation LS-WXL")
        echo "/dev/mtdblock2 0x00000 0x10000 0x10000" > /target/etc/fw_env.config ;;
	*)
	echo "/dev/mtdblock1 0x00000 0x10000 0x10000" > /target/etc/fw_env.config ;;
esac

if [ "$(busybox grep -c "Marvell Armada 370/XP" /proc/cpuinfo)" != "0" ]; then
    cp /source/ifup-mac.sh /target/usr/local/bin/
fi

chmod 755 /target/usr/local/bin/*.sh

mount -o bind /dev /target/dev

exit 0
