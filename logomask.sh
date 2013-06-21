#!/bin/sh

if pidof logomask > /dev/null; then
	touch /tmp/.logomask_kill
else
	logomask &
fi
exit 0
