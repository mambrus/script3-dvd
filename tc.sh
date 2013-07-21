#!/bin/bash

# Author: Michael Ambrus (ambrmi09@gmail.com)
# 2013-07-19

if [ -z $TC_SH ]; then

source .dvd..funcs.sh

#Global variables:

# In bash, arrays cant be easily transfered between functions if entries in them
# contain whitespace. Problem could be handled as a normal list, but then
# either bash IFS, or whitespace in each element would need to be changed.

PROJ_AR=()
VOBS_AR=()

TC_SH="tc.sh"

TMP_OUT_FILE="/tmp/tc.txt"

#Find all vob-dirs relative $1
function get_vobs() {

	# Make a list first with spaces fixed so that we can sort and make it
	# unique easier. Use a marker unlikely to occur in a filename (¤). This
	# is cheating, but sorting an array in Bash is a pain in the ass.

	local L=$(for F in $(find "${1}" -iname "*.vob" | tr ' ' '¤'); do
		dirname $F
	done | sort -u)

	# Convert to resulting arrays, transfer back the marker in the process.
	PROJ_AR=()
	VOBS_AR=()
	declare -li I=0 #Declare as local and integer. Not strictly necessary
	for D in $L; do
		VOBS_AR[$I]=$(echo $D | tr '¤' ' ')
		PROJ_AR[$I]=$(basename "$(echo $D | tr '¤' ' ' | sed -e 's/VIDEO_TS//')")
		(( ++I )) #Dont post-increment or it will upset 'set -e'
	done
}

#Analyse and identify the main feature relative $1
function main_feature() {
	PUSHD "${1}"
	FILES_SZ_CORRECT=$(ls -al "${1}" | \
		awk '{print $5":"$9}' | egrep '^[1-9]' | \
		awk -vMIN=$MF_MINSZ -vMAX=$MF_MAXSZ -F":" '
		{
			if (($1>MIN) && ($1<MAX))
				print $0
		}'
	)

	POPD

	#if [ $VERBOSE == "yes" ]; then
		echo "Files matching main-feature criteria:" 1>&2
		echo $FILES_SZ_CORRECT | sed -e 's/\(vob\|VOB\) */\1\n/g' 1>&2
		echo 1>&2
		echo "Feature(s) selected:" 1>&2
		echo $FILES_SZ_CORRECT | \
			sed -E 's/([0-9]+:)(VTS_[0-9]{2})(_[0-9]\.VOB[[:space:]]*)/\2\n/g' | \
			awk '/^VTS/{print $0}' | \
			sort -u  1>&2
	#fi

	FEATURES=$(echo $FILES_SZ_CORRECT | \
		sed -E 's/([0-9]+:)(VTS_[0-9]{2})(_[0-9]\.VOB[[:space:]]*)/\2\n/g' | \
		awk '/^VTS/{print $0}' | \
		sort -u )

	if 	[ $(echo $FEATURES | wc -l) -eq 1 ]; then
		echo "${FEATURES}"
	else
		echo "Error: Features possible are not equal to 1" 1>%1
		return 1
	fi
}


function tc_from_iso() {
	#dvdbackup -i IN_file.iso -p -F -o ./OUT_Dir
	echo "TBD"
}


function tc_from_vobdir() {
	get_vobs "${RIPDIR}"

	if [ ${#PROJ_AR[@]} -ne ${#VOBS_AR[@]} ]; then
		#Sanity check
		echo "$0 Internal error!" 1>&2
		exit 1
	fi

	if [ $VERBOSE == "yes" ]; then
		for (( I=0; I < ${#PROJ_AR[@]}; I++)); do
			if [ ${#PROJ_AR[$I]} -lt $COL1_WIDTH ]; then
				tput cuf $(( COL1_WIDTH - ${#PROJ_AR[$I]} ))
				echo "${PROJ_AR[$I]} <- ${VOBS_AR[$I]}"
				tput cuf $(( COL1_WIDTH))
				echo "->  ${TRANSDIR}/${PROJ_AR[$I]}_WD"
			else
				echo "${PROJ_AR[$I]} -> ${VOBS_AR[$I]}"
				tput cuf ${#PROJ_AR[$I]}
				echo "->  ${TRANSDIR}/${PROJ_AR[$I]}_WD"
			fi
		done
	fi

	if ! [ -d "${TRANSDIR}" ]; then
		echo "Transdir [${TRANSDIR}] not existing. Creating..."
		mkdir "${TRANSDIR}"
	fi

	PUSHD "${TRANSDIR}"
	for (( I=0; I < ${#PROJ_AR[@]}; I++)); do
		INTERDIR="${TRANSDIR}/${PROJ_AR[$I]}_WD"
		FINALDIR="${TRANSDIR}/${PROJ_AR[$I]}"
		mkdir -p "${INTERDIR}"
		mkdir -p "${FINALDIR}"
		
		echo "Moving to workdir [${INTERDIR}]..."
		PUSHD "${INTERDIR}"

		#Ability to move instead. If on same device, then much faster. TBD
		MF=$(main_feature "${VOBS_AR[$I]}")
		echo -e "Linking main feature [${MF}] from\\n"\
			"[${RIPDIR}] to\\n [${INTERDIR}]"
		time find "${RIPDIR}" -regextype posix-awk -regex '.*'${MF}'.*' \
			-exec ln -s '{}' . ';'

		echo "Removing any menu VOB (tossing it away, worthless)..."
		rm -f *0.VOB

		if [ "X${SKIP_AUTHORING}" == "Xno" ];then
			echo "=========================================="
			echo -e "Authoring starts from\\n [${INTERDIR}] to\\n [${FINALDIR}]"
			echo "=========================================="
			( time (
				VIDEO_FORMAT=pal dvdauthor \
					-t -o "${FINALDIR}" *.VOB
			) 2>&1 ) | grep -Ev '^WARN' || true
			# Even if allowing errors above, next step will fail because
			# An *.IFO file isn't created
			echo "=========================================="
			echo -e "Creating a TOC in [${FINALDIR}]"
			echo "=========================================="
			( time (
				VIDEO_FORMAT=pal dvdauthor \
					-T -o "${FINALDIR}"
			) 2>&1 ) | \
				grep -Ev 'Any uninterpretable gibberish you want to hide (eregex)'
			
			
		else
			echo "=========================================="
			echo -e "Authoring skipped, linking instead."
			echo -e "From\\n [${INTERDIR}] to\\n [${FINALDIR}]"
			echo "=========================================="
			mkdir ${FINALDIR}/VIDEO_TS
			find ${INTERDIR}  -type l -exec ln -s '{}' ${FINALDIR}/VIDEO_TS ';'
			#ln -Ts ${INTERDIR} ${FINALDIR}
		fi
		POPD

		SZ1=$(du --max-dept=0 -L "${INTERDIR}" | awk '{print $1}')
		SZ2=$(du --max-dept=0 -L "${FINALDIR}" | awk '{print $1}')
		ABS_DIFF=$(
			echo "
				if ($SZ1 > $SZ2) {
					$SZ1 - $SZ2
				} else {
					$SZ2 - $SZ1
				}" | bc)

		#Check sanity. Note: using modern bash syntax
		if [ $ABS_DIFF -gt $AUTOR_DIFFSZ_OK ]; then
			#Size differs too much. I.e. error detected.
			echo "Size differs too much after dvdauthor" 1>&2
		    echo "   abs($SZ1 - $SZ2) = $ABS_DIFF > $AUTOR_DIFFSZ_OK" 1>&2
			echo "Check logs. Directories used so far are kept as is" 1>&2
			echo "Check logs. Directories used so far are kept as is" 1>&2
			exit 1
		fi

		FINAL_FN="$(echo ${PROJ_AR[$I]} | sed -e 's/ /_/g')".mp4
		#Consider optionlize MUVIDIR
		MUVIDIR=${MUVIDIR-${TRANSDIR}}
	
		PUSHD "${FINALDIR}"

		echo "=========================================="
		echo -e "Transcoding starts from\\n [${FINALDIR}] to\\n"\
			"[{${MUVIDIR}/${FINAL_FN}}]"
		echo "=========================================="
		time ffmpeg -i "concat:$(echo VIDEO_TS/*.VOB|tr \  \|)" \
			$THREADS $SLANG $FF_EXTRA ${MUVIDIR}/${FINAL_FN}

		POPD

		# If we read this far (i.e. no errors caught) then it should be OK
		# to concider removing intermediate directories and also to move the
		# source dir into "done" directory
		
		if [ "X${KEEP}" == "Xno" ]; then
			rm -rf "${INTERDIR}"
			rm -rf "${FINALDIR}"
		fi
	done
	POPD
}

source s3.ebasename.sh
if [ "$TC_SH" == $( ebasename $0 ) ]; then
	#Not sourced, do something with this.

	TC_SH_INFO="dvd.${TC_SH}"
	source .dvd.ui..tc.sh

	set -u
	set -e
	#set -x
	set -o pipefail

	echo "${TC_SH_INFO} started: $(date +"%D %T")"
	echo
	#time tc "$@"
	time tc_from_vobdir "$@"
	echo "${TC_SH_INFO} stopped: $(date +"%D %T")"
	play_tune alert
	RC=$?

	exit $RC
fi

fi
