#!/usr/bin/env bash
# -----------------------------------------------------------------------------
#
# A simple script for interactive selecting and opening Icelandic radio streams
#
# -----------------------------------------------------------------------------

# Logs a purple colored message to STDERR
function _prompt {
    local purple='\033[35m'
    local nc='\033[0m' # No Color
    echo -e "${purple}$1${nc}" >&2
}

# Log a blue colored message to STDERR
function _info {
    local blue='\033[0;34m'
    local nc='\033[0m' # No Color
    echo -e "${blue}$1${nc}" >&2
}

# Log yellow colored message to STDERR
function _warning {
    local yellow='\033[0;33m'
    local nc='\033[0m' # No Color
    echo -e "${yellow}$1${nc}" >&2
}

# Log red colored message to STDERR
function _error {
    local red='\033[0;31m'
    local nc='\033[0m' # No Color
    echo -e "${red}$1${nc}" >&2
}

# Prompts a selection menu where items can be navigated between using
# the arrow keys.
#
# Expects the first input to be the prompt, and the second input to
# be the output variable. Any further input is considered to be
# the selectable options.
#
# source: https://askubuntu.com/a/1386907
_prompt_selection_menu () {
    if [[ $# -lt 3 ]]; then
        _error "${BASH_SOURCE[0]}, lineno: $LINENO: Expects at least three input parameters to function!"
        return 1
    fi

    local prompt="$1" outvar="$2"
    shift
    shift
    local options=("$@") cur=0 count=${#options[@]} index=0
    local esc
    # cache ESC as test doesn't allow esc codes
    esc=$(echo -en "\e")

    _prompt "$prompt"

    while true; do
        # list all options (option list is zero-based)
        index=0
        for option in "${options[@]}"
        do
            if [ "$index" == "$cur" ]
            then echo -e " >\e[7m$option\e[0m" # mark & highlight the current option
            else echo "  $option"
            fi
            (( index++ ))
        done

        read -s -r -n3 key # wait for user to key in arrows or ENTER

        if [[ $key == $esc[A ]] # up arrow
        then (( cur-- )); (( cur < 0 )) && (( cur = 0 ))
        elif [[ $key == $esc[B ]] # down arrow
        then (( cur++ )); (( cur >= count )) && (( cur = count - 1 ))
        elif [[ $key == "" ]] # nothing, i.e the read delimiter - ENTER
        then break
        fi
        echo -en "\e[${count}A" # go up to the beginning to re-render
    done
    # export the selection to the requested output variable
    printf -v "$outvar" "%s" "${options[$cur]}"
}

function _assert_dependencies {
    if ! command -v mpv &> /dev/null; then
        _error "'mpv' was not found on path! Exiting."
        exit 1
    fi
}

function _stop {
    if [ $# -ne 1 ]; then
        _error "${BASH_SOURCE[0]}, lineno: $LINENO: Function expects a single input parameter!"
        exit 1
    fi

    local process_id="$1"

    kill -15 "$process_id"
}

function _play {
    if [ $# -ne 2 ]; then
        _error "${BASH_SOURCE[0]}, lineno: $LINENO: Function expects two input parameters!"
        exit 1
    fi

    local station="$1"
    local stream="$2"

    setsid mpv --no-video "${stream}" </dev/null &>/dev/null &

    local child_pid=$!
    
    _info "Playing '${station}'"

    _warning "Press CTRL+C to stop"

     trap 'trap - SIGINT; _stop $child_pid' SIGINT
    
    wait "$child_pid"
}

function _select_station {
    local operations selected
    operations=("Exit" "Bylgjan" "Bylgjan - Gull" "Bylgjan - Létt" "Bylgjan - Country" "Bylgjan - Íslenskt" "Bylgjan 80's" "X977" "FM957" "Apparatið" "Rúv - Rás 1" "Rúv - Rás 2" "Rúv - Rondo")

    while true; do
        local selected
        _prompt_selection_menu "Available stations: " selected "${operations[@]}"

        if [ "$selected" == "Exit" ]; then
            exit 0
        elif [ "$selected" == "${operations[1]}" ]; then
            _play "$selected" "https://live.visir.is/hls-radio/bylgjan/chunklist_DVR.m3u8"
        elif [ "$selected" == "${operations[2]}" ]; then
            _play "$selected" "https://live.visir.is/hls-radio/gullbylgjan/chunklist_DVR.m3u8"
        elif [ "$selected" == "${operations[3]}" ]; then
            _play "$selected" "https://live.visir.is/hls-radio/lettbylgjan/chunklist_DVR.m3u8"
        elif [ "$selected" == "${operations[4]}" ]; then
            _play "$selected" "https://live.visir.is/hls-radio/fmextra/chunklist_DVR.m3u8"
        elif [ "$selected" == "${operations[5]}" ]; then
            _play "$selected" "https://live.visir.is/hls-radio/islenska/chunklist_DVR.m3u8"
        elif [ "$selected" == "${operations[6]}" ]; then
            _play "$selected" "https://live.visir.is/hls-radio/80s/chunklist_DVR.m3u8"
        elif [ "$selected" == "${operations[7]}" ]; then
            _play "$selected" "https://live.visir.is/hls-radio/x977/chunklist_DVR.m3u8"
        elif [ "$selected" == "${operations[8]}" ]; then
            _play "$selected" "https://live.visir.is/hls-radio/fm957/chunklist_DVR.m3u8"
        elif [ "$selected" == "${operations[9]}" ]; then
            _play "$selected" "https://live.visir.is/hls-radio/apparatid/chunklist_DVR.m3u8"
        elif [ "$selected" == "${operations[10]}" ]; then
            _play "$selected" "https://ruv-radio-live.akamaized.net/streymi/ras1/ras1/ras1.m3u8"
        elif [ "$selected" == "${operations[11]}" ]; then
            _play "$selected" "https://ruv-radio-live.akamaized.net/streymi/ras2/ras2/ras2.m3u8"
        elif [ "$selected" == "${operations[12]}" ]; then
            _play "$selected" "https://ruv-radio-live.akamaized.net/streymi/rondo/rondo/rondo.m3u8"
        else
            _error "Unknown selection!"
        fi
    done
}

function _execute {
    _assert_dependencies

    _select_station
}

_execute
