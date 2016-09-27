#!/usr/bin/env bash
fast=0
[[ "$1" == "fast" ]] && fast=1 && shift || [[ "$1" == "test" ]] && fast=2 && shift
args="$@"

lips="$(readlink -f ../Lua/lib/lips)"
YAZ0="$(readlink -f ../z64yaz0)"
DUMP="$(readlink -f ../z64dump.py)"

#extracted="$(readlink -f "$extracted")"
rom="$(readlink -f "$rom")"

mkdir -p build
quiet=0

[ ! -s "$YAZ0" ] && cc -O3 "${YAZ0}.c" -o "$YAZ0"

dump() {
    (cd "$(dirname "$DUMP")"; ./z64dump.py "$@")
}

if [ $fast -eq 0 ] || [ ! -d patchme ]; then
    if [ -n "$sha1" ]; then
        [ -d build/patchme ] && rm -r build/patchme
        dump -c "$rom"
        mv ../"$sha1" build/patchme
    else
        cp "$rom" "build/$out"
    fi
fi

ratio() {
    local len1="$(wc -c < "$1")"
    local len2="$(wc -c < "$2")"

    if [ $len1 -eq 0 ]; then
        [ $quiet -le 0 ] && echo emptIy
    else
        let percent=(len2*100)/len1
        [ $quiet -le 0 ] && echo "ratio: $percent%"
        return "$((percent < 100))"
    fi
}

unc() {
    local in=patchme/"$1".Yaz0
    local out=patchme/"$1"

    [ -e "$in" ] || return 0
    "$YAZ0" "$in" > "$out"
    [ $quiet -le 0 ] && echo "uncompressed $1"
    ratio "$out" "$in" || true
    rm patchme/"$1".Yaz0
}

comp() {
    local in=patchme/"$1"
    local out=patchme/"$1".Yaz0

    [ -e "$in" ] || return 0
    "$YAZ0" "$in" > "$out"
    [ $quiet -le 0 ] && echo "compressed $1"
    ratio "$in" "$out" && {
        [ $quiet -le 1 ] && echo "leaving uncompressed $1"
        rm "$out"
    } || {
        rm "$in"
    }
}

copy_rom() {
    dd if=patchme.z64 of="$1" bs=$((1024*1024)) count="${2:-32}" status=none
}

cp *.lua build/
cp *.asm build/
#cp *.bin build/
cd build

# don't copy entire dir; avoid copying dotfiles (.git)
mkdir -p lips
cp "$lips"/* lips
