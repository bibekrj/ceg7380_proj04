#!/usr/bin/bash
# name: Bibek Raj Joshi
# wNumber: w140bxj
# Project Name: Proj04
# Assigned : Oct 20
# Due Date : December 6
# Tested on: aws

owens='w140bxj@owens.osc.edu'

function guessPicklefileSetup {

    echo "************sending first guess pickle file to fry*****************"
  
    scp $1  ${owens}:
   
}

bestDistance=$6

if [ -f "SAVEDSTATE" ]; then
	echo 'Saved State found, loading values.....'
    WEIGHT=`grep "WEIGHT" SAVEDSTATE | cut -d ":" -f2`
    START=`grep "ITERNATION_STATE" SAVEDSTATE | cut -d ":" -f2`
    END=`grep "BATCH_END" SAVEDSTATE | cut -d ":" -f2`
    RANDSEED=`grep "RAND_SEED" SAVEDSTATE | cut -d ":" -f2`
    PICKLEFILE=`grep "PICKLE_FILE_NAME" SAVEDSTATE | cut -d ":" -f2`
    NOOFTRYS=`grep "NO_OF_TRYS" SAVEDSTATE | cut -d ":" -f2`
else
    #sending initial pickle files
    guessPicklefileSetup $2
    #loading the rest of the values
    WEIGHT=$1
    START=0
    END=$5
    PICKLEFILE=$2
    RANDSEED=$3
    NOOFTRYS=$4

fi
for ((i=${START}; i<${END}; i++));
    do
        echo "Pickle File is "$PICKLEFILE" "
        owensFileName="owensJob$i.sbatch"
        sed -e 's/MYATTEMPT/'$i'/g' -e 's/MYDIR/attempt'$i'/g' -e 's/DISTANCEPICKLENUMBER/'$WEIGHT'/g' -e 's/PICKLEFILENAME/'$PICKLEFILE'/g' -e 's/RANDSEED/'$RANDSEED'/g' -e 's/NOOFTRYS/'$NOOFTRYS'/g' -e 's/LOOPSTART/0/g' -e 's/LOOPEND/15/g' owensTemplate.sbatch > $owensFileName
        
        echo 'sending Prepared batch template to  owens '
        
        scp $owensFileName ${owens}:
    

        echo 'running the prepared batch template in fry'
        ssh ${owens} "sbatch $owensFileName"
        jobFinished=""
        while [ "$jobFinished" == '' ]
                do                          
                    echo 'sleeping 10s'
                    sleep 10s
                    echo 'awake'
                    echo
                    owensFinished=`ssh ${owens} "ls attempt$i/ 2> /dev/null | grep "FINISHED" "` 
                   
                    if [ "$owensFinished" == "FINISHED" ]; then
                        jobFinished="FINISHED"
                    fi
                done
        echo "JOBS FINISHED $i"
        if [ "$jobFinished" == "FINISHED" ]; then
            echo '********************************'
            echo 'about to copy files from remote to local for Comparison'
         
            scp ${owens}:attempt$i/'job_'$i'_detail.txt' 'owens_job_'$i'_detail.txt'
            
            echo 'trying to read from the downloaded file'
           
            bestrunFromOwens=`cat 'owens_job_'$i'_detail.txt' | head -n 1`
          
            echo "the best distance on owens is "$bestrunFromOwens" "
            # echo $bestrunfromFry
            
            overallRunBest=$bestrunFromOwens


            echo '*********************************'
            echo "the current best distance is "$bestDistance" "

            if [ "$overallRunBest" -lt "$bestDistance" ]; then
                echo 'FOUND'
                echo '***************************CONGRATULATIONS******************'
                echo "updating the database"                   

               
                bestFileName=`cat "owens_job_"$i"_detail.txt" | tail -n 1 | tr '[:upper:]' '[:lower:]'`
                echo 'The pickle file to download name is '$bestFileName
                destFileName="bestIFoundSoFar_$1_$i.txt"
                bestPickleFileName='bestIFoundSoFar_owens_job_'$i'.pickle'
                echo 'downloading the best owens pickle'
                scp ${owens}:attempt$i/''$bestFileName'.pickle' $bestPickleFileName

               
                echo
                python3 /core/utils.py 3 "$bestPickleFileName" "$destFileName"
                echo
                echo 'copying new best distance to owens for submission'
                echo $destFileName
                scp "$destFileName" ${owens}:
                echo
                echo "linking relevant database and pickle file to home directory on owens"
                echo
                ssh ${owens} "ln -s ~nehrbajo/proj03data/distance0"$WEIGHT".pickle . 2> /dev/null"
                ssh ${owens} "ln -s ~nehrbajo/proj03data/database0"$WEIGHT".txt . 2> /dev/null"
                echo 
                
                echo
                echo 'checking if saved state exists'
                if [ -f "SAVEDSTATE" ]; then
                    echo 'removing saved states'
                    rm "SAVEDSTATE"
                fi
                echo
               
                echo "running the update03.sh"
                ssh ${owens} "source /users/PWSU0471/nehrbajo/proj03data/update03.sh "$WEIGHT" "$destFileName" "
                exit 1
               
               
                                
            else
                

                echo '********************'
                echo 'Setting up the server with new best distance pickle file for next batch run'
                echo 'getting current best weight details'
                echo
                distance=`ssh ${owens} "cat ~nehrbajo/proj03data/database0"$WEIGHT".txt | tail -n 5 | head -n 1"`
                echo
                path=`ssh ${owens} "cat ~nehrbajo/proj03data/database0"$WEIGHT".txt | tail -n 5 | head -n 2 | tail -n 1"`
                echo
                filename="database0"$i""
                python3 /core/utils.py 2 "$distance" "$path" "$filename"
                echo 'The best from all three was '$overallRunBest''
                echo 'but current POSTED best distance is '$bestDistance''
                PICKLEFILE="$filename".pickle
                
                echo 'sending the new best to remote servers'
                echo
                scp "$PICKLEFILE" ${owens}:
                echo
                
            fi
            if [ -f "STOP" ]; then
                echo 'ITERNATION_STATE':$(($i+1)) >> SAVEDSTATE
                echo 'WEIGHT':$1 >> SAVEDSTATE
                echo 'BATCH_END':$5 >> SAVEDSTATE
                echo 'RAND_SEED':$3 >> SAVEDSTATE
                echo 'PICKLE_FILE_NAME':$PICKLEFILE >> SAVEDSTATE
                echo 'NO_OF_TRYS':$4 >> SAVEDSTATE
                rm "STOP"
                exit 

            fi
        fi
    done