#!/usr/bin/env bash
# Copyright (c) 2023 Vladimir Chren
# All rights reserved.
#
# SPDX-License-Identifier: MIT

# This script extracts default config options and its values
# from metadata_osd.lua script and saves them as .conf file(s).

set -e

declare -r INPFILE="scripts/metadata_osd.lua"
declare -r USERCONFFILE="script-opts/metadata_osd.conf"
declare -r USERCONFFILE_DEFAULTS="script-opts/metadata_osd_defaults.conf"

while getopts e optvar; do
    case "$optvar" in
    e) EXTRACT_DEFAULTS=1 ;;
    esac
done

cat > "$USERCONFFILE" <<~HEREDOCUMENT
## metadata_osd. Example configuration file.
## Default values are pre-filled and commented out.

~HEREDOCUMENT

function extract_luaoptions()
{
    declare -r MATCH_FROM="^local options"
    declare -r MATCH_TO="\*\*\* UNSTABLE OPTIONS BELOW \*\*\*"

    # Extract text between /MATCH_FROM/,/MATCH_TO/ excluding the match itself
    # FIXME: Don't add extra new line at the end.
    sed --regexp-extended -n -e "
        /$MATCH_FROM/{   # if equal $MATCH_FROM
            n;           # read next line / skip current
            bm           # branch label m(atch)
        };
        d;               # delete pattern space & restart cycle
        :m
        /$MATCH_TO/!{    # if not equal $MATCH_TO
            p;           # print pattern space
            n;           # read next line
            bm           # branch m
        }
        q;               # quit" \
    "$INPFILE"
}

function reinterpret_as_userconf()
{
    sed --regexp-extended \
        -e "s/^[[:blank:]]+/#/" \
        -e "s/(.*) = (.*),$/\1=\2/" \
        -e "s/=false$/=no/" \
        -e "s/=true$/=yes/" \
        -e "s/=[\"'](.*)[\"']$/=\1/"
}

function extract_defaults()
{
    sed --regexp-extended \
        -e "/^## /d" \
        -e "/^#-- /d" \
        -e "/^$/d" \
        -e "s/^#(.*)/\1/"
}

extract_luaoptions |
    if [[ -n $EXTRACT_DEFAULTS ]]
    then
        reinterpret_as_userconf |
        tee -a "$USERCONFFILE" |
        extract_defaults > "$USERCONFFILE_DEFAULTS"
    else
        reinterpret_as_userconf >> "$USERCONFFILE"
    fi
