# UI part of dvd.tc.sh
# This is not a complete script. It can't exist alone and it's is purely
# meant for being included into the main script. Reason for existence is to #
# keep main logic separated from ui, which for script3 scripts tend to be much
# more bloated than the main-code. In OOP lingo this is called MVC pattern
# (http://en.wikipedia.org/wiki/Model-view-controller)

source .s3..fonts.sh
source .s3..uifuncs.sh
source .dvd..funcs.sh

#Some defaults
TS=$(date +"%s")
DEF_PROJ="DVD_TMP_$TS"
DEF_ISO="dvd_1337.iso"
MF_MIN="dvd_1337.iso"
DEF_MF_MINSZ=1050000000
DEF_MF_MAXSZ=1150000000
DEF_MF_MIN=3
DEF_MF_MAX=6
DEF_COL1_WIDTH=20 #Any sane value. This is just for looks
DEF_THREADS=$(get_nr_cpu)

#Time-stamp, used for temp-file/dir names and for output filename if file is
#is already present. This Can be overloaded for debugging (see -T flag)
DEF_TMP_TS=$(date +"%s")

# Max difference in size in bytes after transcoding is done
# This is used to check is transcoding was successful or not
DEF_AUTOR_DIFFSZ_OK=1000000

#Options to be used for ffmpeg/avconv
DEF_FF_EXTRAALLT="${DEF_FF_EXTRAALLT} -acodec aac"
DEF_FF_EXTRAALLT="${DEF_FF_EXTRAALLT} -aq 100"
#DEF_FF_EXTRAALLT="${DEF_FF_EXTRAALLT} -ac 2"
#DEF_FF_EXTRAALLT="${DEF_FF_EXTRAALLT} -slang swe"
DEF_FF_EXTRAALLT="${DEF_FF_EXTRAALLT} -vcodec libx264"
DEF_FF_EXTRAALLT="${DEF_FF_EXTRAALLT} -vpre slow"
DEF_FF_EXTRAALLT="${DEF_FF_EXTRAALLT} -crf 24"
DEF_FF_EXTRA="${DEF_FF_EXTRA} -acodec copy"
DEF_FF_SLANG="swe"

#dvdauthor default VIDEO options
#DEF_DVDA_VOPS="720xfull+16:9"
#DEF_DVDA_VOPS="ntsc+16:9+720xfull"
#DEF_DVDA_VOPS="ntsc+16:9+720x480"
#DEF_DVDA_VOPS="${DEF_DVDA_VOPS},"		# Options for next track

#dvdauthor default AUDIO options
DEF_DVDA_AOPS="ac3+en"
#DEF_DVDA_AOPS="${DEF_DVDA_AOPS},"		# Options for next track

#dvdauthor default SUBPICTURE options
DEF_DVDA_SOPS="sv"
#DEF_DVDA_SOPS="${DEF_DVDA_SOPS},"		# Options for next track

function print_tc_help() {
	local CMD_STR="$(basename ${0})"

cat <<EOF
$(print_man_header)

$(echo -e ${FONT_BOLD}NAME${FONT_NONE})
        $CMD_STR - Transcoding made simple.

$(echo -e ${FONT_BOLD}SYNOPSIS${FONT_NONE})
        $(echo -e ${FONT_BOLD}${CMD_STR}${FONT_NONE} [options] [project])
        $(echo -e "${FONT_BOLD}${CMD_STR}${FONT_NONE}"\
            "[${FONT_BOLD}-d${FONT_NONE} rootdir]"\
            "[${FONT_BOLD}-i${FONT_NONE} isofile]"\
            "[${FONT_BOLD}-v${FONT_NONE}]"\
            "[${FONT_BOLD}-k${FONT_NONE}]"\
            "[project]")

$(echo -e ${FONT_BOLD}DESCRIPTION${FONT_NONE})
        $(echo -e "TC stands for ${FONT_BOLD}T${FONT_NONE}rans-${FONT_BOLD}C${FONT_NONE}ode")
        TC is is transcoding made simple. It will take either a iso-file or
        a directory with vob-files as input and and transcode it into mp4.
        Output will include main feature only (i.e. the movie), best audio
        stream and (predefined) subscripts (if possible).

$(echo -e ${FONT_BOLD}EXAMPLES${FONT_NONE})
        $(echo -e "${FONT_BOLD}${CMD_STR}${FONT_NONE}")
            $(echo -e "${FONT_UNDERLINE}Straight up${FONT_NONE}"\
            "with ${FONT_UNDERLINE}no arguments${FONT_NONE} and"\
            "${FONT_UNDERLINE}no options.${FONT_NONE}")

            Uses directory from where process is invoked as root directory
            for the project. Output is a ISO-file named properly and
            work-files are tidied away. Make sure you have at least 15G
            free space (process does not use temp-directory due to transfer
            penalty).

        $(echo -e "${FONT_BOLD}${CMD_STR} -d${FONT_NONE} rootdir")
            Uses rootdir as main rip-directory for the project. The
            project might or might not be a directory itself depending on
            settings, in which case this is the directory where the projects
            sub-directory will be. As the process handle very large
            data-files, usage of a temp directory is not an option. This
            directory is for all practical aspects that however.

            Default is to use the current directory as root. Make sure you
            have write permissions.

        $(echo -e "${FONT_BOLD}${CMD_STR} -t${FONT_NONE} transdir")
            Uses transdir as main destination-directory for transformations.

            Default is to use the current directory as root. Make sure you
            have write permissions.

        $(echo -e "${FONT_BOLD}${CMD_STR} -k${FONT_NONE} project
            Use project as project-name. This is the directory where the
            ${FONT_UNDERLINE}VOB-files${FONT_NONE} are kept. Since option ${FONT_BOLD}-k${FONT_NONE} is given, you can use this
            directory to get a feature from, either author or to transcode
            from")

$(echo -e ${FONT_BOLD}OVERVIEW${FONT_NONE})
        This program is meant to take the pain away from ripping DVD's and to
        avoid bloated GUI:s where all you do is doing the exact same thing
        every time, but there's still a big chance you miss something
        because you don't do it often enough. I.e. this script is
        particularly for those folks who $(echo -e ${FONT_BOLD}occasionally${FONT_NONE}) rip their own DVD.

        Instead of a bloated GUI with as much pain and headache making
        backups not worth the trouble, just insert a disc, invoke this command
        and out comes a nice ISO-file, named properly.

        This is a front-end for other command-line tools. Many of these
        tools are very flexible and inherently complex and difficult to use.
        (hence probably also why GUI:s are thought to be a must). From the
        point of view as to address the complexity of underlaying tools and
        layers, this script does not differ from the GUI:s. Where it differs
        is:

            1) It's further scriptable. You can use it with ease in your own
            scripts. For example for batch-ripping or various forms of
            auto-starts.

            2) It makes a best effort to finalize even when ripping fails
            due to a partly broken or worn DVD, or due to a new
            copy-protection. If it fails it will leave the VOB-files read so
            far intact, as in many cases they are still playable. With no
            menu and some fiddling with tracks, but still. Usually only
            some meta information is missing and mending the project into
            something usable isn't too hard.

            3) The project is meant to be able to be used with no parameters.
            It will assume, guess, analyze and/or detect most of what it
            needs to know. Bottom line: it's supposed to be \
$(echo -e ${FONT_BOLD}EASY${FONT_NONE}) to use.

            4) It does not need any graphics and barely any console at all.
            This script can be used in a completely head-less set-up, where
            ripping starts and completes with just the press of a button (by
            using the cradle eject button for example).

$(echo -e ${FONT_BOLD}DEFAULTS${FONT_NONE})
        ISO-files and/or residual traces of intermediate files (either
        intentional or non-intentional due to field rips or intentional
        due to settings) is the directory from where $CMD_STR is invoked.

$(echo -e ${FONT_BOLD}OPTIONS${FONT_NONE})
        Usually you don't need any options/flags when using $CMD_STR, but here
        are a few just to make those flag-Nazis happy:

    $(echo -e ${FONT_BOLD}General options${FONT_NONE})
        $(echo -e "${FONT_BOLD}-d${FONT_NONE} rootdir
            Use this directory as the root-dir to work in. This would
            typically be ${FONT_UNDERLINE}~/Videos${FONT_NONE} or similar.")

        $(echo -e "${FONT_BOLD}-i${FONT_NONE} isofile
            Final file-name will be packed info ${FONT_UNDERLINE}isofile${FONT_NONE}")

        $(echo -e "${FONT_BOLD}-S${FONT_NONE}
            Be ${FONT_UNDERLINE}silent${FONT_NONE}, i.e. Don't use acoustic"\
            "notifiers")

        $(echo -e "${FONT_BOLD}-t${FONT_NONE} transdir
            Use ${FONT_UNDERLINE}transdir${FONT_NONE} as destination directory"\
            "")

        $(echo -e "${FONT_BOLD}-k${FONT_NONE}
            ${FONT_UNDERLINE}Keep${FONT_NONE} the VOB-files which would normally be deleted")

        $(echo -e "${FONT_BOLD}-v${FONT_NONE}
            Be ${FONT_UNDERLINE}verbose${FONT_NONE}")

$(echo -e ${FONT_BOLD}AUTHOR${FONT_NONE})
        Written by Michael Ambrus.

$(echo -e ${FONT_BOLD}REPORTING BUGS${FONT_NONE})
        Report $CMD_STR bugs to bug-script3@gnu.org
        GNU coreutils home page: <http://www.gnu.org/software/script3/>
        General help using GNU software: <http://www.gnu.org/gethelp/>
        Report $CMD_STR translation bugs to <http://translationproject.org/team/>

$(echo -e ${FONT_BOLD}COPYRIGHT${FONT_NONE})
        Copyright 2013 Free Software Foundation, Inc. License GPLv3+: GNU GPL version 3 or
        later <http://gnu.org/licenses/gpl.html>.
        This is free software: you are free to change and redistribute it.\
$(echo -e ${FONT_BOLD}There  is  NO  WARRANTY,${FONT_NONE}\\n"\
        "to the extent permitted by law.)

$(echo -e ${FONT_BOLD}DISCLAMER${FONT_NONE})
        $(echo -e "${FONT_BOLD}IANAL${FONT_NONE} but ripping DVD:s which you
        don't hold copy-rights to without written permission is as of
        todays writing illegal by US law. Whether or not this law and the
        use-case which you intend to use tools like this is applicable in
        your country is ${FONT_BOLD}your responsibility${FONT_NONE} to check
        (or at least not the authors). AFAIK nothing prevents academic
        studies of this code, no even in the US. This code does not fall
        under ITAR")

$(echo -e ${FONT_BOLD}SEE ALSO${FONT_NONE})
        The  full  documentation  for $CMD_STR is maintained as a Texinfo
        manual. If the info and $CMD_STR programs are properly installed at
        your site, the command

              info script3 '$CMD_STR invocation'

       should give you access to the complete manual.

GNU script3 16.7.121-032bb              July 2013                $CMD_STR(7)
EOF
}

	ORIG_ARGS="$@"

	while getopts hd:i:zt:T:vkSmA:s: OPTION; do
		case $OPTION in
		h)
		if [ -t 1 ]; then
			print_tc_help $0 | less -R
		else
			print_tc_help $0
		fi
			exit 0
			;;
		d)
			RIPDIR=$OPTARG
			;;
		t)
			TRANSDIR=$OPTARG
			;;
		T)
			TMP_TS=$OPTARG
			;;
		z)
			SKIP_AUTHORING="yes"
			;;
		m)
			MOUNT_ISO="yes"
			;;
		i)
			ISO=$OPTARG
			;;
		A)
			AUDIO_MAP=$OPTARG
			;;
		s)
			SKIP_KB=$OPTARG
			;;
		S)
			SILENT="yes"
			;;
		v)
			VERBOSE="yes"
			;;
		k)
			KEEP="yes"
			;;
		?)
			echo "Syntax error:" 1>&2
		    echo "For help, type: $TC_SH_INFO -h" 1>&2
			exit 2
			;;

		esac
	done
	shift $(($OPTIND - 1))

	if [ $# -ge 0 ] && [ $# -le 1 ]; then
		echo "This is OK" > /dev/null
		if [ $# -gt 0 ]; then
			PROJECT=${PROJECT-${1}}
			PROJECT=${PROJECT%.iso}
			FILENAME=$1
		fi
	else
		echo "Syntax error: $TC_SH_INFO number of parameters" 1>&2
		echo "For help, type: $TC_SH_INFO -h" 1>&2
		exit 2
	fi

	RIPDIR=${RIPDIR-$(pwd)}
	RIPDIR=${RIPDIR%"/"}
	TRANSDIR=${TRANSDIR-$(pwd)}
	TRANSDIR=${TRANSDIR%"/"}
	PROJECT=${PROJECT-${DEF_PROJ}}
	TMP_TS=${TMP_TS-${DEF_TMP_TS}}
	ISO=${ISO-${DEF_ISO}}
	VERBOSE=${VERBOSE-"no"}
	KEEP=${KEEP-"no"}
	SILENT=${SILENT-"no"}
	FILENAME=${FILENAME-"no"}
	MOUNT_ISO=${MOUNT_ISO-"no"}

	MF_MINSZ=${MF_MINSZ-${DEF_MF_MINSZ}}
	MF_MAXSZ=${MF_MAXSZ-${DEF_MF_MAXSZ}}
	MF_MIN=${MF_MIN-${DEF_MF_MIN}}
	MF_MAX=${MF_MAX-${DEF_MF_MAX}}
	COL1_WIDTH=${COL1_WIDTH-${DEF_COL1_WIDTH}}

	SLANG=${SLANG-${DEF_FF_SLANG}}
	SLANG="-slang ${SLANG}"
	THREADS=${THREADS-${DEF_THREADS}}
	THREADS="-threads ${THREADS}"
	AUDIO_MAP=${AUDIO_MAP-""}
	SKIP_KB=${SKIP_KB-""}

	FF_EXTRA=${FF_EXTRA-${DEF_FF_EXTRA}}
	#FF_EXTRA="${FF_EXTRA-"${FF_EXTRAALLT} ${DEF_FF_EXTRA}"}"

	#dvdauthor options handling
	SKIP_AUTHORING=${SKIP_AUTHORING-"no"}
	AUTOR_DIFFSZ_OK=${AUTOR_DIFFSZ_OK-${DEF_AUTOR_DIFFSZ_OK}}
	set -e
	#VIDEO options
	DVDA_VOPS=${DVDA_VOPS="${DEF_DVDA_VOPS}"}
	if [ "X${DVDA_VOPS}" != "X" ]; then
		DVDA_VOPS="--video=${DVDA_VOPS}"
	fi

	#AUDIO options
	DVDA_AOPS=${DVDA_AOPS="${DEF_DVDA_AOPS}"}
	if [ "X${DVDA_AOPS}" != "X" ]; then
		DVDA_AOPS="--audio=${DVDA_AOPS}"
	fi

	#SUBPICTURE options
	DVDA_SOPS=${DVDA_SOPS="${DEF_DVDA_SOPS}"}
	if [ "X${DVDA_SOPS}" != "X" ]; then
		DVDA_SOPS="--subpictures=${DVDA_SOPS}"
	fi
	set +e

	#All categories combined
	DVDA_OPS="${DVDA_VOPS} ${DVDA_AOPS} ${DVDA_SOPS}"

