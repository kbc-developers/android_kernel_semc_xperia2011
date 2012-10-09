#!/bin/bash

TOP_DIR=$PWD

BUILD_TYPE=$1
OBJ_DIR=$2
MODULE_DIR=$3/lib/modules

# compat
cd $TOP_DIR/ti_wlan/compat-wireless-wl12xx
./scripts/driver-select wl12xx

if [ "$BUILD_TYPE" = 'clean' ]; then
    make clean
else
    if [ "$BUILD_TYPE" = 'build' ]; then
        make KLIB=$OBJ_DIR KLIB_BUILD=$OBJ_DIR ARCH=arm CROSS_COMPILE=$CROSS_COMPILE KERNEL_LOCAL_VERSION=$LOCALVERSION -j1
    fi

    if [ -f ./drivers/net/wireless/wl1251/wl1251.ko ]; then
        rm ./drivers/net/wireless/wl1251/wl1251.ko
    fi
    if [ -f ./drivers/net/wireless/wl1251/wl1251_sdio.ko ]; then
        rm ./drivers/net/wireless/wl1251/wl1251_sdio.ko
    fi

    cp -av ./compat/compat.ko $MODULE_DIR
    cp -av ./compat/compat_firmware_class.ko $MODULE_DIR
    cp -av ./drivers/net/wireless/wl12xx/wl12xx.ko $MODULE_DIR
    cp -av ./drivers/net/wireless/wl12xx/wl12xx_sdio.ko $MODULE_DIR
    cp -av ./net/mac80211/mac80211.ko $MODULE_DIR
    cp -av ./net/wireless/cfg80211.ko $MODULE_DIR
fi

cd $TOP_DIR

