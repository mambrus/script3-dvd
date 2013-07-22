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
FINAL_FN=""

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

#Error handler
function err_tc_from_iso_dvdcopy() {
	play_tune bad
	rm -rf $1
	echo "${TC_SH_INFO} stopped with error: $(date +"%D %T")"
}

# This method uses dvdcopy to get the main feature into a copy.
# It's probably safer, but can take around 6min extra per iso (depending on
# disk/bus-speeds) and uses about one full dvd in size exrta on disk for
# tempfiles. Experience show reading from mounts, if mount iso reside on
# usb-drive is actually slightly *slower* than reading in a copy extra.
# Therefore this variant is made default, but whichever is best probably
# depends on system used (note that threading does not affect as this
# currently only has an impact on ffmpeg (who works with authored copies
# anyway).
function tc_from_iso_dvdcopy() {
	TDIR=$(tmpname dvdcopydir)
	FINAL_FN=$(basename "${FILENAME}")
	FINAL_FN=$(echo ${FINAL_FN} | \
		sed -E 's/\.(ISO|iso)$//' | \
		sed -e 's/ /_/g')
	FINAL_FN="${FINAL_FN}.mp4"
	TDIR="${TDIR}_COPYDIR_${FINAL_FN}"

	add_on_err err_tc_from_iso_dvdcopy "$TDIR"
	
	echo -e "Copying main feature from \\n[$1] into \\n[$TDIR]"
	time dvdbackup -i "${1}" -p -F -o "${TDIR}"

	echo -e "Transcoding \\n[$1]..."
	time tc_from_vobdir "${TDIR}"
	rm -rf $TDIR
}

#Error handler
function err_tc_from_iso_mounted() {
	play_tune bad
	sudo umount "$1"
	rm -rf "$1"
	echo "${TC_SH_INFO} stopped with error: $(date +"%D %T")"
}

# Mount and read directly from loopback device. This requires the iso to be
# free from any copy-protection.
function tc_from_iso_mounted() {
	MOUNT=$(tmpname iso_mountpoint)
	FINAL_FN=$(basename "${FILENAME}")
	FINAL_FN=$(echo ${FINAL_FN} | \
		sed -E 's/\.(ISO|iso)$//' | \
		sed -e 's/ /_/g')
	FINAL_FN="${FINAL_FN}.mp4"
	MOUNT="${MOUNT}_MOUNT_${FINAL_FN}"
	
	add_on_err err_tc_from_iso_mounted "$MOUNT"

	echo "Creating mount-point [$MOUNT] ..."
	mkdir $MOUNT
	echo "Mounting mount-point [$MOUNT] ..."
	sudo mount -o loop $1 $MOUNT

	echo -e "Transcoding main feature \\n[$1] from \\n[$MOUNT]"
	time tc_from_vobdir "${MOUNT}"
	sudo umount $MOUNT
	rm -rf $MOUNT
}

function tc_from_iso() {
	if [ $MOUNT_ISO == "yes" ]; then
		tc_from_iso_mounted "$1"
	else
		tc_from_iso_dvdcopy "$1"
	fi
}

function tc_from_vobdir() {
	if [ $# -eq 1 ]; then
		VOBDIR="${1}"
	else
		VOBDIR="${RIPDIR}"
	fi

	get_vobs "${VOBDIR}"

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
		local TFINAL_FN=$(basename "${FILENAME}")
		ESUFFIX="${TFINAL_FN}_$(date +"%s")"
		INTERDIR="${TRANSDIR}/${PROJ_AR[$I]}_${ESUFFIX}_WD"
		FINALDIR="${TRANSDIR}/${PROJ_AR[$I]}_${ESUFFIX}"
		mkdir -p "${INTERDIR}"
		mkdir -p "${FINALDIR}"

		echo "Moving to workdir [${INTERDIR}]..."
		PUSHD "${INTERDIR}"

		#Ability to move instead. If on same device, then much faster. TBD
		MF=$(main_feature "${VOBS_AR[$I]}")
		echo -e "Linking main feature [${MF}] from\\n"\
			"[${VOBDIR}] to\\n [${INTERDIR}]"
		time find "${VOBDIR}" -regextype posix-awk -regex '.*'${MF}'.*' \
			-exec ln -s '{}' . ';'

		echo "Removing any menu VOB (tossing it away, worthless)..."
		rm -f *0.VOB

		if [ "X${SKIP_AUTHORING}" == "Xno" ];then
			echo "=========================================="
			echo -e "${FONT_BOLD}Authoring${FONT_NONE} starts"\
				"from\\n [${INTERDIR}] to\\n [${FINALDIR}]"
			echo -e "Setting options to be used:\\n"\
				"${FONT_BOLD}${DVDA_OPS}${FONT_NONE}"
			echo "=========================================="
			( time (
				VIDEO_FORMAT=pal dvdauthor \
					-t ${DVDA_VOPS} ${DVDA_AOPS} ${DVDA_SOPS} -o "${FINALDIR}" *.VOB
			) 2>&1 ) | grep -Ev '^WARN' || true #<-- Note: true
			# Even if allowing errors above, next step will fail because
			# An *.IFO file isn't created

			echo "=========================================="
			echo -e "Creating a TOC in [${FINALDIR}]"
			echo "=========================================="
			time VIDEO_FORMAT=pal dvdauthor \
					-T -o "${FINALDIR}" || signal_err
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
			signal_err
			exit 1
		fi

		FINAL_FN=${FINAL_FN-"$(echo ${PROJ_AR[$I]} | sed -e 's/ /_/g')".mp4}
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
	source futil.tmpname.sh

	set -u
	set -e
	#set -x
	set -o pipefail

	echo "${TC_SH_INFO} started: $(date +"%D %T")"
	echo
	EXT=$(
		echo "${FILENAME}" | \
		sed -E 's/.*\.//' | \
		tr '[[:lower:]]' '[[:upper:]]'
	)

	if [ "X${EXT}" == "XISO" ]; then
		# Iso image. Mount it, copy it, and transcode it
		time tc_from_iso "$@"
	else
		# Argument indicate directory. Assume vobs
		time tc_from_vobdir "$@"
	fi

	echo "${TC_SH_INFO} stopped: $(date +"%D %T")"
	play_tune alert
	RC=$?

	exit $RC
fi

fi
