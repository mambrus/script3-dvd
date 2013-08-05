#!/bin/bash

#ORG_DIR=/media/mambrus/Elements/
ORG_DIR=/media/mambrus/Elements/videos
#NAMES_DIR=/home/mambrus/Videos/trans_perhaps/_failed3
NAMES_DIR=/home/mambrus/Videos/trans2_perhaps/want
DONE=done_loose_vobs
SPECIAL=./special.txt

# Transcode and on success, move original to...
# File to be transcoded is checked against list of files in need for additional
# dvd.tc.sh parameters.
function tc_onsuccess_mvoto() {
	EARGS="${2}"

	if [ -f "${SPECIAL}" ]; then
		local ARGS=$(
			cat "${SPECIAL}" | \
				grep -vE '^[[:space:]]*$' | \
				grep -vE '^#' | grep $(basename "${1}")
		)
	fi
	local FAIL="no"
	if [ "X${ARGS}" == "X" ]; then
		echo "Special args: NONE"
		dvd.tc.sh -t "$(pwd)" $EARGS "${1}" || local FAIL="yes"
	else
		local ARGS=$(echo "${ARGS}" | cut -f2 -d";")
		echo "Special args: $ARGS"
		dvd.tc.sh $ARGS -t "$(pwd)" "${1}" || local FAIL="yes"
	fi
	if [ $FAIL == "no" ]; then
		echo "Transcoding succeeded. Moving original..."
		mkdir -p "$ORG_DIR/../${DONE}/$(dirname $F)" ;  
		mv $F "$ORG_DIR/../${DONE}/$(dirname $F)/$(basename $F)"
	fi
}

(
	for F in $(
		for I in $(
			#ls $NAMES_DIR | sed -E 's/.mp4$/.iso/' | tr '_' '*'); 
			ls $NAMES_DIR | sed -E 's/.mp4$//' | tr '_' '*'); 
		do find $ORG_DIR -name $I; done | sort); 
	do 
		echo "==================";
		echo $F; 
		echo "==================";
		if [ -d "${F}" ]; then
#This is a VOBDIR. Assume broken with initial garbage. HAX it 5s off.
			tc_onsuccess_mvoto "${F}" "-s10000"
			echo "Done with VOB-project ["${F}"]"
		else
			tc_onsuccess_mvoto "${F}"
			echo "Done with ISO-project ["${F}"]"
		fi 
	done 
) 2>&1 | tee -a /tmp/log_append_loosevobs.txt

