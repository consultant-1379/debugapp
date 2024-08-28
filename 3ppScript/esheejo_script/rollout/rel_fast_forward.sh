#!/bin/bash

# Define executables
_ECHO=echo
_BASENAME=basename
_CAT=cat
_CURL=curl
_WHICH=which
if [ -e /proj/ciexadm200/tools/bin/xmlstarlet ]; then
    _XMLSTARLET=/proj/ciexadm200/tools/bin/xmlstarlet
else
    _XMLSTARLET=xmlstarlet
fi
SCRIPTNAME="$($_BASENAME $0)"

# Print usage instructions
function usage() {
    $_ECHO "Usage:"
    $_ECHO "${SCRIPTNAME} -h <host> -j <jobname> [-a <authtoken>]"
    $_ECHO ""
    $_ECHO "Where:"
    $_ECHO "    -h    - Jenkins host"
    $_ECHO "    -j    - Jenkins job name"
    $_ECHO "    -a    - Jenkins authentication token"
    $_ECHO "    -v    - Verbose output"
    $_ECHO
    $_ECHO "    <host> is the base URL of the Jenkins instance to copy from/to"
    $_ECHO "        https://jenkins.lmera.ericsson.se/testjenkins"
    $_ECHO "    <jobname> is the name of the Jenkins job to create"
    $_ECHO "        By default the last part of the gerrit project is used to name the Jenkins job."
    $_ECHO "    <authtoken> is the Jenkins authentication token in the format <username>:<token>"
    $_ECHO "        By default no authentication is used"
    $_ECHO "        The API token is available in your personal configuration page."
    $_ECHO "        Click your name on the top right corner on every page,"
    $_ECHO "        then click \"Configure\" to see your API token."
    $_ECHO "        Example: esignum:0123456789abcdef0123456789abcdef"
    $_ECHO
    $_ECHO "Example:"
    $_ECHO "    ${SCRIPTNAME} -h http://eselivm2v553l.lmera.ericsson.se:8080/jenkins \ "
    $_ECHO "    ${SCRIPTNAME//?/ } -j MyOldJob_Release                                    \ "
    $_ECHO "    ${SCRIPTNAME//?/ } -a esignum:0123456789abcdef0123456789abcdef"
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
        4)  $_ECHO "[ERROR] ${SCRIPTNAME}: Unable to find xmlstarlet"
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
[ $? -ne 0 ] && error 4

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
        "-j"|"--job")
            JOB=$2
            shift
            ;;
        "-a"|"--authorization")
            AUTH=$2
            shift
            ;;
        "-v"|"--verbose"|"-d"|"--debug")
            VERBOSE=1
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
[ -z "${HOST}" ] && error 2 "Jenkins host"
[ -z "${JOB}" ] && error 2 "Job name"

# Process optional parameter values
[ ! -z "${AUTH}" ] && AUTH="-u ${AUTH}"

# Validate and construct Jenkins base URLs for REST
URLPATTERN='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
if [[ ${HOST} =~ ${URLPATTERN} ]]; then
    JOBURL="${HOST}/job/${JOB}/config.xml"
else
    error 3 "${HOST}"
fi

# Retrieve job configuration
JOBCONFIG=$($_CURL -s ${AUTH} ${JOBURL})

# Extract parameters
PREBUILD=$($_ECHO ${JOBCONFIG} | $_XMLSTARLET sel -t -m '/*/scm/branches/hudson.plugins.git.BranchSpec' -v . -n)
#POSTBUILD=$($_ECHO ${JOBCONFIG} | $_XMLSTARLET sel -t -m '/*/postbuilders/hudson.tasks.Shell/command' -v . -n)

# Check if we got any configuration data
#if [[ -z "${DISABLED}" ]]; then
#    # Get HTTP response code if we didn't
#    HTTP_RESPONSE=$($_CURL -s -o /dev/null -I -w "%{http_code}" ${AUTH} ${JOBURL})
#    [ "${HTTP_RESPONSE}" != "200" ] && error 5 ${HTTP_RESPONSE}
#fi

if [ ! -z ${VERBOSE} ]; then
    $_ECHO "[DEBUG] ############ JENKINS HOST ##############"
    $_ECHO "[DEBUG] ${HOST}"
    $_ECHO "[DEBUG] ############## JOB NAME ################"
    $_ECHO "[DEBUG] ${JOB}"
    $_ECHO "[DEBUG] ############# PREBUILD #################"
    $_ECHO "[DEBUG] ${PREBUILD}"
    $_ECHO "[DEBUG] ############# POSTBUILD ################"
 #   $_ECHO "[DEBUG] ${POSTBUILD}"
    $_ECHO "[DEBUG] ########################################"
    $_ECHO "[DEBUG] ########################################"	
fi

UPDATE=0

echo "${PREBUILD}"
if [ $? -eq 0 ]; then
JOBCONFIG=$($_ECHO "${JOBCONFIG}" | $_XMLSTARLET ed -u "/*/scm/branches/hudson.plugins.git.BranchSpec" -v "<name>$GERRIT_REFNAME</name>")
UPDATE=1
fi

#echo "${POSTBUILD}" | grep -q "check_gerrit_sync.sh"
#if [ $? -eq 0 ]; then
#JOBCONFIG=$($_ECHO "${JOBCONFIG}" | $_XMLSTARLET ed -u "/*/postbuilders/hudson.tasks.Shell/command" -v "#CI Common pre step scripts
#/proj/ciexadm200/tools/utils/scripts/common_pre_post_jenkins_scripts/post_step/release_post_step.sh")
#UPDATE=1
#fi

# Update job
if [ ${UPDATE} -ne 0 ]; then
    response=$($_CURL -k -s -X POST ${AUTH} -H "Content-Type:application/xml" -d "${JOBCONFIG}" "${JOBURL}")
    if [ ! -z "${response}" ]; then
       $_ECHO "${response}" > jenkins_error.html
        $_ECHO "[ERROR] ${SCRIPTNAME}: Jenkins returned an error locking the job."
        $_ECHO "[ERROR] ${SCRIPTNAME}: Open the file jenkins_error.html in a browser."
        $_ECHO -n "[ERROR] "
    else
        $_ECHO "[SUCCESS] ${SCRIPTNAME}: Job successfully updated."
        $_ECHO -n "[SUCCESS] "
	UPDATE=0
    fi
    $_ECHO "${SCRIPTNAME}: Check the job at ${HOST}/job/${JOB}"
else
    $_ECHO "[SUCCESS] ${SCRIPTNAME}: Job ${JOB} doesn't need updating."
fi
