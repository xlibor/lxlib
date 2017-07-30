#!/bin/sh

PACKAGE_PATH="$1"
LXBIN_PATH="/usr/local/bin"

echo "start installing lxlib..."
osname=`uname`

if [ -n "$PACKAGE_PATH" ];then
    LPKG_PATH="${PACKAGE_PATH}/"
    LXPUB_PATH="${PACKAGE_PATH}/lxpub"
    PACKAGE_PATH="${PACKAGE_PATH}/lxlib"
   echo "use defined path: "${PACKAGE_PATH}
else
   LPKG_PATH="/usr/local/lxroot"
   LXPUB_PATH="/usr/local/lxroot/lxpub"
   mkdir -p $LPKG_PATH
   PACKAGE_PATH="/usr/local/lxroot/lxlib"
   echo "use default path: ${PACKAGE_PATH}"
fi

mkdir -p $PACKAGE_PATH
mkdir -p $LXBIN_PATH
mkdir -p $LXPUB_PATH
mkdir -p $LXPUB_PATH/log

rm -rf $LXBIN_PATH/lx
rm -rf $PACKAGE_PATH/*

echo "install lxlib console to $LXBIN_PATH"

cp ./lxlib/support/lxbin $LXBIN_PATH/lx
chmod 755 $LXBIN_PATH/lx

if [ $osname = "Linux" ];then
    sed -i "s#LXLIB_PATH#$LPKG_PATH#g" $LXBIN_PATH/lx
else
    sed -i "" "s#LXLIB_PATH#$LPKG_PATH#g" $LXBIN_PATH/lx
fi

echo "install lxlib framework to $PACKAGE_PATH"
cp -a ./lxlib/* $PACKAGE_PATH/

echo -e "\033[32mlxlib installed successfull. \033[0m"
