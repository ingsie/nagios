#! /usr/bin/env bash
#
# USAGE:
# ./check_hddtemp.sh <device> <warn> <crit>
# Nagios script to get the temperatue of HDD from hddtemp
#
# You may have to let nagios run this script as root
# This is how the sudoers file looks in my debian system:
# nagios  ALL=(root) NOPASSWD:/usr/lib/nagios/plugins/check_hddtemp.sh
#
# Version 1.0

declare -i STATE_OK=0
declare -i STATE_WARNING=1
declare -i STATE_CRITICAL=2
declare -i STATE_UNKNOWN=3

function usage() {
	echo "Usage: ./check_hddtemp.sh <device> <warn> <crit>"
}

function check_root() {
	# make sure script is running as root
	if [ `whoami` != root ]; then
		echo "UNKNOWN: please make sure script is running as root"
		exit $STATE_UNKNOWN
	fi
}

function check_arg() {
	# make sure you supplied all 3 arguments
	if [ $# -ne 3 ]; then
		usage
		exit $STATE_OK
	fi
}

function check_device() {
	# make sure device is a special block
	if [ ! -b "$DEVICE" ];then
		echo "UNKNOWN: $DEVICE is not a block special file"
		exit $STATE_UNKNOWN
	fi
}

function check_warn_vs_crit() {
	# make sure CRIT is larger than WARN
	if [ $WARN -ge $CRIT ];then
		echo "UNKNOWN: WARN value may not be greater than or equal the CRIT value"
		exit $STATE_UNKNOWN
	fi
}

function init() {
	check_root
	check_arg $*
	check_device
	check_warn_vs_crit
}

function get_hddtemp() {
	# gets temperature and stores it in $HEAT
	# and make sure we get a numeric output
	if [ -x $HDDTEMP ];then
		INTERFACE="sat"
		case "$DEVICE" in
		*:*)
			INTERFACE="$(echo "$DEVICE" | cut -d: -f1)"
			DEVICE="$(echo "$DEVICE" | cut -d: -f2)"
			;;
		esac
		HEAT="$($HDDTEMP -d "$INTERFACE" -A "$DEVICE" | awk '/Temperature_Celsius/ && ! / 0$/ { print $10 }')"
		case "$HEAT" in
		[0-9]* )
			echo "do nothing" > /dev/null
			;;
		* )
			echo "OK: Could not get temperature from: $DEVICE"
			exit $STATE_OK
			;;
		esac
	else
		echo "UNKNOWN: cannot execute $HDDTEMP"
		exit $STATE_UNKNOWN
	fi
}

function check_heat() {
	code=$STATE_OK
	# checks temperature and replies according to $CRIT and $WARN
	if [ $HEAT -lt $WARN ];then
		echo -n "OK: Temperature is below warn treshold ($DEVICE is $HEAT)"
	elif [ $HEAT -lt $CRIT ];then
		echo -n "WARNING: Temperature is above warn treshold ($DEVICE is $HEAT)"
		code=$STATE_WARNING
	else
		echo -n "CRITICAL: Temperature is above crit treshold ($DEVICE is $HEAT)"
		code=$STATE_CRITICAL
	fi
	echo "|temperature=$HEAT;$WARN;$CRIT"
	exit $code
}

# -- Main -- #

HDDTEMP=/usr/sbin/smartctl
DEVICE=$1
WARN=$2
CRIT=$3

init $*
get_hddtemp
check_heat
