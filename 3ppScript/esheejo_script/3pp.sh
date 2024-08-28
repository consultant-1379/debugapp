#!/bin/bash

var="$(find * -maxdepth 2 -type f -name pom.xml | xargs grep '<type>zip</type>\|<type>tar</type>\|<type>tar.gz</type>' | awk '{print $1}' | sed -e 's/\(:\)*$//g' )"

	for i in $var; do
		foo=$(sed -n "/<parent>/,/<\/parent>/p" $i)
		foo1=$(sed -n "/<dependency>/,/<\/dependency>/p" $i)
		echo -e "################################################\n$foo \n\n $foo1" >> /home/esheejo/Result3pp.txt
	done
