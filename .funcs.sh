#!/bin/bash

# Author: Michael Ambrus (ambrmi09@gmail.com)
# 2013-07-19
#
# Common functions for s3.dvd

if [ -z $DOT_FUNCS_SH ]; then

DOT_FUNCS_SH=".funcs.sh"

#Trap handling for SIGERR
declare -a on_err_items
function on_err()
{
    for i in "${on_err_items[@]}"
    do
        echo "on_err: $i"
        eval $i
    done
}

function add_on_err()
{
    local n=${#on_err_items[*]}
    on_err_items[$n]="$*"
    if [[ $n -eq 0 ]]; then
        echo "Setting trap"
        trap on_err ERR
    fi
}
# Work-around traps limitations in loops e.t.a.
# Use like this:
# sonething_that_fails || signal_error
function signal_err() {
	echo "Fake trap invoked" 1>&2
	on_err
	false
}

#Play a notification tune
function play_tune() {
	if [ "X${SILENT}" == "Xno" ]; then
		local PLAY=$(\
			which play && \
			play ${HOME}/bin/.dvd..${1}.wav >/dev/null 2>&1 \
		)
	fi
}

function get_nr_cpu() {
	 cat /proc/cpuinfo | grep processor | wc -l
}

function PUSHD() {
	#VERBOSE=""
	if [ "X${VERBOSE}" == "X" ]; then
		pushd "${1}"
		echo "======================================="
		pwd
		echo "======================================="
		echo
	elif [ "X${VERBOSE}" == "Xyes" ]; then
		echo -n "-> Changing directory [to from]: "
		#echo $(pushd "${1}" | sed -e 's/ /\n/' | tail -n2)
		read RC < <(pushd "${1}")
		echo
		echo "======================================="
		pwd
		echo "======================================="
		echo
	else
		pushd "${1}" >/dev/null
	fi
}

function POPD() {
	if [ "X${VERBOSE}" == "X" ]; then
		popd
	elif [ "X${VERBOSE}" == "Xyes" ]; then
		echo -n "<- Changing back [to]: "
		echo $(popd | sed -e 's/ /\n/' | head -n1)
	else
		popd >/dev/null
	fi
}

source s3.ebasename.sh
if [ "$DOT_FUNCS_SH" == $( ebasename $0 ) ]; then
	#Not sourced, do something with this.

	echo "Error: This file is meant to be sourced only" 1>&2
	exit 1
fi

fi
