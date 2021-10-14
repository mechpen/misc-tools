#!/bin/bash

case $1 in
    -f)
	FORCE=yes
	shift
	;;
esac

AUR_DIR=${1:-$HOME/aur}

for d in $AUR_DIR/*; do
    echo "checking $d..."
    pushd $d >/dev/null
    git fetch
    if [ "yes" = "$FORCE" ] || ! git diff --quiet origin/master; then
	git pull
	makepkg -si --noconfirm
    fi
    popd >/dev/null
done
