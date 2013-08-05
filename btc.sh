#!/bin/bash

#ORG_DIR=/media/mambrus/Elements/
ORG_DIR=/media/mambrus/Elements/videos
#NAMES_DIR=/home/mambrus/Videos/trans_perhaps/_failed3
NAMES_DIR=/home/mambrus/Videos/trans2_perhaps/want/failed1
DONE=done_loose_vobs
ONOK_MOVE="yes"
DEF_VOB_ARGS="-s10000"
SPECIAL=./special.txt

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
	if [ "X${ARGS}" == "X" ]; then
		#Not set (i.e project not found)
		echo "Special args: NONE"

		if [ -d "${PROJECT}" ]; then
			# If directory, it must be a VOBs-project
			echo "Project is a VOB-dir. Default args appied: [${EARGS}]"
			local ARGS="$EARGS"
		fi
	else
		local ARGS=$(echo "${ARGS}" | cut -f2 -d";")
		echo "Special args: $ARGS"
	fi

	dvd.tc.sh $ARGS -t "$(pwd)" "${PROJECT}" || local FAIL="yes"
	if [ "X${FAIL}" == "Xno" ]; then
		echo "Transcoding succeeded. "
		if [ "X${ONOK_MOVE}" == "Xyes" ]; then
			echo "Moving original..."
			mkdir -p "$ORG_DIR/../${DONE}/$(dirname $F)" ;  
			mv $F "$ORG_DIR/../${DONE}/$(dirname $F)/$(basename $F)"
		fi
	fi
}

function find_projects() {
	#Find project(s). Naming convention of project:
	# iso-project: path & filename. Must point at valid iso-file
	# vobs-project: path. Must point at directory. Directory is startpoint
	#  for further search. I.e. several sub-projects can be found, is
	#  allowed and will be tcanscoded one by one.
	for F in $(
		for I in $(
			#ls $NAMES_DIR | sed -E 's/.mp4$/.iso/' | tr '_' '*'); 
			ls $NAMES_DIR | sed -E 's/.mp4$/_/' | tr '_' '*'); 
		do find $ORG_DIR -name $I; done | sort); 
	do 
		echo "==================";
		echo $F; 
		echo "==================";
		if [ -d "${F}" ]; then
			# This is a VOBDIR. Assume broken with initial garbage. 
			tc_onsuccess_mvoto "${F}" $DEF_VOB_ARGS
			echo "Done with VOB-project ["${F}"]"
		else
			tc_onsuccess_mvoto "${F}"
			echo "Done with ISO-project ["${F}"]"
		fi 
	done 
} 

find_projects 2>&1 | tee -a /tmp/log_append_loosevobs.txt

