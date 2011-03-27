#!/bin/bash
script_directory=`dirname $0`

is_xkb_directory() {
    [[ -d "$1/rules" && -d "$1/symbols" ]]
}

find_xkb_directory() {
    for directory in "/usr/share/X11/xkb" "/etc/X11/xkb"; do
        if is_xkb_directory "$directory"; then
            echo $directory
            return
        fi
    done

    local locate_query='/*/xkb/symbols'
    local located=`locate $locate_query`;
    if [[ `echo $located | wc -l` -eq 1 ]]; then
        local directory=`dirname $located`
        if is_xkb_directory $directory; then
            echo $directory
            return
        fi
    fi
}

install_symbols() {
    for layout in $script_directory/symbols/*; do
        cp $layout $xkb_directory/symbols/ ||
        {
            echo Failed to copy $layout
            exit 10
        }
    done
}

install_rules() {
    for list in $xkb_directory/rules/*.lst; do
        echo Patch $list
        $script_directory/patch-list $list $script_directory/rules/patch-layout.lst $script_directory/rules/patch-variant.lst
    done

    for xml in $xkb_directory/rules/*.xml; do
        if [[ -z `echo $xml | grep extras` ]]; then
            echo Patch $xml
            $script_directory/patch-xml $xml $script_directory/rules/patch-layout.xml
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

echo Installing symbols
install_symbols
echo Patching rules
install_rules
echo Done
