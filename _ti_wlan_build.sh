#!/bin/bash

TOP_DIR=$PWD

BUILD_TYPE=$1
KERNEL_OBJ_DIR=$TOP_DIR/$2
MODULE_DIR=$3/lib/modules
WLAN_OBJ_DIR=./out

export HOST_PLATFORM=msm
export KERNEL_DIR=$KERNEL_OBJ_DIR

# AP
cd $TOP_DIR/ti_wlan/ap/platforms/os/linux
export ROOT_DIR=$WLAN_OBJ_DIR/ap

if [ "$BUILD_TYPE" = 'clean' ]; then
    make clean
else
    make
    cp -av *.ko $MODULE_DIR/
fi

# STA
export ROOT_DIR=$WLAN_OBJ_DIR/sta
cd $TOP_DIR/ti_wlan/sta/platforms/os/linux

if [ "$BUILD_TYPE" = 'clean' ]; then
    make clean
else
    make
    cp -av *.ko $MODULE_DIR/
fi

cd $TOP_DIR/ti_wlan
rm ./ap/platforms/os/linux/tiap_drv.ko
rm ./ap/platforms/os/common/build/linux/tiap_drv.ko
rm ./ap/stad/build/linux/tiap_drv.ko
rm ./sta/platforms/os/linux/tiwlan_drv.ko
rm ./sta/platforms/os/linux/sdio.ko
rm ./sta/platforms/os/common/build/linux/tiwlan_drv.ko
rm ./sta/external_drivers/msm/Linux/sdio/sdio.ko
rm ./sta/stad/build/linux/tiwlan_drv.ko

cd $TOP_DIR

