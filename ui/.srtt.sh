# UI part of all srtt tool
# This is not even a script, stupid and can't exist alone. It is purely
# meant for being included.

DEF_OFFS="0.0"
DEF_GAIN="1.0"
DEF_ZERO="0.0"

function print_help() {
			cat <<EOF
Usage: $SRTT_SH_INFO [options] filname

Examples:
  $SRTT_SH_INFO -o12.34 myfile.srt

Options:
  -o seconds  Offset to add in seconds. If to subtract, seconds should be
              a negative value. Default offset is $DEF_OFFS.
  -g gain     Gain to apply (or slew). Default gain is $DEF_GAIN.
  -z time     Zero time. Default zero-time is $DEF_ZERO.


EOF
}
	while getopts ho:g:z: OPTION; do
		case $OPTION in
		h)
			print_help $0
			exit 0
			;;
		o)
			SRTT_OFFS="${OPTARG}"
			;;
		g)
			SRTT_GAIN="${OPTARG}"
			;;
		z)
			SRTT_ZERO="${OPTARG}"
			;;
		?)
			echo "Syntax error:" 1>&2
			print_help $0 1>&2
			exit 2
			;;

		esac
	done
	shift $(($OPTIND - 1))

	if [ $# -ne 1 ]; then
		echo "Syntax error:" \
			"$SRTT_SH_INFO number of arguments should be exactly one:" \
			"regexp_pattern" 1>&2
		echo "For help, type: $SRTT_SH_INFO -h" 1>&2
		exit 2
	fi


	SRTT_OFFS=${SRTT_OFFS-$DEF_OFFS}
	SRTT_GAIN=${SRTT_GAIN-$DEF_GAIN}
	SRTT_ZERO=${SRTT_ZERO-$DEF_ZERO}


