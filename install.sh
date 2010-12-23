#!/bin/bash

is_xkb_directory() {
    [[ -d "$1/rules" && -d "$1/symbols" ]]
}

find_xkb_directory() {
    for directory in "$PWD/usr" "/usr/share/X11/xkb" "/etc/X11/xkb"; do
        echo -n "Testing directory «$directory»… " >&2;
        if is_xkb_directory $directory; then
            echo $directory
            echo 'yes' >&2
            return
        fi
        echo 'no' >&2
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
        cp $layout $xkb_directory/symbols/
    done
}

install_rules() {
#   get_line_numbers pattern filename
# pattern is an extended regexp.
# returns numbers array of available lines looking like the pattern,
# returns "", if no suitable lines were found.
  get_line_numbers(){
    echo `egrep -n "$1" "$2"|cut -d':' -f1`
  }
    patch_list() {
      patch_section(){
#         echo -n "Adding a section «$2» to a file «$1»... "
        local NUMBERS=($(get_line_numbers "! $2" "$1"))
        local line=${NUMBERS[0]};
#         echo "total lines count: `wc -l "$1"|cut -d' ' -f1`";
#         echo "head lines: $line";
        local taillines=$((`wc -l "$1"|cut -d' ' -f1`-$line));
        head -n$line "$1" > "$1.fixed"
        cat "rules/patch-$2.lst" >> "$1.fixed"
        tail -n$taillines "$1" >> "$1.fixed"
        mv "$1.fixed" "$1"
#         echo 'done';
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
          local TAG_OPENING_LINE=$(head -n $(($RUKBI_LINE-1)) "$SRC" | grep -n '<layout>' "$SRC" | tail -n1 | cut -d':' -f1);

          local SRC_LENGTH=$(wc "$SRC");

          set -x
          local TAG_CLOSING_LINE=$(tail -n $(($SRC_LENGTH-$RUKBI_LINE)) | grep -nm1 '</layout>' "$SRC" | cut -d':' -f1);
          set +x

          head -n $(($TAG_OPENING_LINE-1)) >> "$DEST"
          tail -n $(($SRC_LENGTH-$TAG_CLOSING_LINE)) > "$PART"
          local SWAP="$PART"; PART="$SRC"; SRC="$SWAP"
        done

        #TODO remove existing Rukbi entries from the xml
        #TODO patch xml
#         echo "TODO patch xml"
        rm -f "$SRC"
        rm -f "$PART"
#         mv "$DEST" "$1"
        echo "See the processed file «${DEST}»"
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
