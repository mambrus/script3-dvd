# UI part of all srtt tool
# This is not even a script, stupid and can't exist alone. It is purely
# meant for being included.

DEF_M="0.0"
DEF_K="1.0"
DEF_INV="yes"
DEF_TMP_NAME="/tmp/${SRTT_SH_INFO}_inter"
DEF_TRELATIVE="original"

function srtt_ftime2sec() {
	local FTIME=$1

	echo $FTIME | awk '
		function ftime2sec(ftime)
		{
			patsplit(ftime,a,/[:,]/,r);
			return 3600*r[0] + 60*r[1] + strtonum(r[2]"."r[3]);
		}
		{
			print ftime2sec($1)
		}
		'
}

function print_srtt_help() {
			cat <<EOF
NAME
        $SRTT_SH_INFO - Adjust time-stamps in Matroska sub-text files

SYNOPSIS
        $SRTT_SH_INFO [options] filename

DESCRIPTION
        $SRTT_SH_INFO parses srt-files. It understands the srt format and
        reads-modifies-write time-stamps according to the line equation:
        y = kx + m.

    Calibration
        If y is the time each subtext appearers for the time x for each
        corresponding spoken line. With two calibration points: preferably
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

        Formulae with constants inserted describe how the error is
        generated. We actually need the inverse, but $SRTT_SH_INFO will
        calculate that for you.

        k,m can now be passed using the corresponding options. See "Raw
        operation options" below.

    Assisted operation
        $SRTT_SH_INFO can calculate {k,m} automatically provided two
        calibration points {{x,y}[1], {x,y}[2]} are given. Note that this
        operation is mutually exclusive from the raw (y = kx +m) operation.
        If one point is given, all must be given.

        All {x,y}[1,2] are times and are expressed as formatted time
        (ftime) following a non-locale format as follows:

        HH:MM:SS(,milli)

        See "Assisted operation options" under OPTIONS for how to set
        {x,y}[1,2].

EXAMPLES
        $SRTT_SH_INFO -m12.34 myfile.srt

OPTIONS

    General options
        -I          Time adjustments are incremental. I.e.
                    adjustment/calibration options apply relative last
                    output and not relative original time-stamps. Default:
                    $DEF_TRELATIVE

    Assisted operation options
        -x ftime    x[1]: Speech time for the first calibration point
        -y ftime    y[1]: Text time for the first calibration point
        -X ftime    x[2]: Speech time for the second calibration point
        -Y ftime    y[2]: Text time for the second calibration point

    Raw operation options
        -m seconds  Offset to add in seconds. If to subtract, seconds should
                    be a negative value.
                    Hint: If the text shows up too early, the sign in
                    seconds should be negative. If the text comes too late,
                    the sign in seconds should be positive (no sign).
                    Default offset is $DEF_M.
        -k gain     Gain to apply (or slew). Default gain is $DEF_K.

    Debugging and verbosity options
        -d          Output additional debugging info and additional verbosity
        -T name     Prefix of intermediate files, suffix number is appended
                    depending on order. Default is $DEF_TMP_NAME

                    Intermediate files are not used in normal operation.
                    They are produced on demand only and are be used for
                    tracing transformation errors.
OPERATION

    In file-operation mode, note that UID needs to have write access both to
    the file being altered and to the directory where it's stored.

    Getting good adjustments is easiest to accomplish if one begins without
    the -I option, i.e. for (repeated) coarse calibration. Then continue
    with -I option for final touch-ups.

    Note that the original time-stamps are never lost (provided time-stamps
    have been manipulated by $SRTT_SH_INFO). If restarting a relative
    adjustment series is needed: To restore a .srt file, re-run
    $SRTT_SH_INFO without options.

    Hints:

        Wether to use "Assisted operation" or "Raw operation" depends on
        your mileage. But in general, check if only offset adjustment is
        needed first. And:

        * If one determines that only offset adjustment is needed, use "Raw
          operation", i.e. pass -m without either -k or -{x,y,X,Y}.

          This is a good rule-of-thumb regardless of offset original or
          offset incremental (see -I flag) is used.  Determining if only a
          constant offset is needed is done by inspecting offset in the
          beginning and in the end of a film. Rough estimation is enough. If
          difference in offsets is small relative the distance between the
          two measuring points, there is no need for slew compensation.

        * If one determines that slew compensation is also needed, use
          "Assisted operation", i.e. pass options -{x,y,X,Y}.

          Using "Raw operation" in this case is generaly too hard without
          the help of a calculator.

AUTHOR
        Written by Michael Ambrus, 29 Dec 2014

EOF
}
	while getopts hm:k:dt:x:y:X:Y:I OPTION; do
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
				echo "Syntax error: Mutually exclusive options used" 1>&2
				echo "For help, type: $SRTT_SH_INFO -h" 1>&2
				exit 3
			fi
			SRTT_OPMODE="raw"
			SRTT_M_0="${OPTARG}"
			;;
		k)
			if [ "X${SRTT_OPMODE}" == "Xassisted" ]; then
				echo "Syntax error: Mutually exclusive options used" 1>&2
				echo "For help, type: $SRTT_SH_INFO -h" 1>&2
				exit 3
			fi
			SRTT_OPMODE="raw"
			SRTT_K_0="${OPTARG}"
			;;
		I)
			SRTT_TRELATIVE="last"
			;;
		[x,y,X,Y])
			if [ "X${SRTT_OPMODE}" == "Xraw" ]; then
				echo "Syntax error: Mutually exclusive options used" 1>&2
				echo "For help, type: $SRTT_SH_INFO -h" 1>&2
				exit 3
			fi
			SRTT_OPMODE="assisted"
			case $OPTION in
			x)
				FX1="${OPTARG}"
				;;
			y)
				FY1="${OPTARG}"
				;;
			X)
				FX2="${OPTARG}"
				;;
			Y)
				FY2="${OPTARG}"
				;;
			esac
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

	if [ "X$SRTT_OPMODE" == "Xassisted" ]; then
		if 	[ "X${FX1}" == "X" ] || \
			[ "X${FY1}" == "X" ] || \
			[ "X${FX2}" == "X" ] || \
			[ "X${FY2}" == "X" ]
		then

			echo "Syntax error: missing option(s)" 1>&2
			echo "  $SRTT_SH_INFO requires that if one of x,y,X,Y are given," \
				"all should be given." 1>&2
			echo "For help, type: $SRTT_SH_INFO -h" 1>&2
			exit 4
		fi

		X1=$(srtt_ftime2sec ${FX1})
		Y1=$(srtt_ftime2sec ${FY1})
		X2=$(srtt_ftime2sec ${FX2})
		Y2=$(srtt_ftime2sec ${FY2})

		SRTT_M_0=$(awk "BEGIN{print ($Y2* $X1-$Y1* $X2)/($X1- $X2)}" )
		SRTT_K_0=$(awk "BEGIN{print ($Y1- $SRTT_M_0)/ $X1}" )

	fi

#Actuating defaults if needed
	SRTT_INV=${SRTT_INV-$DEF_INV}
	SRTT_M_0=${SRTT_M_0-$DEF_M}
	SRTT_K_0=${SRTT_K_0-$DEF_K}
	SRTT_DEBUG=${SRTT_DEBUG-"no"}
	SRTT_TMP_NAME=${SRTT_TMP_NAME-$DEF_TMP_NAME}
	SRTT_OPMODE=${SRTT_OPMODE-"raw"}
	SRTT_TRELATIVE=${SRTT_TRELATIVE-$DEF_TRELATIVE}

	if [ $SRTT_INV == "yes" ]; then
		SRTT_M=$(awk "BEGIN{print (-1.0*$SRTT_M_0)/$SRTT_K_0}")
		SRTT_K=$(awk "BEGIN{print  1.0/$SRTT_K_0}")
	else
		SRTT_M=${SRTT_M_0}
		SRTT_K=${SRTT_K_0}
	fi

	if [ $SRTT_DEBUG == "yes" ]; then
		exec 3>&1 1>&2
		echo "Variables:"
		echo "  SRTT_OPMODE=$SRTT_OPMODE"
		echo "  SRTT_TRELATIVE=$SRTT_TRELATIVE"
		echo "  SRTT_DEBUG=$SRTT_DEBUG"
		echo "  SRTT_TMP_NAME=$SRTT_TMP_NAME"
		echo "  FX1=$FX1"
		echo "  FY1=$FY1"
		echo "  FX2=$FX2"
		echo "  FY2=$FY2"
		echo "  X1=$X1"
		echo "  Y1=$Y1"
		echo "  X2=$X2"
		echo "  Y2=$Y2"
		echo "  SRTT_INV=$SRTT_INV"
		echo "  SRTT_M_0=$SRTT_M_0"
		echo "  SRTT_K_0=$SRTT_K_0"
		echo "  SRTT_M=$SRTT_M"
		echo "  SRTT_K=$SRTT_K"
		echo
		exec 1>&3 3>&-
	fi

