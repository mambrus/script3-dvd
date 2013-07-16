# UI part of dvd.toiso.sh
# This is not a complete script. It can't exist alone and it's is purely
# meant for being included into the main script. Reason for existence is to #
# keep main logic separated from ui, which for script3 scripts tend to be much
# more bloated than the main-code. In OOP ling this is called MVC pattern
# (http://en.wikipedia.org/wiki/Model-view-controller)

source .s3..fonts.sh
source .s3..uifuncs.sh

function print_toiso_help() {
	local CMD_STR="$(basename ${0})"

cat <<EOF
$(print_man_header)

$(echo -e ${FONT_BOLD}NAME${FONT_NONE})
        $CMD_STR - $(echo -e \
            "converts a ${BG_RED}${FG_WHITE}${FONT_BLINK}movie-DVD${FONT_NONE}"\
            "into a playable/burnable ISO-image")

$(echo -e ${FONT_BOLD}SYNOPSIS${FONT_NONE})
        $(echo -e ${FONT_BOLD}${CMD_STR}${FONT_NONE} [options] [name])

$(echo -e ${FONT_BOLD}DESCRIPTION${FONT_NONE})
        Command line tool to transfer DVD-movies into ISO-images with as few
        options and as litte user interaction a possible.

$(echo -e ${FONT_BOLD}EXAMPLES${FONT_NONE})
        $(echo -e "${FONT_BOLD}${CMD_STR}${FONT_NONE}")
            $(echo -e "${FONT_UNDERLINE}Straight up${FONT_NONE}"\
            "with ${FONT_UNDERLINE}no arguments${FONT_NONE} and"\
            "${FONT_UNDERLINE}no options.${FONT_NONE}")

            Uses directory from where process is invoked as root directory
            for the project. Output is a ISO-file named properly and
            work-files are tidied away. make sure you have at least 15G
            free space (process does not use temp-directory due to transfer
            penalty).

        $(echo -e "${FONT_BOLD}${CMD_STR} -d${FONT_NONE} <root_dir>")
            Uses this directory as root directory for the project. The
            project might or might not be a directory itself depending on
            settings, in which case this is the directory where the projects
            sub-directory will be. As the process handle very large
            data-files, usage of a temp directory is not an option. This
            directory is for all practical aspects that however.

            Default is to use the current directory as root. Make sure you
            have write permissions.

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
        $(echo -e ${FONT_BOLD}-d${FONT_NONE} root_dir)

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

	while getopts hHD:R: OPTION; do
		case $OPTION in
		h)
		if [ -t 1 ]; then
			print_toiso_help $0 | less -R
		else
			print_toiso_help $0
		fi
			exit 0
			;;
		d)
			ROOT_DIR=$OPTARG
			;;
		?)
			echo "Syntax error:" 1>&2
			print_toiso_help $0 1>&2
			exit 2
			;;

		esac
	done
	shift $(($OPTIND - 1))

	if [ $# -ge 0 ] && [ $# -le 1 ]; then
		echo "This is OK"
	else
		echo "Syntax error: $TOISO_SH_INFO number of parameters" 1>&2
		echo "For help, type: $TOISO_SH_INFO -h" 1>&2
		exit 2
	fi

	ROOT_DIR=${ROOT_DIR-"./"}


