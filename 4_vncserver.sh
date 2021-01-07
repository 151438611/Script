#!/bin/bash

case "$1" in
	start)	
		[ "$(pidof Xtigervnc)" ] || \
		/usr/bin/vncserver -localhost no -depth 24 -geometry 1920x1080 -SecurityTypes VncAuth
	;;
	stop)	
		/usr/bin/vncserver -kill :* -clean
	;;
	status)
		/usr/bin/vncserver -list
	;;
	restart) 
		$0 stop
		sleep 2
		$0 start
	;;
	*)	
		echo "Usage: bash vncserver.sh {start|stop|status|restart}"
		exit 2
	;;
esac
