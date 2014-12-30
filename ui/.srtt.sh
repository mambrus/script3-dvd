# UI part of all srtt tool
# This is not even a script, stupid and can't exist alone. It is purely
# meant for being included.

DEF_OFFS="0.0"
DEF_GAIN="1.0"
DEF_INV="yes"
DEF_TMP_NAME="/tmp/${SRTT_SH_INFO}_inter"

function print_srtt_help() {
			cat <<EOF
NAME
        $SRTT_SH_INFO - Adjust time-stamps in Matroska sub-text files

SYNOPSIS
        $SRTT_SH_INFO [options] filname

DESCRIPTION
        $SRTT_SH_INFO parses srt-files. It understands the srt format and
        reads-modifies-write time-stamps according to the line equation:
        y = kx + m.

    Calibration
        If y is the time each subtext appearers for the time x for each
        corresponding spoken line. With two calibration points, preferably
        spread far from each other, we can calculate k and m as follows:

             y[2]*x[1] - y[1]*x[2]
        m = ----------------------
                  x[1] - x[2]


             y[1] - m
        k = -----------
               x[1]

        Where:
           [1] is the first  calibration point for {x,y}
           [2] is the second calibration point for {x,y}

        k,m can then be passed using the corresponding options below.
        Alternatively $SRTT_SH_INFO can calculate {k,m} for you, provided
        the calibration points {{x,y}[1], {x,y}[2]} are given instead. See
        "Assisted operation options" below.

EXAMPLES
        $SRTT_SH_INFO -m12.34 myfile.srt

OPTIONS

    Assisted operation options
        TBD

    Raw operation options
        -m seconds  Offset to add in seconds. If to subtract, seconds should
                    be a negative value. Default offset is $DEF_OFFS.
        -k gain     Gain to apply (or slew). Default gain is $DEF_GAIN.

    Debugging and verbosity options
        -d          Output additional debugging info.
        -T name     Prefix of intermediate files, suffix number is appended
                    depending on order. Default is $DEF_TMP_NAME

                    Intermediate files are not used in normal operation.
                    They are produced on demand only and are be used for
                    tracing transformation errors.

AUTHOR
        Written by Michael Ambrus.

EOF
}
	while getopts hm:k:dt: OPTION; do
		case $OPTION in
		h)
			if [ -t 1 ]; then
				print_srtt_help $0 | less -R
			else
				print_srtt_help $0
			fi
			exit 0
			;;
		m)
			if [ "X${SRTT_OPMODE}" == "Xassisted" ]; then
				echo "Syntax error: Mutually exlusive options used" 1>&2
				echo "For help, type: $SRTT_SH_INFO -h" 1>&2
				exit 3
			fi
			SRTT_OPMODE="raw"
			SRTT_OFFS_0="${OPTARG}"
			;;
		k)
			if [ "X${SRTT_OPMODE}" == "Xassisted" ]; then
				echo "Syntax error: Mutually exlusive options used" 1>&2
				echo "For help, type: $SRTT_SH_INFO -h" 1>&2
				exit 3
			fi
			SRTT_OPMODE="raw"
			SRTT_GAIN_0="${OPTARG}"
			;;
		d)
			SRTT_DEBUG="yes"
			;;
		t)
			DEBUG="yes"
			SRTT_TMP_NAME="${OPTARG}"
			;;
		?)
			echo "Syntax error: options" 1>&2
			echo "For help, type: $SRTT_SH_INFO -h" 1>&2
			exit 2
			;;

		esac
	done
	shift $(($OPTIND - 1))

	if [ $# -ne 1 ]; then
		echo "Syntax error: arguments" \
			"$SRTT_SH_INFO number of arguments should be exactly one:" \
			"input filename" 1>&2
		echo "For help, type: $SRTT_SH_INFO -h" 1>&2
		exit 2
	fi

#Actuating defaults if needed
	SRTT_INV=${SRTT_INV-$DEF_INV}
	SRTT_OFFS_0=${SRTT_OFFS_0-$DEF_OFFS}
	SRTT_GAIN_0=${SRTT_GAIN_0-$DEF_GAIN}
	SRTT_DEBUG=${SRTT_DEBUG-"no"}
	SRTT_TMP_NAME=${SRTT_TMP_NAME-$DEF_TMP_NAME}
	SRTT_OPMODE=${SRTT_OPMODE-"raw"}
	
	if [ $SRTT_INV == "yes" ]; then
		SRTT_OFFS=$(echo ${SRTT_OFFS_0} | awk '{print -1.0*$1}')
		SRTT_GAIN=$(echo ${SRTT_GAIN_0} | awk '{print  1.0/$1}')
	else
		SRTT_OFFS=${SRTT_OFFS_0}
		SRTT_GAIN=${SRTT_GAIN_0}
	fi

	if [ $SRTT_DEBUG == "yes" ]; then
		exec 3>&1 1>&2
		echo "Variables:"
		echo "  SRTT_INV=$SRTT_INV"
		echo "  SRTT_OFFS_0=$SRTT_OFFS_0"
		echo "  SRTT_GAIN_0=$SRTT_GAIN_0"
		echo "  SRTT_OFFS=$SRTT_OFFS"
		echo "  SRTT_GAIN=$SRTT_GAIN"
		echo "  SRTT_DEBUG=$SRTT_DEBUG"
		echo "  SRTT_TMP_NAME=$SRTT_TMP_NAME"
		echo "  SRTT_OPMODE=$SRTT_OPMODE"
		echo
		exec 1>&3 3>&-
	fi


