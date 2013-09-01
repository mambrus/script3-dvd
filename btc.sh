#!/bin/bash

#ORG_DIR=/media/mambrus/Elements/
#ORG_DIR=/media/mambrus/Elements/videos
ORG_DIR=/media/mambrus/Elements/
#NAMES_DIR=/home/mambrus/Videos/trans_perhaps/_failed3
#NAMES_DIR=/home/mambrus/Videos/trans2_perhaps/want/failed1
#NAMES_DIR=/home/mambrus/Videos/trans2_perhaps/newones
#NAMES_DIR=/home/mambrus/Video/trans2_perhaps/maybe_remain
NAMES_DIR=/home/mambrus/Videos/trans3_perhaps/sista
DONE_SDIR=done_sista
MV_TO_DIR=/media/mambrus/Elements/${DONE_SDIR}
ONOK_MOVE="yes"
DEF_VOB_ARGS="-s10000"
DEF_ISO_ARGS="-s0"
SPECIAL=./special.txt
LOG=./log.txt

# Transcode and on success, move original to...
# File to be transcoded is checked against list of files in need for additional
# dvd.tc.sh parameters.
function tc_onsuccess_mvoto() {
	local PROJECT="${1}"
	local EARGS="${2}"

	if [ -f "${SPECIAL}" ]; then
		local ARGS=$(
			cat "${SPECIAL}" | \
				grep -vE '^[[:space:]]*$' | \
				grep -vE '^#' | grep $(basename "${PROJECT}")
		)
	fi
	local FAIL="no"

	if [ "X${ARGS}" == "X" ]; then #I.e project need no special treatment
		echo "Special args: NONE"

		echo "Default args appied: [${EARGS}]"
		local ARGS="$EARGS"
	else
		local ARGS=$(echo "${ARGS}" | cut -f2 -d";")
		echo "Special args: $ARGS"
		ARGS="${ARGS} -s0"
	fi

	dvd.tc.sh $ARGS -t "$(pwd)" "${PROJECT}" || local FAIL="yes"
	if [ "X${FAIL}" == "Xno" ]; then
		echo "Transcoding succeeded. "
		if [ "X${ONOK_MOVE}" == "Xyes" ]; then
			echo "Moving original..."
			mkdir -p "${MV_TO_DIR}/$(dirname $F)" ;  
			mv $F "${MV_TO_DIR}/$(dirname $F)/$(basename $F)"
		fi
	fi
}

function find_projects() {
	echo "Looking for patters (extraxted from filenames in dir): "
	echo "===================================="
	for I in $(
		ls $NAMES_DIR | sed -E 's/.mp4$/_/' | tr '_' '*'); 
	do echo $I; done | sort; 
	echo "===================================="
	echo "Found: "
	echo "===================================="
	for I in $(
		ls $NAMES_DIR | sed -E 's/.mp4$/_/' | tr '_' '*'); 
	do find -L $ORG_DIR -name $I; done | sort; 
	echo "===================================="
	echo "Continue with the actual job: "
	echo "===================================="

	#Find project(s). Naming convention of project:
	# iso-project: path & filename. Must point at valid iso-file
	# vobs-project: path. Must point at directory. Directory is startpoint
	#  for further search. I.e. several sub-projects can be found, is
	#  allowed and will be tcanscoded one by one.
	for F in $(
		for I in $(
			#ls $NAMES_DIR | sed -E 's/.mp4$/.iso/' | tr '_' '*'); 
			ls $NAMES_DIR | sed -E 's/.mp4$/_/' | tr '_' '*'); 
		do find -L $ORG_DIR -name $I; done | sort); 
	do 
		echo "==================";
		echo $F; 
		echo "==================";
		if [ -d "${F}" ]; then
			# This is a VOBDIR. Assume broken with initial garbage. 
			tc_onsuccess_mvoto "${F}" "$DEF_VOB_ARGS"
			echo "Done with VOB-project ["${F}"]"
		else
			tc_onsuccess_mvoto "${F}" "$DEF_ISO_ARGS"
			echo "Done with ISO-project ["${F}"]"
		fi 
	done 
} 

find_projects 2>&1 | tee -a ${LOG}
