#!/bin/bash

# Author: Michael Ambrus (ambrmi09@gmail.com)
# 2013-07-18

if [ -z $RBOT_SH ]; then

RBOT_SH="rbot.sh"

TMP_OUT_FILE="/tmp/rbot.txt"


function rbot() {
	if [ "X${VERBOSE}" == "Xno" ]; then
		#Shut inotify up if it doesn't need to be chatty
		INO_EXTRAS="${INO_EXTRAS}-qq"
	fi
	
	#Try open the tray for user if closed
	set +e
	eject ${DRIVE} > /dev/null 2>&1
	eject -T ${DRIVE} > /dev/null 2>&1
	set -e
	N=0

	echo "Please insert new disk in [${DRIVE}] and close the door"
	echo "========================================================="
	inotifywait "${INO_EXTRAS}" -e open ${DRIVE}
	set +e
	while inotifywait "${INO_EXTRAS}" -e close_nowrite ${DRIVE} -t 1200; do
		set -e

		inotifywait "${INO_EXTRAS}" -e close_nowrite ${DRIVE}
		echo "About to scan disk [$N] from [${DRIVE}]"
		inotifywait "${INO_EXTRAS}" -e open ${DRIVE}
		
		set +e
		echo "Waiting for mount 1(2) [${DRIVE}]"
		inotifywait "${INO_EXTRAS}" -e open -t 30 ${DRIVE} || \
			echo "Timed-out, continuing..."
		echo "Waiting for mount 2(2) [${DRIVE}]"
		inotifywait "${INO_EXTRAS}" -e open -t 30 ${DRIVE} || \
			echo "Timed-out, continuing..."
		set -e

		PLAY=$(\
			which play && \
			play ${HOME}/bin/.dvd..rbot_newrun.wav >/dev/null 2>&1 \
		)
		dvd.toiso.sh || \
			PLAY=$(\
				which play && \
				play ${HOME}/bin/.dvd..bad.wav >/dev/null 2>&1 \
			)

		(( N = N + 1 ))
		echo "You have scanned [$N] disks from [${DRIVE}]"
		eject
		echo "Opened [${DRIVE}] for you..."
		
		set +e
		inotifywait "${INO_EXTRAS}" -e attrib ${DRIVE}
		set -e

		echo "Please insert disk in [${DRIVE}] and close the door"
		echo "========================================================="
	done
	set -e

	echo "Buh-by now and thank you for the fish!"
	echo "========================================================="
}

source s3.ebasename.sh
if [ "$RBOT_SH" == $( ebasename $0 ) ]; then
	#Not sourced, do something with this.

	RBOT_SH_INFO="dvd.${RBOT_SH}"
	source .dvd.ui..rbot.sh

	set -u
	set -e
	echo "${RBOT_SH_INFO} started: $(date +"%D %T")"
	time rbot "$@"
	echo "${RBOT_SH_INFO} stopped: $(date +"%D %T")"
	PLAY=$(\
		which play && \
		play ${HOME}/bin/.dvd..alert.wav >/dev/null 2>&1 \
	)
	RC=$?

	exit $RC
fi

fi
