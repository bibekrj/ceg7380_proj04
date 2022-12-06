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

bestDistance=`ssh ${owens} "source ~nehrbajo/proj03data/update03.sh $1" `


guessPicklefileSetup $2
echo 'file sent'
echo 'loading variables'
WEIGHT=$1
START=0
END=$5
PICKLEFILE=$2
RANDSEED=$3
NOOFTRYS=$4
LOOP_START=0
LOOP_END=15
echo $END
echo $START
echo 'variables loaded'


for ((i=${START}; i<${END}; i++));
    do
        echo "inside the for loop $i"
        echo "the value of i is $i"
        echo "Pickle File is "$PICKLEFILE" "
        owensFileName="owensJob$i.sbatch"
        sed -e 's/MYATTEMPT/'$i'/g' -e 's/MYDIR/attempt'$i'/g' -e 's/DISTANCEPICKLENUMBER/'$WEIGHT'/g' -e 's/PICKLEFILENAME/'$PICKLEFILE'/g' -e 's/RANDSEED/'$RANDSEED'/g' -e 's/NOOFTRYS/'$NOOFTRYS'/g' -e 's/LOOPSTART/'$LOOP_START'/g' -e 's/LOOPEND/'$LOOP_END'/g' owensTemplate.sbatch > $owensFileName
        
        echo 'sending Prepared batch template to  owens '
        
        scp $owensFileName ${owens}:
    

        echo 'running the prepared batch template in fry'
        ssh -q ${owens} "sbatch $owensFileName"
        jobFinished=""
        while [ "$jobFinished" == '' ]
            do                          
                echo 'sleeping 10s'
                sleep 5s
                echo 'awake'
                echo
                owensFinished=`ssh -q ${owens} "ls attempt$i/ 2> /dev/null | grep "FINISHED" "` 
                
                if [ "$owensFinished" == "FINISHED" ]; then
                    jobFinished="FINISHED"
                fi

                if [ -f "STOP" ]; then
                    jobFinished="INCOMPLETE"
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
            echo $bestrunfromFry
            
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

            
                python3 core/utils.py 3 "$bestPickleFileName" "$destFileName"
                echo
                echo 'copying new best distance to owens for submission'
                echo $destFileName
                scp "$destFileName" ${owens}:
                echo
                echo "linking relevant database and pickle file to home directory on owens"
                echo
                ssh -q ${owens} "ln -s ~nehrbajo/proj03data/distance0"$WEIGHT".pickle . 2> /dev/null"
                ssh -q ${owens} "ln -s ~nehrbajo/proj03data/database0"$WEIGHT".txt . 2> /dev/null"
                echo 
                
                echo
                echo 'checking if saved state exists'
                if [ -f "SAVEDSTATE" ]; then
                    echo 'removing saved states'
                    rm "SAVEDSTATE"
                fi
                echo
               
                echo "running the update03.sh"
                ssh -q ${owens} "source /users/PWSU0471/nehrbajo/proj03data/update03.sh "$WEIGHT" "$destFileName" "
                echo "DB Updated with best distance $overallRunBest"
                
                echo 'Removing Unwanted Files'
                # scp "cleanupcrew.sh" ${owens}:
                # ssh ${owens} "source cleanupcrew.sh" 

                # ssh ${owens} "rm cleanupcrew.sh"

                echo $overallRunBest
                echo "Normal" > best.txt
                echo $overallRunBest >> best.txt
                exit 1
               
               
                                
            else
                if [ "$END" -eq 1 ]; then
                    # scp "cleanupcrew.sh" ${owens}:
                    # ssh  ${owens} "source cleanupcrew.sh" 
                    sleep 1s
                    # ssh ${owens} "rm cleanupcrew.sh"
                    echo 'DID NOT GET BEST DISTANCE'
                    echo 'NOTFOUND' >best.txt
                    echo '000000000'>>best.txt
                    exit 0
                else

                    echo '********************'
                    echo 'Setting up the server with new best distance pickle file for next batch run'
                    echo 'getting current best weight details'
                    echo
                    distance=`ssh -q ${owens} "cat ~nehrbajo/proj03data/database0"$WEIGHT".txt | tail -n 5 | head -n 1"`
                    echo
                    path=`ssh -q ${owens} "cat ~nehrbajo/proj03data/database0"$WEIGHT".txt | tail -n 5 | head -n 2 | tail -n 1"`
                    echo
                    filename="database0"$i""
                    python3 core/utils.py 2 "$distance" "$path" "$filename"
                    echo 'The best from all three was '$overallRunBest''
                    echo 'but current POSTED best distance is '$bestDistance''
                    PICKLEFILE="$filename".pickle
                    
                    echo 'sending the new best to remote servers'
                    echo
                    echo 
                    scp "$PICKLEFILE" ${owens}:
                    echo ' new pickle file sent to the server for next run in case of interupt'
                    finalval=$(($i+1)) 
                    echo 'The end and final val are'
                    echo $END
                    echo $finalval
                    if [ "$END" -eq "$finalval" ]; then
                        # scp "cleanupcrew.sh" ${owens}:
                        # ssh  ${owens} "source cleanupcrew.sh" 
                        sleep 1s
                        # ssh ${owens} "rm cleanupcrew.sh"
                        echo 'DID NOT GET BEST DISTANCE'
                    fi
                    LOOP_START=$(($LOOP_START+16))
                    LOOP_END=$(($LOOP_END+16))
                    # exit 0

                fi
                
            fi
           
        elif [ "$jobFinished" == "INCOMPLETE" ]; then
            files=`ssh ${owens} "ls | grep attempt${i}/job_'$i'_detail.txt"`
            shouldbe="attempt${i}/job_'$i'_detail.txt"
            if [ "$files" == "$shouldbe" ]; then
                scp ${owens}:attempt$i/'job_'$i'_detail.txt' 'owens_job_'$i'_detail.txt'
                bestrunFromOwens=`cat 'owens_job_'$i'_detail.txt' | head -n 1`

                overallRunBest=$bestrunFromOwens


            #     echo '*********************************'
                echo " from the incomplete run the current best distance is "$bestDistance" "

                if [ "$overallRunBest" -lt "$bestDistance" ]; then
            #         echo 'FOUND'
            #         echo '***************************CONGRATULATIONS******************'
            #         echo "updating the database"                   

                
                    bestFileName=`cat "owens_job_"$i"_detail.txt" | tail -n 1 | tr '[:upper:]' '[:lower:]'`
                    echo 'The pickle file to download name is '$bestFileName
                    destFileName="bestIFoundSoFar_$1_$i.txt"
                    bestPickleFileName='bestIFoundSoFar_owens_job_'$i'.pickle'
                    echo 'downloading the best owens pickle'
                    scp ${owens}:attempt$i/''$bestFileName'.pickle' $bestPickleFileName

                
                    python3 core/utils.py 3 "$bestPickleFileName" "$destFileName"
            #         echo
                    echo 'copying new best distance to owens for submission'
                    echo $destFileName
                    scp "$destFileName" ${owens}:
            #         echo
                    echo "linking relevant database and pickle file to home directory on owens"
            #         echo
                    ssh -q ${owens} "ln -s ~nehrbajo/proj03data/distance0"$WEIGHT".pickle . 2> /dev/null"
                    ssh -q ${owens} "ln -s ~nehrbajo/proj03data/database0"$WEIGHT".txt . 2> /dev/null"
            #         echo 
                    
            #         echo
            #         echo 'checking if saved state exists'
            #         if [ -f "SAVEDSTATE" ]; then
            #             echo 'removing saved states'
            #             rm "SAVEDSTATE"
            #         fi
            #         echo
                
                    echo "running the update03.sh"
                    ssh -q ${owens} "source /users/PWSU0471/nehrbajo/proj03data/update03.sh "$WEIGHT" "$destFileName" "
                    echo "DB Updated with best distance $overallRunBest"
                    
            #         echo 'Removing Unwanted Files'
            #         scp "cleanupcrew.sh" ${owens}:
            #         ssh ${owens} "source cleanupcrew.sh" 

            #         ssh ${owens} "rm cleanupcrew.sh"

                    echo $overallRunBest
                    echo "STOPPED_BEST" > best.txt
                    echo $overallRunBest >> best.txt
                    exit 1
                
                
                 else
                    echo 'NOTFOUND' >best.txt
                    echo 'FALSE'>> best.txt
                    exit
                fi
            
            fi
        fi
        if [ -f "STOP" ]; then
                echo 'ITERNATION_STATE':$(($i+1)) >> SAVEDSTATE
                echo 'WEIGHT':$1 >> SAVEDSTATE
                echo 'BATCH_END':$5 >> SAVEDSTATE
                echo 'RAND_SEED':$3 >> SAVEDSTATE
                echo 'PICKLE_FILE_NAME':$PICKLEFILE >> SAVEDSTATE
                echo 'NO_OF_TRYS':$4 >> SAVEDSTATE
                # rm "STOP"
                exit 2

        fi
    done