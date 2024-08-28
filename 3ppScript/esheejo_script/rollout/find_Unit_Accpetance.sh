#!/bin/bash

while read job
do
	echo -e $job | grep Unit >>/home/esheejo/3ppScript/esheejo_script/rollout/FEM105/fem105_UNIT_PostBuild.txt
	echo -e $job | grep Acceptance >>/home/esheejo/3ppScript/esheejo_script/rollout/FEM105/fem105_Acceptance_PostBuild.txt

done < $1
