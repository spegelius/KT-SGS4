#!/bin/sh

if [ "$MREV" == "" ]; then
    echo "No MREV defined, us kk or lp in build command"
    exit 1
fi

if [ "$EXTRAVER" != "" ]; then
    echo $EXTRAVER
    EXTRAVER="-$EXTRAVER"
fi

export PLATFORM="AOSP"
export CURDATE=`date "+%m.%d.%Y"`
export MUXEDNAMELONG="KT-SGS4-$MREV-$PLATFORM-$CARRIER$EXTRAVER-$CURDATE"
export MUXEDNAMESHRT="KT-SGS4-$MREV-$PLATFORM-$CARRIER*"
export KTVER="--$MUXEDNAMELONG--"
export KERNELDIR=`readlink -f .`
export PARENT_DIR=`readlink -f ..`
export INITRAMFS_DEST=$KERNELDIR/kernel/usr/initramfs
export INITRAMFS_SOURCE=`readlink -f ..`/Ramdisk
export INITRAMFS_BRANCH=$(echo $PLATFORM | awk '{print tolower($0)}')"-"$VERSION
export CONFIG_$PLATFORM_BUILD=y
export PACKAGEDIR=$PARENT_DIR/Packages/$PLATFORM

#Enable FIPS mode
export USE_SEC_FIPS_MODE=true
export ARCH=arm

# export CROSS_COMPILE=/home/ktoonsez/aokp4.2/prebuilts/gcc/linux-x86/arm/arm-eabi-4.6/bin/arm-eabi-
#export CROSS_COMPILE=$PARENT_DIR/linaro4.7/bin/arm-eabi-
#export CROSS_COMPILE=/media/storage/toolchain/linaro-4.7-12.10/bin/arm-linux-gnueabihf-
#export CROSS_COMPILE=/media/storage/toolchain/arm-linux-androideabi-4.8/bin/arm-linux-androideabi-
#export CROSS_COMPILE=/media/storage/toolchain/sabermod-arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
export CROSS_COMPILE=/media/storage/toolchain/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux/bin/arm-linux-gnueabihf-

pushd $INITRAMFS_SOURCE
git checkout $INITRAMFS_BRANCH
if [ ! $? -eq 0 ]; then
  exit 1
fi
popd

time_start=$(date +%s.%N)

echo "** Remove old Package Files"
rm -rf $PACKAGEDIR/*

echo "** Setup Package Directory"
mkdir -p $PACKAGEDIR/system/app
mkdir -p $PACKAGEDIR/system/lib/modules
mkdir -p $PACKAGEDIR/system/etc/init.d

echo "** Create initramfs dir"
mkdir -p $INITRAMFS_DEST

echo "** Remove old initramfs dir"
rm -rf $INITRAMFS_DEST/*

echo "** Copy new initramfs dir"
cp -R $INITRAMFS_SOURCE/* $INITRAMFS_DEST

echo "** chmod initramfs dir"
chmod -R g-w $INITRAMFS_DEST/*
rm $(find $INITRAMFS_DEST -name EMPTY_DIRECTORY -print)
rm -rf $(find $INITRAMFS_DEST -name .git -print)

echo "** Remove old zImage"
rm $PACKAGEDIR/zImage
rm arch/arm/boot/zImage

echo "** Board: $BOARD"
if [ -z $BOARD ]; then
    export BOARD="jf"
fi

echo "** Make the kernel"
make SELINUX_DEFCONFIG=jfselinux_defconfig SELINUX_LOG_DEFCONFIG=jfselinux_log_defconfig KT_${BOARD}_defconfig

echo "** Modding .config file - "$KTVER
sed -i 's,CONFIG_LOCALVERSION="-KT-SGS4",CONFIG_LOCALVERSION="'$KTVER'",' .config

HOST_CHECK=`uname -n`
if [ $HOST_CHECK = 'ktoonsez-VirtualBox' ] || [ $HOST_CHECK = 'task650-Underwear' ]; then
	echo "Ktoonsez/task650 24!"
	make -j24
else
	echo "Others! - " + $HOST_CHECK
	make -j`grep 'processor' /proc/cpuinfo | wc -l`
fi;

echo "** Copy modules to Package"
cp -a $(find . -name *.ko -print |grep -v initramfs) $PACKAGEDIR/system/lib/modules/
if [ $ADD_KTWEAKER = 'Y' ]; then
	cp $PARENT_DIR/ktapps/com.ktoonsez.KTweaker.apk $PACKAGEDIR/system/app/com.ktoonsez.KTweaker.apk
	cp $PARENT_DIR/ktapps/com.ktoonsez.KTmonitor.apk $PACKAGEDIR/system/app/com.ktoonsez.KTmonitor.apk
fi;

if [ -e $KERNELDIR/arch/arm/boot/zImage ]; then
	echo "** Copy zImage to Package"
	cp arch/arm/boot/zImage $PACKAGEDIR/zImage

	echo "** Make boot.img"
	./mkbootfs $INITRAMFS_DEST | gzip > $PACKAGEDIR/ramdisk.gz
	./mkbootimg --cmdline "$RD_CMDLINE" --kernel $PACKAGEDIR/zImage --ramdisk $PACKAGEDIR/ramdisk.gz --base 0x80200000 --pagesize 2048 --ramdisk_offset 0x02000000 --output $PACKAGEDIR/boot.img 
	#if [ $EXEC_LOKI = 'Y' ]; then
	#	echo "Executing loki"
	#	./loki_patch-linux-x86_64 boot aboot$CARRIER.img $PACKAGEDIR/boot.img $PACKAGEDIR/boot.lok
	#	rm $PACKAGEDIR/boot.img
	#fi;
	cd $PACKAGEDIR

	#if [ $EXEC_LOKI = 'Y' ]; then
	#	cp -R ../META-INF-SEC ./META-INF
	#else
		cp -R $PARENT_DIR/ktapps/META-INF .
	#fi;
	cp -R ../kernel .

	rm ramdisk.gz
	rm zImage
	rm ../$MUXEDNAMESHRT.zip*
	zip -r ../$MUXEDNAMELONG.zip .
	cd ..
        md5sum $MUXEDNAMELONG.zip > $MUXEDNAMELONG.zip.md5sum 

	time_end=$(date +%s.%N)
	echo -e "** ${BLDYLW}Total time elapsed: ${TCTCLR}${TXTGRN}$(echo "($time_end - $time_start) / 60"|bc ) ${TXTYLW}minutes${TXTGRN} ($(echo "$time_end - $time_start"|bc ) ${TXTYLW}seconds) ${TXTCLR}"

	#export DLNAME="http://ktoonsez.jonathanjsimon.com/sgs4/$PLATFORM/$MUXEDNAMELONG.zip"
	
	#FILENAME=../$MUXEDNAMELONG.zip
	#FILESIZE=$(stat -c%s "$FILENAME")
	#echo "Size of $FILENAME = $FILESIZE bytes."
	#rm ../$MREV-$PLATFORM-$CARRIER"-version.txt"
	#exec 1>>../$MREV-$PLATFORM-$CARRIER"-version.txt" 2>&1
	#echo -n "$MUXEDNAMELONG,$FILESIZE," & curl -s https://www.googleapis.com/urlshortener/v1/url --header 'Content-Type: application/json' --data "{'longUrl': '$DLNAME'}" | grep \"id\" | sed -e 's,^.*id": ",,' -e 's/",.*$//'
	#echo 1>&-
	
	#SHORTURL=$(grep "http" ../$MREV-$PLATFORM-$CARRIER"-version.txt" | sed s/$MUXEDNAMELONG,$FILESIZE,//g)
	#exec 1>>../url/aurlstats-$CURDATE.sh 2>&1
	##echo "curl -s 'https://www.googleapis.com/urlshortener/v1/url?shortUrl="$SHORTURL"&projection=FULL' | grep -m2 \"shortUrlClicks\|\\\"longUrl\\\"\""
	#echo "echo "$MREV-$PLATFORM-$CARRIER
	#echo "curl -s 'https://www.googleapis.com/urlshortener/v1/url?shortUrl="$SHORTURL"&projection=FULL' | grep -m1 \"shortUrlClicks\""
	#echo 1>&-
	#chmod 0777 ../url/aurlstats-$CURDATE.sh
	#sed -i 's,http://ktoonsez.jonathanjsimon.com/sgs4/'$PLATFORM'/'$MUXEDNAMESHRT','"[B]"$CURDATE":[/B] [url]"$SHORTURL'[/url],' ../url/SERVERLINKS.txt

	cd $KERNELDIR
else
	echo "** KERNEL DID NOT BUILD! no zImage exist"
fi;
