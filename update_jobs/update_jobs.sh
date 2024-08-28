#!/bin/bash

while read HOST
do
	echo "##############################################################################"
	echo "#######################    Updating jobs on $HOST ###########################"
	echo "##############################################################################"
	
	for j in $(java -jar $HOME/jcli/jenkins-cli.jar -noCertificateCheck -s https://${HOST}-eiffel004.lmera.ericsson.se:8443/jenkins/ list-jobs All | grep -v "Skipping" ); do 

	echo "Updating job $j"; java -jar $HOME/jcli/jenkins-cli.jar -noCertificateCheck -s https://${HOST}-eiffel004.lmera.ericsson.se:8443/jenkins/ get-job $j | grep -v 'Skipping ' | sed 's#<keepQueues>true#<keepQueues>false#g' | java -jar $HOME/jcli/jenkins-cli.jar -noCertificateCheck -s https://${HOST}-eiffel004.lmera.ericsson.se:8443/jenkins/ update-job $j; done

done < $1
