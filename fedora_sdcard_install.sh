#!/bin/bash
# Document and automate arm image installer for Fedora installs

# TODO add ssh key check first

nice -n -15 arm-image-installer \
    --media=/dev/sdb \
    --image="${HOME}/Downloads/Fedora-Server-36-1.5.aarch64.raw.xz" \
    --addkey="${HOME}/.ssh/id_rsa.pub" \
    --addconsole \
    --resizefs \
    --showboot \
    --target=rpi4 
