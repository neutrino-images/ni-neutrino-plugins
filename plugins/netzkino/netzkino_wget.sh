#!/bin/sh

wget_busy_file="/tmp/.netzkino_wget.busy"
movie_file="$2"
stream_name="$1"

netzkino_wget() {
	touch $wget_busy_file
	wget -c -O "${movie_file}" "http://pmd.netzkino-and.netzkino.de/${stream_name}.mp4"
	rm $wget_busy_file
}

if [ ! -e $wget_busy_file ]; then
	netzkino_wget &
fi
