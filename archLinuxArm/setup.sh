#!/bin/bash -x
# Initial setup for Arch Linux Arm on Raspberry Pi

set -o history \
    -o histexpand \
    -o pipefail \
    -o nounset \
    -o errexit

trap cleanup SIGINT

#BASH_ARGV0="$(echo "${0}" | cut -d '/' -f 2)"

main() {

    rootUserCheck
    setupBashEnv
    postRebootFile="/var/run/post-reboot"

    if [[ -f $postRebootFile ]]; then
        systemUpgrade $postRebootFile
        logger -p info -s "From bash program $(pwd)/${0} Rebooting system now after full upgrade!"
        systemctl reboot
    fi
    
    installPkgs

    if [ ! "${#embyVolumes[@]}" == 0 ]; then
        setupEmbyContainer "${embyVolumes[@]}"
    fi


    finalCleanup "$postRebootFile"
}

setupEmbyContainer() {

    local volStr
    for v in "$@"; do
        volStr+="--volume $v:/mnt/$(cleanupContainerMounts $v) "
    done

    echo "${volStr}"

    if ! grep -E '^emby:' /etc/passwd &> /dev/null; then
        useradd -M -s /sbin/nologin emby || abort "Failed to create emby container user"
        usermod -aG video emby
    fi

    # TODO add conditional check for vchipq and adjust container creation
    # also add warning message about higher CPU usage due to no GPU
    podman run -d \
        --name embyserver \
        ${volStr} \
        --device /dev/dri:/dev/dri \
        --device /dev/vchiq:/dev/vchiq \
        -p 8096:8096 \
        -e UID="$(id -u emby)" \
        -e GID="$(id -g emby)" \
        -e GIDLIST="$(id -G emby | tr ' ' '\n' | tail -n +2)" \
        -e TZ=America/Chicago \
        docker.io/emby/embyserver_arm64v8 || abort "Failed to create embyserver container"
    
    podman generate systemd embyserver > /usr/lib/systemd/system/embyserver-container.service || abort "Failed to create embyserver systemd unit file"
    systemctl daemon-reload
    systemctl enable --now embyserver-container
}

# cleanupContainerMounts accepts a string directory path and returns the last directory in said path
cleanupContainerMounts() {

    IFS='/'
    read -ra arr <<< "$1"
    echo "${arr[-1]}"
}

# setupBashEnv creates .bash_profile, and .bashrc and configures
# ~/.bashrc to be read upon login, non default but expected bash behavior
setupBashEnv() {

    if [ ! -f "$HOME/.bash_profile" ]; then
        echo "

#
# ~/.bash_profile
#

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi
" > "$HOME/.bash_profile"
    fi

    if [ ! -f "$HOME/.bashrc" ]; then
        echo "
#
# ~/.bashrc
#

# For visudo
export env_editor
export EDITOR=/usr/bin/vim

alias ls='ls --color=auto'
alias ll='ls -lhtr'
alias la='ls -a'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Change forground prompt to green
export PS1='\e[32m\u@\h \W]\$ \e[m'
" > "$HOME/.bashrc"
    fi

    cp "$HOME/.bashrc" "$HOME/.bashrc~"
    # Restart script upon root user login
    echo "${0}" >> "$HOME/.bashrc"
}

# systemUpgrade initilizes the pacman package manager keyring
# Then updates local database, and performs a full system upgrade and reboot
systemUpgrade() {

    # create post reboot file
    if [ ! -f "$1" ]; then
        touch "$1"
    fi

    pacman-key --init
    pacman-key --populate archlinuxarm
    pacman -Syy # update local database for easy searching later
    pacman -Syu # full upgrade
}

installPkgs() {

    local -a pkgs
    pkgs=(
        'vim'
        'sudo'
        'git'
        'bc'
        'gcc'
        'make'
        'base-devel'
        'i2c-tools'
        'bash-completion'
        'alsa-lib'
        'htop'
        'zram-generator'
        'cmake'
        'core/man'
        'pacman-contrib'
        'podman'
        'btrfs-progs'
        'podman-docker'
        'raspberrypi-firmware'
        'community/motion'
        'wget'
        'screen'
        'extra/boost-libs'
        'extra/libgudev'
        'community/sdl_image'
        'community/apcupsd'
    )

    pacman -S --needed --noconfirm "${pkgs[@]}" || abort "line: ${LINENO} Failed to install packages ${pkgs[*]}"
}

rootUserCheck() {

    if [ "$(id -u)" != 0 ]; then
        abort "line: ${LINENO} Logged in as $(whoami), this script must be ran as root user."
    fi
}

abort() {

    if [[ -n $1 ]]; then
        echo "ERROR: ${1}"
        echo "Aborting"
    fi
    exit 1
}

cleanup() {

    echo "Cleaning up before exiting..."
    if [[ -f $1 ]]; then
        rm -f $1
    fi
}

finalCleanup() {

    # rm File used to detect first reboot
    if [[ -f $1 ]]; then
        echo "Deleting temperary file ${1}"
        rm "${1}"
    fi
    cp "$HOME/.bashrc" "$HOME/.bashrc~"

    # Remove this script from ~/.bashrc to prevent running on every login
    cat "$HOME/.bashrc~" | grep -v "${0}" > "$HOME/.bashrc"
}

usage() {
    echo -e "
usage: ${0} [-c] [-h]
    -c : Emby Podman Volume(s) or local folders to mount as media libraries
            For multiple volumes, invoke -c each time

    -h Display this message
"
    exit 1
}

declare -a embyVolumes=()
while getopts "c:" o; do
    case $o in
        c )
            # TODO use string splitting by comma to allow for comman seperated list for one -c option
            embyVolumes+=("${OPTARG}")
            ;;
        ?|* )
            usage
            ;;
    esac
done

main "${embyVolumes[@]}"
