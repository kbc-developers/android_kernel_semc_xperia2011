#!/bin/bash

TOP_DIR=$PWD

BUILD_TYPE=$1
OBJ_DIR=$2
MODULE_DIR=$3/lib/modules

# compat
cd $TOP_DIR/ti_wlan/compat-wireless-wl12xx
./scripts/driver-select wl12xx

if [ "$BUILD_TYPE" = 'clean' ]; then
    make KLIB=$OBJ_DIR KLIB_BUILD=$OBJ_DIR ARCH=arm CROSS_COMPILE=$CROSS_COMPILE KERNEL_LOCAL_VERSION=$LOCALVERSION clean
else
    make KLIB=$OBJ_DIR KLIB_BUILD=$OBJ_DIR ARCH=arm CROSS_COMPILE=$CROSS_COMPILE KERNEL_LOCAL_VERSION=$LOCALVERSION -j1

    cp -av ./compat/compat.ko $MODULE_DIR
    cp -av ./compat/compat_firmware_class.ko $MODULE_DIR
    cp -av ./drivers/net/wireless/wl12xx/wl12xx.ko $MODULE_DIR
    cp -av ./drivers/net/wireless/wl12xx/wl12xx_sdio.ko $MODULE_DIR
    cp -av ./net/mac80211/mac80211.ko $MODULE_DIR
    cp -av ./net/wireless/cfg80211.ko $MODULE_DIR
    rm ./compat/compat.ko
    rm ./compat/compat_firmware_class.ko
    rm ./drivers/net/wireless/wl1251/wl1251.ko
    rm ./drivers/net/wireless/wl1251/wl1251_sdio.ko
    rm ./drivers/net/wireless/wl12xx/wl12xx.ko
    rm ./drivers/net/wireless/wl12xx/wl12xx_sdio.ko
    rm ./net/mac80211/mac80211.ko
    rm ./net/wireless/cfg80211.ko
fi

cd $TOP_DIR

