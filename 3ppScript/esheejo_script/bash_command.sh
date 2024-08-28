#!/bin/bash

#rm -rf /home/esheejo/Result3pp.txt

while read job
do
	#cd into an OSS folder I created for the jobs
	cd OSS
	
	#Clones the repo
	git clone ssh://esheejo@gerritmirror.lmera.ericsson.se:29418/$job |awk '{print $3}'
        
	#Ouput to console 
	echo -e "####################\n\nRepo $job is cloned\n\n"
	
	#to get the job name from the input- taking the artifactID off the repo name
	dir=$(cut -d/ -f3 <<<"${job}")

	if [[ -n "$dir" ]]; then
	      
		#cd into repoo
		cd $dir
		
		#debug to show where I am
		 pwd
		
                #Seach through the poms not inclusing the top level pom
                FIND_RESULT=$(find * -regex ".*\.\(tar\|tar.gz\|zip\|war\|ear\)" )

                LOC_IN_REPO=$(find * -regex ".*\.\(tar\|tar.gz\|zip\|war\|ear\)"| cut -d/ -f1)

                #set a FIND_RESULTiable prev_pom to equal nothing..
                PREV_DIR_IN_REPO="notSet"

                #for every result returned from $FIND_RESULT; do
                for i in $LOC_IN_REPO; do

                       # echo -e "\n###########################\n File found in\n $i"
                        #if i != prev_pom the
                        if [ "$i" != "$PREV_DIR_IN_REPO" ];then
                                echo -e "\n###############################################\n File found in: $i"
                                echo -e "###############################\nRepo: $job\n$FIND_RESULT\n">> /home/esheejo/Result.txt
                                PREV_DIR_IN_REPO=$i
                        fi
                done
		
		#cd up out of the repo
		cd ..

		#remove the repo
		rm -rf $dir
		
		#echo to know repo is removed
		echo -e "\n####################\n\nRepo $job is removed\n\n"
		
	else
		echo -e "####################\n\nRepo url not correct\n\n"
	fi
	
	#cd up out of the OSS folder
	cd ..

	
done < $1
