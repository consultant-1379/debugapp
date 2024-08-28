#!/bin/bash

while read HOST
do

TOTAL_JOBS=$(java -jar $HOME/jcli/jenkins-cli.jar -noCertificateCheck -s https://${HOST}-eiffel004.lmera.ericsson.se:8443/jenkins/ list-jobs All | wc -l)

echo "$HOST - Number of Jobs: $TOTAL_JOBS"

#if [ "$TOTAL_JOBS" -gt 900 ]
#then
#    echo "No more jobs on this Jenkins"
#    java -jar $HOME/jcli/jenkins-cli.jar -noCertificateCheck -s https://fem104-eiffel004.lmera.ericsson.se:8443/jenkins/ set-build-result fail
#else
#    echo "Not Cool Beans"#
#fi

done < $1
