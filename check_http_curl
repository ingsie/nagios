#! /usr/bin/env bash

# nagios exit codes
declare -i STATE_OK=0
declare -i STATE_WARNING=1
declare -i STATE_CRITICAL=2
declare -i STATE_UNKNOWN=3

# initial curl parameters
CURL_PARAM=""

# http code expected for return code 0
CURL_EXPECTED="200"

# little help function
show_help() {
  cat >&2 << EOF
check_http_curl v0.0.1
Copyright (c) 2013 Moritz Rudert <helios@planetcyborg.de>

Usage:
$0 -u <uri> [-a auth] [-t <timeout>] [-e <expect>] [-4|-6]

Options:
 -h
  Print detailed help screen
 -4
  Use IPv4 connection
 -6
  Use IPv6 connection
 -e STRING
  expected statuscode for exit 0
 -u <uri>
  URL to GET
 -a AUTH_PAIR
  Username:password on sites with authentication
 -A STRING
  String to be sent in http header as "User Agent"
EOF

  [ -n "$1" ] && { echo >&2; echo "$1" >&2; }

  exit 1
}

# parsing commandline parameters
while getopts ":a:u:e:h46A:" opt; do
  case $opt in
    a)
      CURL_PARAM="$CURL_PARAM --anyauth -u $OPTARG"
    ;;
    u)
      CURL_URL="$OPTARG"
    ;;
    e)
      CURL_EXPECTED="$OPTARG"
    ;;
    h)
      show_help
    ;;
    4)
      CURL_PARAM="$CURL_PARAM -4"
    ;;
    6)
      CURL_PARAM="$CURL_PARAM -6"
    ;;
    A)
      CURL_PARAM="$CURL_PARAM -A $OPTARG"
    ;;
    \?)
      show_help "Invalid option: -$OPTARG"
    ;;
    :)
      show_help "Option -$OPTARG requires an argument."
    ;;
  esac
done

# if no URL to test specified, show help and exit
[ -z "$CURL_URL" ] && show_help "No URL defined!"
[ -x "$(which curl)" ] || show_help "curl not found!"

# curl magic
CURL_OUTPUT=($(curl -sSqm 10 -w "%{http_code}\\n%{size_download}\\n%{time_total}\\n" $CURL_PARAM "$CURL_URL" -o /dev/null --stderr -))

# if curl exited unexpected
if [ $? -ne 0 ]; then
  # unset unneeded elements of array
  for i in $(seq 0 3); do
    unset -v CURL_OUTPUT[$i]
  done

  echo "${CURL_OUTPUT[@]}"
  exit $STATE_CRITICAL
fi

# output
echo "${CURL_OUTPUT[0]} - ${CURL_OUTPUT[1]} bytes in ${CURL_OUTPUT[2]} seconds response time"
# HTTP WARNING: HTTP/1.1 401 Authorization Required - 734 bytes in 0.034 second response time |time=0.034063s;;;0.000000 size=734B;;;0

# ...and exit code
if [ "${CURL_OUTPUT[0]}" = "$CURL_EXPECTED" ]; then
  exit $STATE_OK
else
  exit $STATE_WARNING
fi
