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
kb=""

usage() {
    echo "Ussage: ${0##*/} <ACTION> [OPTIONS]"
    echo ""
    echo "Action:"
    echo "  init                 initlaize"
    echo "  deps                 install dependencies"
    echo "  build [kb]           build firmware for keyboard [kb: kyria,dactyl_gaming]"
    echo "  copy  [kb]           install firmware for keyboard [kb: kyria,dactyl_gaming]"
    echo "  cleanup              cleanup"
    echo ""
    echo "Options:"
    echo "  --left               perform action for left half"
    echo "  --right              perform action for right half"
    echo "  -h, --help           display this help and exit"
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
            kb="$1"
            shift
            ;;
        copy)
            action="copy"
            shift
            kb="$1"
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
    if [[ -d "$dir/zmk" ]]; then
        git -C "$dir/zmk" reset --hard
    fi
    west init -l config
    west update
    west zephyr-export
    cp "$dir/config/logo.c" "$dir/zmk/app/boards/shields/nice_view/widgets/art.c"
    git -C "$dir/zmk" apply < "$dir/patch/nice_view_battery_percentage.patch"
fi

if [[ $action == "update" ]]; then
    west update
    cp "$dir/config/logo.c" "$dir/zmk/app/boards/shields/nice_view/widgets/art.c"
    git -C "$dir/zmk" apply < "$dir/patch/nice_view_battery_percentage.patch"
fi

if [[ $action == "cleanup" ]]; then
    rm -fr .west modules zephyr zmk
fi

if [[ $action == "copy" ]]; then
    if [[ $kb == "" ]]; then
        echo "Keyboard not specified"
        exit 1
    fi
    case "$kb" in
        "kyria")
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
            ;;
        "dactyl_gaming")
            while ! cp ./dactyl_gaming-nice_nano_v2-zmk.uf2 /run/media/pbogut/NICENANO/ 2> /dev/null; do
                echo "Waiting for device [dactyl_gaming] ..."
                sleep 1s
            done
            ;;
    esac
fi

if [[ $action == "build" ]]; then
    if [[ $kb == "" ]]; then
        echo "Keyboard not specified"
        exit 1
    fi
    case "$kb" in
        "kyria")
            if [[ $half == "both" ]] || [[ $half == "left" ]]; then
                rm build -fr
                mkdir -p ./build/artifacts
                west build -s zmk/app -b "nice_nano_v2" -- -DZMK_CONFIG="$PWD/config" -DSHIELD="kyria_left nice_view_adapter nice_view" &&
                    cp build/zephyr/zmk.uf2 kyria_left-nice_nano_v2-zmk.uf2
            fi
            if [[ $half == "both" ]] || [[ $half == "right" ]]; then
                rm build -fr
                mkdir -p ./build/artifacts
                west build -s zmk/app -b "nice_nano_v2" -- -DZMK_CONFIG="$PWD/config" -DSHIELD="kyria_right nice_view_adapter nice_view" &&
                    cp build/zephyr/zmk.uf2 kyria_right-nice_nano_v2-zmk.uf2

            fi
            ;;
        "dactyl_gaming")
            rm build -fr
            mkdir -p ./build/artifacts
            west build -s zmk/app -b "nice_nano_v2" -- -DZMK_CONFIG="$PWD/config" -DSHIELD="dactyl_gaming" -DZMK_EXTRA_MODULES="$PWD/shields/dactyl_gaming" &&
                cp build/zephyr/zmk.uf2 dactyl_gaming-nice_nano_v2-zmk.uf2
            ;;
    esac
fi
