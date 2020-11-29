#!/bin/sh

if [ $# -eq 0 ]; then
	echo "usage: ${0##*/} <iframe>"
	exit 1
fi

iframe=""
for path in "/var/tuxbox/icons" "/usr/share/tuxbox/neutrino/icons"; do
	if [ -f "$path/$1" ]; then
		iframe="$path/$1"
		break
	fi
done

if [ $iframe ]; then
	showiframe $iframe
else
	echo "not found: $1"
	exit 1
fi
