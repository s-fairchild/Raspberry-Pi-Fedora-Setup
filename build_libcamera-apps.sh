#!/bin/bash
# Build libcamera and libcamera-apps for Fedora 36 Server aarch64

source common.env

libCameraPkgs=""
LibeproxyPkgs="mesa-libOSMesa-devel"

buildDepPkgs="${libCameraPkgs} ${LibeproxyPkgs}"

buildLibcameraApps() {

    cd /tmp || abort
    git clone https://github.com/raspberrypi/libcamera-apps.git || abort
    cd libcamera-apps || abort
    mkdir build
    cd build || abort
    # OpenCV Should build if libraries are installed
    # cmake .. -DENABLE_DRM=1 -DENABLE_X11=0 -DENABLE_QT=0 -DENABLE_OPENCV=0 -DENABLE_TFLITE=0
    cmake .. -DENABLE_DRM=1 -DENABLE_X11=0 -DENABLE_QT=0 -DENABLE_TFLITE=0
}

buildLibcamera() {

    cd /tmp || abort
    git clone git://linuxtv.org/libcamera.git || abort
    cd libcamera || abort
    meson build --buildtype=release -Dpipelines=raspberrypi -Dipas=raspberrypi -Dv4l2=true -Dgstreamer=enabled -Dtest=false -Dlc-compliance=disabled -Dcam=disabled -Dqcam=disabled -Ddocumentation=disabled
    local -i buildPid
    buildPid=$(ninja -j4 -C build)
    sudo renice -n -15 $buildPid
    sudo ninja -C build install
}

buildLibepoxy() {

    cd /tmp || abort
    git clone https://github.com/anholt/libepoxy.git || abort
    cd libepoxy || abort
    mkdir _build
    cd _build || abort
    meson
    ninja
    sudo ninja install
}