#!/usr/bin/env bash
#=================================================
# name:   init
# author: author <author_contact>
# date:   02/11/2023
#=================================================
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$dir" || exit 1

action=""
half="both"

usage() {
    echo "Ussage: ${0##*/} <ACTION> [OPTIONS]"
    echo ""
    echo "Action:"
    echo "  init           initlaize"
    echo "  deps           install dependencies"
    echo "  build [half]   build firmware [half: both,left,right] default: both"
    echo "  copy [half]    build firmware [half: left,right]"
    echo "  cleanup        cleanup"
    echo ""
    echo "Options:"
    echo "  --left         perform action for left half"
    echo "  --right        perform action for right half"
    echo "  -h, --help     display this help and exit"
}

while test $# -gt 0; do
    case "$1" in
        --left)
            half="left"
            shift
            ;;
        --right)
            half="right"
            shift
            ;;
        deps)
            action="deps"
            shift
            ;;
        update)
            action="update"
            shift
            ;;
        init)
            action="init"
            shift
            ;;
        build)
            action="build"
            shift
            ;;
        copy)
            action="copy"
            shift
            ;;
        cleanup)
            action="cleanup"
            shift
            ;;
        --help | -h)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

if [[ -z $action ]]; then
    usage
    exit 1
fi

if [[ $action == "deps" ]]; then
    paru -S python-west zephyr-sdk
fi

if [[ $action == "init" ]]; then
    west init -l config
    west update
    west zephyr-export
fi

if [[ $action == "update" ]]; then
    west update
fi

if [[ $action == "cleanup" ]]; then
    rm -fr .west modules zephyr zmk
fi

if [[ $action == "copy" ]]; then
    if [[ $half == "both" ]] || [[ $half == "left" ]]; then
        while ! cp ./kyria_left-nice_nano_v2-zmk.uf2 /run/media/pbogut/NICENANO/ 2> /dev/null; do
            echo "Waiting for device [left] ..."
            sleep 1s
        done
        echo "Done"
    fi

    if [[ $half == "both" ]]; then
        sleep 2s
    fi

    if [[ $half == "both" ]] || [[ $half == "right" ]]; then
        while ! cp ./kyria_right-nice_nano_v2-zmk.uf2 /run/media/pbogut/NICENANO/ 2> /dev/null; do
            echo "Waiting for device [right] ..."
            sleep 1s
        done
        echo "Done"
    fi
fi

if [[ $action == "build" ]]; then
    if [[ $half == "both" ]] || [[ $half == "left" ]]; then
        rm build -fr
        mkdir -p ./build/artifacts
        west build -s zmk/app -b "nice_nano_v2" -- -DZMK_CONFIG="$PWD/config" -DSHIELD="kyria_left" &&
            cp build/zephyr/zmk.uf2 kyria_left-nice_nano_v2-zmk.uf2
    fi
    if [[ $half == "both" ]] || [[ $half == "right" ]]; then
        rm build -fr
        mkdir -p ./build/artifacts
        west build -s zmk/app -b "nice_nano_v2" -- -DZMK_CONFIG="$PWD/config" -DSHIELD="kyria_right" &&
            cp build/zephyr/zmk.uf2 kyria_right-nice_nano_v2-zmk.uf2

    fi
fi
