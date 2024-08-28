#!/bin/bash

# Define executables
_ECHO=echo
_BASENAME=basename
_CAT=cat
_CURL=curl
_WHICH=which
_GREP=grep
if [ -e /proj/ciexadm200/tools/bin/xmlstarlet ]; then
    _XMLSTARLET=/proj/ciexadm200/tools/bin/xmlstarlet
else
    _XMLSTARLET=xmlstarlet
fi
_XMLLINT=xmllint

SCRIPTNAME="$($_BASENAME $0)"

# Print usage instructions
function usage() {
    $_ECHO "Usage:"
    $_ECHO "${SCRIPTNAME} -h <host> -s <string> [-l] [-a <authtoken] [-v]"
    $_ECHO ""
    $_ECHO "Where:"
    $_ECHO "    -h    - Jenkins host"
    $_ECHO "    -a    - Source Jenkins authentication token"
    $_ECHO "    -s    - String to search for"
    $_ECHO "    -l    - Print job URL for matching jobs"
    $_ECHO "    -v    - Verbose output"
    $_ECHO
    $_ECHO "    <host> is the base URL of the Jenkins instance to examine"
    $_ECHO "        https://jenkins.lmera.ericsson.se/testjenkins"
    $_ECHO "    <string> is the string to search for."
    $_ECHO "    <authtoken> is the Jenkins authentication token in the format <username>:<token>"
    $_ECHO "        By default no authentication is used"
    $_ECHO "        The API token is available in your personal configuration page."
    $_ECHO "        Click your name on the top right corner on every page,"
    $_ECHO "        then click \"Configure\" to see your API token."
    $_ECHO "        Example: esignum:0123456789abcdef0123456789abcdef"
    $_ECHO
    $_ECHO "Example:"
    $_ECHO "    ${SCRIPTNAME} -h http://eselivm2v553l.lmera.ericsson.se:8080/jenkins \ "
    $_ECHO "    ${SCRIPTNAME//?/ } -s \"set-url\""
    $_ECHO
}

# Print error messages
function error() {
    ERR=$1
    shift
    case ${ERR} in
        0)  $_ECHO "[ERROR] ${SCRIPTNAME}: Failed to initialize Grid Engine environment."
            exit
            ;;
        1)  $_ECHO "[ERROR] ${SCRIPTNAME}: Unknown parameter: $1"
            ;;
        2)  $_ECHO "[ERROR] ${SCRIPTNAME}: Missing parameter: $1"
            ;;
        3)  $_ECHO "[ERROR] ${SCRIPTNAME}: Invalid base URL: $1"
            ;;
        4)  $_ECHO "[ERROR] ${SCRIPTNAME}: Unable to find: $1"
            exit
            ;;
        5)  $_ECHO "[ERROR] ${SCRIPTNAME}: Unable to retrieve configuration. HTTP response: $1"
            ;;
        *)  $_ECHO "[ERROR] Unknown error"
            $_ECHO ${ERR}
            $_ECHO $*
            ;;
    esac
    $_ECHO
    $_ECHO "Run '${SCRIPTNAME} -?' for help."
    exit ${ERR}
}

# Ensure xmlstarlet is available
$_WHICH $_XMLSTARLET >/dev/null
[ $? -ne 0 ] && error 4 $_XMLSTARLET

# Ensure xmllintt is available
$_WHICH $_XMLLINT >/dev/null
[ $? -ne 0 ] && error 4 $_XMLLINT

# Clean up any existing Jenkins error file.
[ -e jenkins_error.html ] && rm -f jenkins_error.html

# Check bash version
if [ ${BASH_VERSION:0:1} -lt 4 ]; then
    $_ECHO "[WARNING] ${SCRIPTNAME} needs bash version 4 or greater."
    $_ECHO "[WARNING] The current version of bash is ${BASH_VERSION}."
    $_ECHO "[WARNING]"
    $_ECHO "[WARNING] Attempting to run operation in Grid Engine..."
    $_ECHO
    if [ -f /opt/sge/current/bctgrid/common/settings.sh ]; then
        . /opt/sge/current/bctgrid/common/settings.sh
    else
        error 0
    fi
    qrsh -l OS=RHEL6.4 "$0 $*"
    exit
fi

# Process parameters
while [ "$1" != "" ]; do
    case ${1,,} in
        "-h"|"--host")
            HOST=${2%/}
            shift
            ;;
        "-s"|"--string")
            STRING=${2%}
            shift
            ;;
        "-a"|"--authorization")
            AUTH=$2
            shift
            ;;
        "-v"|"--verbose"|"-d"|"--debug")
            VERBOSE=1
            ;;
        "-l"|"--printurl")
            PRINTURL=1
            ;;
        "-?"|"-h"|"--help")
            usage
            exit
            ;;
        *)
            error 1 $1
            exit -1
            ;;
    esac
    shift
done

# Test required parameter values
[ -z "${HOST}" ] && error 2 "Source Jenkins host"
[ -z "${STRING}" ] && error 2 "Search string"

# Process optional parameter values
[ ! -z "${AUTH}" ] && AUTH="-u ${AUTH}"

# Validate and construct Jenkins base URLs for REST
URLPATTERN='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
if [[ ! ${HOST} =~ ${URLPATTERN} ]]; then
    error 3 "${HOST}"
fi

# Get job list
jobs=$($_CURL ${AUTH} -s "${HOST}/api/xml?xpath=/hudson/job&wrapper=jobs"   | \
       $_XMLLINT --format -                                                 | \
       $_XMLSTARLET sel -T -t -m "/jobs/job" -v "concat(name,',',color)" -n | \
       sed "s#,.*##"|grep "Release" )

for job in ${jobs}; do
    if [ ! -z ${VERBOSE} ]; then
        $_ECHO "[DEBUG] #### JOB ####"
        $_ECHO "[DEBUG] ${job}"
        $_ECHO "[DEBUG] #############"
    fi

    JOBURL="${HOST}/job/${job}/config.xml"

    # Retrieve source job configuration
    JOBCONFIG="$($_CURL -s ${AUTH} ${JOBURL})"

    # Prepare report string
    if [ ! -z ${PRINTURL} ]; then
        report="${job} (${JOBURL})"
    else
        report="${job}"
    fi

    # Search for String
    $_ECHO "${JOBCONFIG}" | $_GREP -q ${STRING}

    # Output result
    [ $? -eq 0 ] && echo ${report}  

done


