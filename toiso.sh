#!/bin/bash

# Author: Michael Ambrus (ambrmi09@gmail.com)
# 2013-07-16

if [ -z $TOISO_SH ]; then

TOISO_SH="toiso.sh"


function toiso() {
	echo "TBD"
}

source s3.ebasename.sh
if [ "$TOISO_SH" == $( ebasename $0 ) ]; then
	#Not sourced, do something with this.

	TOISO_SH_INFO="dvd.${TOISO_SH}"
	source .dvd.ui..toiso.sh

	toiso "$@"
	RC=$?

	exit $RC
fi

fi
