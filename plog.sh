#!/bin/bash

LOG=./log.txt
if [ -t 1 ]; then
	#echo "Please wait..." 1>&2
	cat ${LOG} | \
		sed -E 's/.*Copying (.*)(, part .*)*: [0-9]% done.*/>>Copying \1\2\n/' | \
		sed -E 's/.*STAT: (.*)/>>STAT: \1\n/' | sed -E 's/[[:cntrl:]]/\n/g' | \
		cat --number | \
		awk \
		'/frame=.* fps=.* q=.* size= .*kB time=.* bitrate=.*kbits\/s/{
			if (!r1){print $0}; r1=1; p=1
		}{
			if (!p){ print ""$0; r1=0}; p=0;
		}' | tac | less
else
	cat ${LOG} | \
		sed -E 's/.*Copying (.*)(, part .*)*: [0-9]% done.*/>>Copying \1\2\n/' | \
		sed -E 's/.*STAT: (.*)/>>STAT: \1\n/' | sed -E 's/[[:cntrl:]]/\n/g' | \
		cat --number | \
		awk \
		'/frame=.* fps=.* q=.* size= .*kB time=.* bitrate=.*kbits\/s/{
			if (!r1){print $0}; r1=1; p=1
		}{
			if (!p){ print ""$0; r1=0}; p=0;
		}' | tac
fi
