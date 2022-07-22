#!/bin/bash -x

set -o history -o histexpand -o pipefail

main() {

    echo
    downloadCheckImage
    sudo arm-image-installer ${armImageOpts}
}

downloadCheckImage() {

    local wdir="${HOME}/Downloads"
    if [[ -d $wdir ]]; then
        cd "${wdir}" || abort
    fi
    local checksumUrl='https://fedora.mirror.constant.com/fedora/linux/releases/36/Server/aarch64/images/Fedora-Server-36-1.5-aarch64-CHECKSUM'
    local checksumFile='Fedora-Server-36-1.5-aarch64-CHECKSUM'
    local imageUrl='https://fedora.mirror.constant.com/fedora/linux/releases/36/Server/aarch64/images/Fedora-Server-36-1.5.aarch64.raw.xz'
    local imageName='Fedora-Server-36-1.5.aarch64.raw.xz'

    if [[ ! -f $imageName ]]; then
        wget "${imageUrl}" -O "${imageName}"
    fi
    if [[ ! -f $checksumFile ]]; then
        wget "${checksumUrl}" -O "${checksumFile}"
    fi
    verifyChecksum

}

verifyChecksum() {

    local hashType
    hashType="$(cat ${checksumFile} | grep Hash: | cut -d ' ' -f 2)"
    hashProgram="$(echo $hashType | tr '[:upper:]' '[:lower:]')"
    hashProgram+="sum"
    if ! which $hashProgram &> /dev/null; then
        abort "Could not find hashing program: ${hashProgram}"
    else
        generatedChecksum="$($hashProgram ${imageName} | cut -d ' ' -f 1)"
        downloadedChecksum="$(cat $checksumFile | grep "$hashType (Fedora-Server-36-1.5.aarch64.raw.xz) = " | cut -d ' ' -f 4)"
       if [[ $generatedChecksum == "$downloadedChecksum" ]]; then
            echo "Generated hash: ${generatedChecksum}"
            echo "Downloaded hash: ${downloadedChecksum}"
       fi
    fi
}

log() {

    lastCmd="${1}"
    echo "Failed: ${lastCmd}"
    abort
}

abort() {

    if [[ -v $1 ]]; then
        echo "$1"
    fi
    echo "aborting..."
    exit 1
}

collectOpts() {

    local arr
    declare -A arr
    while getopts "d:o:" o; do {
        case "${o}" in
            d)
                arr[device]="${OPTARG}"
                ;;
            o)
                arr[installerOptions]="${OPTARG}"
                ;;
        esac
    }; done

    for o in "${!arr[@]}"; do
        echo -n "[$o]=${arr[$o]} "
    done
}

a="$(collectOpts "$@")"
echo $a
declare -A args=${a}

echo "${args[@]}"
# echo $args

for i in "${args[@]}"; do
    echo ${i}
done

main "${args[@]}"