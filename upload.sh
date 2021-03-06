#!/bin/sh

ROM_NAME=SEMC
BIN_DIR=./out/$ROM_NAME/bin
FASTBOOT=`which fastboot`


echo ""
echo "============== fastboot menu ==============="
echo "  1: boot boot.img"
echo "  2: boot recovery.img"
echo "  3: flash boot.img"
echo "  4: flash recovery.img"
echo "  5: reboot"
echo ""
echo "  9: exit"
echo "============================================"
read -p "select menu? (1-9) " SELECT_NO

case "$SELECT_NO" in
  "1" ) sudo $FASTBOOT boot $BIN_DIR/boot.img ;;
  "2" ) sudo $FASTBOOT boot $BIN_DIR/recovery.img ;;
  "3" ) sudo $FASTBOOT flash boot $BIN_DIR/boot.img ;;
  "4" ) sudo $FASTBOOT flash recovery $BIN_DIR/recovery.img ;;
  "5" ) sudo $FASTBOOT reboot ;;
  "9" ) exit 0 ;;
esac
