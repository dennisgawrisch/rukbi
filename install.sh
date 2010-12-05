#!/bin/bash

is_xkb_directory() {
    [[ -d "$1/rules" && -d "$1/symbols" ]]
}

find_xkb_directory() {
    for directory in "/usr/share/X11/xkb" "/etc/X11/xkb"; do
        if is_xkb_directory $directory; then
            echo $directory
            return
        fi
    done

    local locate_query='/*/xkb/symbols'
    if [[ `locate $locate_query | wc -l` -eq 1 ]]; then
        local directory=`locate $locate_query`
        local directory=`dirname $directory`
        if is_xkb_directory $directory; then
            echo $directory
            return
        fi
    fi
}

install_symbols() {
    for layout in symbols/*; do
        cp $layout $xkb_directory/symbols/
    done
}

install_rules() {
    patch_list() {
        cp $1 $1.rukbi.bak
        local tmp=/tmp/`basename $1`
        cat $1 | grep -v rukbi > $tmp
        echo "TODO patch list"
        rm $tmp
    }

    patch_xml() {
        cp $1 $1.rukbi.bak
        #TODO remove existing Rukbi entries from the xml
        #TODO patch xml
        echo "TODO patch xml"
    }

    for list in $xkb_directory/rules/*.lst; do
        patch_list $list
    done

    for xml in $xkb_directory/rules/*.xml; do
        if [[ -z `echo $xml | grep extras` ]]; then
            patch_xml $xml
        fi
    done
}

while getopts d: option; do
    case $option in
        d)  xkb_directory=$OPTARG;;
        ?)  echo Usage: $0 [-d=/path/to/xkb]
            exit 1
    esac
done

if [[ -n $xkb_directory ]]; then
    if ! is_xkb_directory $xkb_directory; then
        echo Not an XKB directory.
        exit 2
    fi
else
    xkb_directory=`find_xkb_directory`
    if [[ -z $xkb_directory ]]; then
        echo Could not find XKB directory. Please use -d=/path/to/xkb command line option.
        exit 3
    fi
fi

install_symbols
install_rules
