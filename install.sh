#!/bin/bash

is_xkb_directory() {
    [[ -d "$1/rules" && -d "$1/symbols" ]]
}

find_xkb_directory() {
    echo -n "Determining target directory... " >&2
    for directory in "/usr/share/X11/xkb" "/etc/X11/xkb"; do
        if is_xkb_directory "$directory"; then
            echo "$directory"
            echo "$directory" >&2
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
    for layout in symbols/*; do
        cp $layout $xkb_directory/symbols/ ||
        {
            echo Failed to install the layout description.
            [[ "$UID" == 0 ]] || echo -e "\nYou should run the installation as \`sudo $0\`".
            exit 1
        }
    done
}

install_rules() {
    # get_line_numbers pattern filename
    # pattern is an extended regexp.
    # returns numbers array of available lines looking like the pattern,
    # returns "", if no suitable lines were found.
    get_line_numbers(){
        echo `egrep -n "$1" "$2"|cut -d':' -f1`
    }

    patch_list() {
        patch_section() {
            local NUMBERS=($(get_line_numbers "! $2" "$1"))
            local line=${NUMBERS[0]};
            local taillines=$((`wc -l "$1"|cut -d' ' -f1`-$line));
            head -n$line "$1" > "$1.fixed"
            cat "rules/patch-$2.lst" >> "$1.fixed"
            tail -n$taillines "$1" >> "$1.fixed"
            mv "$1.fixed" "$1"
        }

        cp "$1" "$1.rukbi.bak"
        local tmp="$(mktemp rukbi.XXXX)"
        grep -viE '(rukbi|birman)' "$1" > "$tmp"
        patch_section "$tmp" layout
        patch_section "$tmp" variant
        mv "$tmp" "$1"
    }

    patch_xml() {
        cp "$1" "$1.rukbi.bak"
        local SRC="$(mktemp rukbi.XXXX)"
        local DEST="$(mktemp rukbi.XXXX)"
        local PART="$(mktemp rukbi.XXXX)"
        cat "$1">"$SRC"

        while true; do
            local RUKBI_LINE=$(grep -nm1 'rukbi_' "$SRC" | cut -d':' -f1);
            [[ -n "$RUKBI_LINE" ]] ||
            {
                cat "$SRC" >> "$DEST"
                break
            }
            local TAG_OPENING_LINE=$(head -n $(($RUKBI_LINE-1)) "$SRC" | grep -n '<layout>' | tail -n1 | cut -d':' -f1);
            local SRC_LENGTH=$(wc -l "$SRC"|cut -d' ' -f1);
            local TAG_CLOSING_LINE=$(tail -n $(($SRC_LENGTH-$RUKBI_LINE)) "$SRC"| grep -nm1 '</layout>' | cut -d':' -f1);

            head -n $(($TAG_OPENING_LINE-1)) "$SRC" >> "$DEST"
            tail -n $(($SRC_LENGTH-$TAG_CLOSING_LINE-$RUKBI_LINE)) "$SRC" > "$PART"
            local SWAP="$PART"; PART="$SRC"; SRC="$SWAP"
        done

        local TAG_OPENING_LINE=$(grep -nm1 '<layoutList>' "$DEST" | cut -d':' -f1)
        head -n $TAG_OPENING_LINE "$DEST" > "$PART"
        local TAIL=$(($(wc -l "$DEST"|cut -d' ' -f1)-$TAG_OPENING_LINE))
        cat rules/patch-layout.xml >> "$PART"
        tail -n $TAIL "$DEST" >> "$PART"
        mv "$PART" "$DEST"
        rm -f "$SRC"
        rm -f "$PART"
        mv "$DEST" "$1"
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

echo -n "Installing layouts... "
install_symbols
echo -n ". "
install_rules
echo "done"
