#!/bin/bash
#
# Copyright (c) 2017, The Apollo Authors. All Rights Reserved
#
# VERSION:    1.0
# FILEIN:     third_party
# FILEOUT:    fast-rtps_$MACHINE_ARCH

#------------------------ global variable --------------------------
MACHINE_ARCH=$(uname -m)
INSTALL_PATH="fast-rtps_${MACHINE_ARCH}"

#--------------------------- function ------------------------------
function print_usage() {
    echo 'Usage:
    ./build.sh [OPTION]'
    echo 'Options:
    build: run build only
    clean: run environment clean
    '
    return 0
}

function build() {
    #pull FastRTPS source code
    git clone https://github.com/eProsima/Fast-RTPS.git

    #cd Fast-RTPS
    cd Fast-RTPS
    git checkout release/1.4.0
    git submodule init
    git submodule update

    #patch
    patch -p1 < ../FastRTPS_1.4.0.patch
    patch -p1 < ../FastRTPS-VxWorks.patch

    # checkout asio to 1.12
    cd thirdparty/asio/asio
    # git checkout asio-1-12-2
    # patch asio
    # patch -p1 < ../../../../ASIO-1-12-0.patch

    # patch Fast-CDR
    cd ../../fastcdr
    patch -p1 < ../../../0001-use-stdlib-for-VxWorks.patch

    # patch Fast-RTPS
    cd ../..
    patch -p1 < ../0002-undef-NONE.patch

    mkdir -p build/install
    cd build

    cmake -DTHIRDPARTY=ON -DCMAKE_INSTALL_PREFIX=./install -DCMAKE_TOOLCHAIN_FILE=$VSB_DIR/buildspecs/cmake/rtp.cmake -DBUILD_OPTION=-DCMAKE_TOOLCHAIN_FILE=$VSB_DIR/buildspecs/cmake/rtp.cmake ..
    make VERBOSE=1
    make install

    cd ../../
    rm -rf fast-rtps/include/*
    rm -rf fast-rtps/lib/*

    cp -fr Fast-RTPS/build/install/include/* ${INSTALL_PATH}/include/
    cp -fr Fast-RTPS/build/external/install/include/* ${INSTALL_PATH}/include/

    cp -fr Fast-RTPS/build/install/lib/* ${INSTALL_PATH}/lib/
    cp -fr Fast-RTPS/build/external/install/lib/* ${INSTALL_PATH}/lib/

    # rm -rf Fast-RTPS
    ln -rs fast-rtps_$MACHINE_ARCH fast-rtps
}

function clean() {
    rm -rf fast-rtps
    rm -rf Fast-RTPS
}

case $1 in
  build)
    build
    ;;
  clean)
    clean
    ;;
  *)
    print_usage
    ;;
esac
