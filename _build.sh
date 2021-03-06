#!/bin/bash

KERNEL_DIR=$PWD

cpoy_initramfs()
{
    if [ -d $INITRAMFS_TMP_DIR ]; then
        rm -rf $INITRAMFS_TMP_DIR  
    fi
    cp -a $INITRAMFS_SRC_DIR $(dirname $INITRAMFS_TMP_DIR)
    rm -rf $INITRAMFS_TMP_DIR/.git
    find $INITRAMFS_TMP_DIR -name .gitignore | xargs rm
}

if [ ! -n "$1" ]; then
    echo ""
    read -p "select ramdisk? [(s)amsung/(a)osp default:samsung] " BUILD_RAMDISK
else
    BUILD_RADISK=$1
fi

# check target
BUILD_TARGET=$1
case "$BUILD_TARGET" in
    "AOSP" ) BUILD_DEFCONFIG=kbc_urushi_aosp_defconfig ;;
    "SEMC" ) BUILD_DEFCONFIG=kbc_urushi_semc_defconfig ;;
    * ) echo "error: not found BUILD_TARGET" && exit -1 ;;
esac
BIN_DIR=out/$BUILD_TARGET/bin
OBJ_DIR=out/$BUILD_TARGET/obj
mkdir -p $BIN_DIR
mkdir -p $OBJ_DIR

# generate LOCALVERSION
. mod_version

# check and get compiler
. cross_compile

# set build env
export ARCH=arm
export CROSS_COMPILE=$BUILD_CROSS_COMPILE
export LOCALVERSION="-$BUILD_LOCALVERSION"

echo "=====> BUILD START $BUILD_KERNELVERSION-$BUILD_LOCALVERSION"

if [ ! -n "$2" ]; then
    echo ""
    read -p "select build? [(b)oot/(r)ecovery default:boot] " BUILD_TARGET
else
    BUILD_TARGET=$2
fi

if [ ! -n "$3" ]; then
    echo ""
    read -p "select build? [(a)ll/(u)pdate/(i)mage default:update] " BUILD_SELECT
else
    BUILD_SELECT=$3
fi

# copy initramfs
if [ "$BUILD_TARGET" = 'recovery' -o "$BUILD_TARGET" = 'r' ]; then
    INITRAMFS_SRC_DIR=../so03c_recovery_ramdisk
    INITRAMFS_TMP_DIR=/tmp/so03c_recovery_ramdisk
    IMAGE_NAME=recovery
else
    INITRAMFS_SRC_DIR=../so03c_boot_ramdisk
    INITRAMFS_TMP_DIR=/tmp/so03c_boot_ramdisk
    IMAGE_NAME=boot
fi
echo ""
echo "=====> copy initramfs"
cpoy_initramfs


# make start
if [ "$BUILD_SELECT" = 'all' -o "$BUILD_SELECT" = 'a' ]; then
    echo ""
    echo "=====> cleaning"
    ./_ti_wlan_build.sh clean $KERNEL_DIR/$OBJ_DIR $INITRAMFS_TMP_DIR
    make clean
    cp -f ./arch/arm/configs/$BUILD_DEFCONFIG $OBJ_DIR/.config
    make -C $PWD O=$OBJ_DIR KERNEL_LOCAL_VERSION=$LOCALVERSION oldconfig || exit -1
fi

if [ "$BUILD_SELECT" != 'image' -a "$BUILD_SELECT" != 'i' ]; then
    echo ""
    echo "=====> build start"
    if [ -e make.log ]; then
        mv make.log make_old.log
    fi
    nice -n 10 make O=$OBJ_DIR KERNEL_LOCAL_VERSION=$LOCALVERSION -j12 2>&1 | tee make.log
fi

# check compile error
COMPILE_ERROR=`grep 'error:' ./make.log`
if [ "$COMPILE_ERROR" ]; then
    echo ""
    echo "=====> ERROR"
    grep 'error:' ./make.log
    exit -1
fi

# TI WLAN module build
if [ "$BUILD_SELECT" != 'image' -a "$BUILD_SELECT" != 'i' ]; then
    ./_ti_wlan_build.sh build $KERNEL_DIR/$OBJ_DIR $INITRAMFS_TMP_DIR
else
    ./_ti_wlan_build.sh copy $KERNEL_DIR/$OBJ_DIR $INITRAMFS_TMP_DIR
fi

# *.ko copy
find -name '*.ko' -exec cp -av {} $INITRAMFS_TMP_DIR/lib/modules/ \;

echo ""
echo "=====> CREATE RELEASE IMAGE"
# clean release dir
if [ `find $BIN_DIR -type f | wc -l` -gt 0 ]; then
    rm -rf $BIN_DIR/*
fi
mkdir -p $BIN_DIR

# copy zImage
cp $OBJ_DIR/arch/arm/boot/zImage $BIN_DIR/kernel
echo "----- Making uncompressed $IMAGE_NAME ramdisk ------"
./release-tools/mkbootfs $INITRAMFS_TMP_DIR > $BIN_DIR/ramdisk-$IMAGE_NAME.cpio
echo "----- Making $IMAGE_NAME ramdisk ------"
#./release-tools/minigzip < $BIN_DIR/ramdisk-$IMAGE_NAME.cpio > $BIN_DIR/ramdisk-$IMAGE_NAME.img
lzma < $BIN_DIR/ramdisk-$IMAGE_NAME.cpio > $BIN_DIR/ramdisk-$IMAGE_NAME.img
echo "----- Making $IMAGE_NAME image ------"
./release-tools/mkbootimg --base 0x00200000 --kernel $BIN_DIR/kernel --ramdisk $BIN_DIR/ramdisk-$IMAGE_NAME.img --output $BIN_DIR/$IMAGE_NAME.img

# size check
FILE_SIZE=`wc -c $BIN_DIR/$IMAGE_NAME.img | awk '{print $1}'`
if [ $FILE_SIZE -gt 13107200 ]; then
    echo "FATAL: boot image size over. image size = $FILE_SIZE > 13107200 byte"
    rm $BIN_DIR/$IMAGE_NAME.img
    exit -1
fi

# create cwm image
cd $BIN_DIR
if [ -d tmp ]; then
    rm -rf tmp
fi
mkdir -p ./tmp/$BUILD_LOCALVERSION-$IMAGE_NAME
cp $IMAGE_NAME.img ./tmp/$BUILD_LOCALVERSION-$IMAGE_NAME
cp $KERNEL_DIR/release-note.txt ./tmp/$BUILD_LOCALVERSION-$IMAGE_NAME/
git log > ./tmp/$BUILD_LOCALVERSION-$IMAGE_NAME/kernel-commitlog.txt
cd $KERNEL_DIR/$INITRAMFS_SRC_DIR
git log > $KERNEL_DIR/$BIN_DIR/tmp/$BUILD_LOCALVERSION-$IMAGE_NAME/ramdisk-commitlog.txt
cd $KERNEL_DIR/$BIN_DIR/tmp
tar -jcf ../$BUILD_LOCALVERSION-$IMAGE_NAME.tar.bz2 $BUILD_LOCALVERSION-$IMAGE_NAME
echo "  $BIN_DIR/$BUILD_LOCALVERSION-$IMAGE_NAME.tar.bz2"

cd $KERNEL_DIR
echo ""
echo "=====> BUILD COMPLETE $BUILD_KERNELVERSION-$BUILD_LOCALVERSION"
exit 0
