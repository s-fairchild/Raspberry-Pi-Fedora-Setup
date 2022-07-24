#!/bin/bash -x
# Initial setup for Arch Linux Arm on Raspberry Pi

set -o history \
    -o histexpand \
    -o pipefail \
    -o nounset \
    -o errexit

trap ctrl_c SIGINT

BASH_ARGV0="$(echo "${0}" | cut -d '/' -f 2)"

main() {

    scriptDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    rootUserCheck
    tmpFile="$HOME/${0}-reboot-check"
    rebooted="$(rebootCheck "${tmpFile}")"
    if [[ $rebooted == false ]]; then
        echo "${scriptDir}/$0" >> "${HOME}/.bashrc"
        systemUpgrade "${tmpFile}"
    fi
    installPkgs
    finalCleanup "${tmpFile}"
}

setupEmbyContainer() {

    useradd -M -s /sbin/nologin emby
    usermod -aG video emby
}

systemUpgrade() {

    local tmpFile="${1}"
    pacman-key --init
    pacman-key --populate archlinuxarm
    pacman -Syy # update local database for easy searching later
    pacman -Syu # full upgrade
    echo "rebooted=true" > "${tmpFile}" || abort "Failed to create temp reboot check file"
    logger -p info -s "From bash program $(pwd)/${0} Rebooting system now after full upgrade!"
    # systemctl reboot
}

rebootCheck() {

    local tmpFile="${1}"
    if [ ! -f "${tmpFile}" ]; then
        # echo "First time running ${0}"
        echo "rebooted=false" > "${tmpFile}" || abort "Failed to write to ${tmpFile}"
    fi

    . "${tmpFile}" || abort "Unable to source ${tmpFile}"

    echo "${rebooted}"
}

installPkgs() {

    local -a pkgs
    pkgs=(
        vim
        sudo
        git
        bc
        gcc
        make
        base-devel
        i2c-tools
        bash-completion
        alsa-lib
        htop
        zram-generator
        cmake
        core/man
        pacman-contrib
        podman
        btrfs-progs
        podman-docker
        raspberrypi-firmware
        community/motion
        wget
        screen
        extra/boost-libs
        extra/libgudev
        community/sdl_image
        community/apcupsd
    )

    pacman -S --needed --noconfirm "${pkgs[@]}" || abort "Failed to install packages ${pkgs[*]}"
}

rootUserCheck() {

    if [ "$(id -u)" != 0 ]; then
        abort "Logged in as $(whoami), this script must be ran as root user."
    fi
}

abort() {

    if [[ -n $1 ]]; then
        echo "ERROR: ${1}"
        echo "Aborting"
    fi
    exit 1
}

ctrl_c() {

    echo "Cleaning up before exiting..."
}

finalCleanup() {

    if [[ -f $1 ]]; then
        echo "Deleting temperary file ${1}"
        rm "${1}"
    fi
    previousContents="$(grep -vE 'reboot=*' "$HOME/.bashrc")"
    echo "Backing up $HOME/.bashrc and removing $0 to stop an endless loop"
    echo "Backup file is $HOME/.bashrc~"
    cp "$HOME/.bashrc" "$HOME/.bashrc~"
    echo "${previousContents}" > "$HOME/.bashrc"
}

main
