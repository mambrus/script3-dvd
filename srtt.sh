#!/bin/bash
# Author: Michael Ambrus (ambrmi09@gmail.com)
# 2014-12-28

if [ -z $SRTT_SH ]; then

SRTT_SH="srtt.sh"

function srtt_pack() {
	local FNAME=$1

	cat $FNAME -- | dos2unix | \
		sed -e 's/\x92//g' -e 's/\x96//g'| \
		awk '
		function ftime2sec(ftime)
		{
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

		function exitwerr(phase)
		{
			print "Error: Format error detected: " phase
			print "In file ['$FNAME'], line number: "NR
			print "["$0"]"
			fflush();
			exit(1);
		}

		BEGIN{
			resetLogic();
			L_EMPTY=1;
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
				exitwerr("Index-line");
			
			if (!L_EMPTY)
				exitwerr("Index-line - Empty line (marker) has not occured");

			L_INDEX=1;
			L_EMPTY=0;

			printf("%s;",$0);
		}

		/*-- Time line --*/
		/-->/{
			if (!L_INDEX || L_TIME || L_1 || L_2)
				exitwerr("Time-line");

			L_TIME=1;
			printf("%f;%f;",ftime2sec($1),ftime2sec($3));
		}

		/*-- End line(s) --*/
		/^[[:space:]]*$/{
			if (L_EMPTY==0) {
				if (!L_1) {
					L_1=1;
					printf("%s;",$0);

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

	cat $FNAME -- | dos2unix | \
		sed -e 's/\x92//g' -e 's/\x96//g'| \
		awk -F";" '
		function sec2ftime(secs)
		{
			hrs=int(secs/3600);
			secs=secs-hrs*3600;

			mins=int(secs/60)
			secs=secs-mins*60;

			secs_int=int(secs);
			secs_frac=secs-secs_int;

			return sprintf("%02d:%02d:%02d,%03d",
				hrs,mins,secs_int,secs_frac*1000);

		}
		{
			print $1
			print sec2ftime($2)" --> "sec2ftime($3)
			print $4
			if (length($5) > 0)
				print $5
			printf("\n");
		}
	'
}

function srtt_adjust_time() {
	local M=$1
	local K=$2
	local FNAME=$3

	cat $FNAME -- | dos2unix | \
		sed -e 's/\x92//g' -e 's/\x96//g'| \
		awk -F";" \
		-v M=$M \
		-v K=$K '
		{
			T1=K*$2 + M;
			T2=K*$3 + M;
			printf("%d;%f;%f;%s;%s;\n",$1,T1,T2,$4,$5);
		}
		'
}

function srtt() {
	local FNAME=$1

	if [ $SRTT_DEBUG == "yes" ]; then
		echo "Intermediate files produced:" \
			"${SRTT_TMP_NAME}_[0-3] ..." 1>&2

		cat $FNAME -- | dos2unix > ${SRTT_TMP_NAME}_0
		srtt_pack ${SRTT_TMP_NAME}_0 > ${SRTT_TMP_NAME}_1
		srtt_adjust_time $SRTT_M $SRTT_K ${SRTT_TMP_NAME}_1 > \
			${SRTT_TMP_NAME}_2
		srtt_unpack ${SRTT_TMP_NAME}_2 | tee ${SRTT_TMP_NAME}_3
	else
		srtt_pack $FNAME | \
			srtt_adjust_time $SRTT_M $SRTT_K | \
			srtt_unpack
	fi
}


source s3.ebasename.sh
if [ "$SRTT_SH" == $( ebasename $0 ) ]; then
	#Not sourced, do something with this.

	SRTT_SH_INFO=${SRTT_SH}
	source .dvd.ui..srtt.sh
	set -o pipefail

	if ! [ -f "${1}" ]; then
		echo "No such file: ${1}" 1>&2
		exit 1
	fi
	if ! [ -f "${1}.orig" ]; then
		if [ $SRTT_DEBUG == "yes" ]; then
			echo "A backup-copy of the original file (${1}.orig) is missing." 1>&2
			echo "Creating a backup copy in the same directory..." 1>&2
		fi
		cp ${1} ${1}.orig
		chmod a-w ${1}.orig
	fi

	if [ $SRTT_TRELATIVE == "original" ]; then
		FNAME="${1}.orig"
	else
		FNAME="${1}"
	fi

	srtt "${FNAME}" > "${DEF_TMP_NAME}_out" && \
		mv "${DEF_TMP_NAME}_out" ${1}

	exit $?
fi

fi
