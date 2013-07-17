#!/bin/bash

# Author: Michael Ambrus (ambrmi09@gmail.com)
# 2013-07-16

if [ -z $TOISO_SH ]; then

TOISO_SH="toiso.sh"

TMP_OUT_FILE="/tmp/toiso.txt"


function toiso() {
	echo "Creating ${RIPDIR}/${PROJECT}"
	mkdir "${RIPDIR}/${PROJECT}"
	echo "Reading DVD into [${RIPDIR}/${PROJECT}]"
	rm -f $TMP_OUT_FILE
	touch $TMP_OUT_FILE

	# Make a full mirror. Any copy-protection will still leave us with
	# enough VOBS to to create our own main-feaute (which can me authored if
	# needed)
	if [ "X${VERBOSE}" == "Xyes" ]; then
		time dvdbackup -i /dev/dvd -M -p -o "${RIPDIR}/${PROJECT}"
	else
		time (dvdbackup -i /dev/dvd -M -p -o "${RIPDIR}/${PROJECT}" >> $TMP_OUT_FILE 2>&1 )
	fi
	if [ "X${PROJECT}" == "X${DEF_PROJ}" ]; then
		#No project given on command-line. Detect a new one based on the
		#auto-detected feature-name
		NEW_PROJ=$(ls ${RIPDIR}/${PROJECT} | \
			sed -e 's/[[:space:]]\+/_/g' | \
			tr '[:lower:]' '[:upper:]' )
		echo "New project-name detected..."
		echo "Renaming [${RIPDIR}/${PROJECT}] to [${RIPDIR}/${NEW_PROJ}]"
		mv "${RIPDIR}/${PROJECT}" "${RIPDIR}/${NEW_PROJ}"
		PROJECT="${NEW_PROJ}"
	fi

	#Will spaces be handled correctly?
	FEATURE_CREATED=$(ls ${RIPDIR}/${PROJECT})

	if [ "X${ISO}" == "X${DEF_ISO}" ]; then
		#No specific iso-file-name given. Autodetect one
		NEW_ISO="$(ls ${RIPDIR}/${PROJECT} | \
			sed -e 's/[[:space:]]\+/_/g').iso"
		ISO="${NEW_ISO}"
		echo "New ISO file-name detected [${ISO}]"
	fi

	(
		cd "${RIPDIR}/${PROJECT}"
		echo "Creating iso-file [${ISO}] from [${RIPDIR}/${PROJECT}/${FEATURE_CREATED}]"
		if [ "X${VERBOSE}" == "Xyes" ]; then
			time genisoimage -o "${ISO}" "${RIPDIR}/${PROJECT}/${FEATURE_CREATED}"
		else
			time (genisoimage -o "${ISO}" \
				"${RIPDIR}/${PROJECT}/${FEATURE_CREATED}" >> $TMP_OUT_FILE 2>&1)
		fi
	)
	if [ "X${KEEP}" == "Xno" ]; then
		mv "${RIPDIR}/${PROJECT}/${ISO}" "${RIPDIR}"
		rm -rf "${RIPDIR}/${PROJECT}"
	fi
}

source s3.ebasename.sh
if [ "$TOISO_SH" == $( ebasename $0 ) ]; then
	#Not sourced, do something with this.

	TOISO_SH_INFO="dvd.${TOISO_SH}"
	source .dvd.ui..toiso.sh

	set -u
	set -e

	time toiso "$@"
	RC=$?

	exit $RC
fi

fi
