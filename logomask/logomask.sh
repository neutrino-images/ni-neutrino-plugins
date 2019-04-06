#!/bin/sh

PIDFILE=/tmp/logomask.pid

if [ -e $PIDFILE ]; then
	echo "stopping logomask"
	read PID < $PIDFILE && kill -TERM $PID
else
	logomask
fi

exit 0
