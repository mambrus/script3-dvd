#!/bin/bash
# Author: Michael Ambrus (ambrmi09@gmail.com)
# 2014-12-28
# This is the back-end for all dvd.*grep.sh tools. All it needs is a pattern
# in the envvar SRTT_PATTERN. If run as front-end, it will search for
# everything (which is basically equal to the normal egrep)

if [ -z $SRTT_SH ]; then

SRTT_SH="srtt.sh"


AWK_FTIME2SEC='
	function ftime2sec(ftime)
	{
		patsplit(ftime,a,/:/);
	}
'

function srtt_ftime2sec() {
	local FTIME=$1
}

function srtt_sec2ftime() {
	local SEC=$1
}

function srtt_pack() {
	local FNAME=$1
#	local TAWK "${AWK_FTIME2SEC}" '
#		/-->/{
#			print
#		}
#	'

	##cat $FNAME | awk "${TAWK}"

	cat $FNAME | awk '
		function ftime2sec(ftime)
		{
			sec=0;
			patsplit(ftime,a,/[:,]/,r);
			return 3600*r[0] + 60*r[1] + strtonum(r[2]"."r[3]);
		}

		function resetLogic()
		{
			L_INDEX=0;
			L_TIME=0;
			L_EMPTY=0;
			L_1=0;
			L_2=0;
		}

		function exitwerr()
		{
			print > /dev/stderr;
			print "Error: Format error detected" > /dev/stderr;
			fflush();
			exit(1);
		}

		BEGIN{
			resetLogic();
		}

		/*-- Subtext-line 1 & 2 --*/
		/^[[:print:]]+$/{
			if (L_INDEX && L_TIME)
			{
				if (!L_1) {
					L_1=1;
					printf("%s;",$0);
				} else if (!L_2) {
					L_2=1;
					printf("%s;",$0);
				}
			}
		}

		/*-- Index line --*/
		/^[0-9]+[[:space:]]*$/{
			if (L_INDEX || L_TIME || L_1 || L_2)
				exitwerr();

			L_INDEX=1;
			L_EMPTY=0;

			printf("%s;",$0);
		}

		/*-- Time line --*/
		/-->/{
			if (!L_INDEX || L_TIME || L_1 || L_2)
				exitwerr();

			L_TIME=1;
			printf("%f;%f;",ftime2sec($1),ftime2sec($3));
		}

		/*-- End line(s) --*/
		/^[[:space:]]*$/{
			if (L_EMPTY==0) {
				if (!L_1) {
					exitwerr();
				} else if (!L_2) {
					L_2=1;
					printf(";");
				}
				printf("\n");
			}
			resetLogic();
			L_EMPTY=1;
		}
	'
}

function srtt_unpack() {
	local FNAME=$1
}

function srtt() {
	local FNAME=$1

	srtt_pack $FNAME
}


source s3.ebasename.sh
if [ "$SRTT_SH" == $( ebasename $0 ) ]; then
	#Not sourced, do something with this.

	SRTT_SH_INFO=${SRTT_SH}
	source .dvd.ui..srtt.sh

	srtt "$@"

	exit $?
fi

fi
