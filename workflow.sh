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



echo 'sending initialGuess.pickle'
guessPicklefileSetup $2
echo 'file sent'
echo "*"
echo "*"
echo "*"

echo 'loading variables'
WEIGHT=$1
START=1
END=$5
PICKLEFILE=$2
RANDSEED=$3
NOOFTRYS=$4
LOOP_START=0
LOOP_END=15
echo $END
echo $START
echo 'variables loaded'

bestDistance=`ssh ${owens} "source ~nehrbajo/proj03data/update03.sh $WEIGHT" `
echo "The best distance on owens with $WEIGHT is $bestDistance"
for ((i=${START}; i<=${END}; i++));
    do
        echo "**************************************"
        echo "loop $i"
        echo "values to forward"
        echo "attempt$i"
        echo "Start$START"
        echo "end $END"
        echo "Pickle File at $i is $PICKLEFILE"
        echo "RANDSEED $RANDSEED"
        echo "weight $WEIGHT"
        echo "Number of try $NOOFTRYS"
        echo "LOOP Starting at $LOOP_START"
        echo "Loop end at $LOOP_END"
        echo "**************************************"

        owensFileName="owensJob$i.sbatch"

        echo "The batch file name is sent to $owensFileName"

        sed -e 's/MYATTEMPT/'$i'/g' -e 's/MYDIR/attempt'$i'/g' -e 's/DISTANCEPICKLENUMBER/'$WEIGHT'/g' -e 's/PICKLEFILENAME/'$PICKLEFILE'/g' -e 's/RANDSEED/'$RANDSEED'/g' -e 's/NOOFTRYS/'$NOOFTRYS'/g' -e 's/LOOPSTART/'$LOOP_START'/g' -e 's/LOOPEND/'$LOOP_END'/g' owensTemplate.sbatch > $owensFileName
        
        echo 'sending Prepared batch template to  owens '
        scp $owensFileName ${owens}:
        echo "$owensFileName is sent to owens"

        echo "**"
    
        echo 'running the prepared batch template in owens'
        ssh ${owens} "sbatch $owensFileName"

        echo "going into loop to check for finished flag"
        
        jobFinished=""
        while [ "$jobFinished" == '' ]
            do                          
                echo 'sleeping 5s'
                sleep 5s
                echo 'awake'
                echo
                owensFinished=`ssh ${owens} "ls attempt$i/ 2> /dev/null | grep "FINISHED" | wc -l "` 
                echo "$owensFinished"

                if [ "$owensFinished" == "1" ]; then
                    echo "JOB $i Finished"
                    jobFinished="FINISHED"
                fi

                if [ -f "STOP" ]; then
                    jobFinished="INCOMPLETE"
                fi
            done
        echo "echo out of sleep loop, JOBS FINISHED $i"

        if [ "$jobFinished" == "FINISHED" ]; then 
            echo 'file downloaded'
            sleep 2s
            scp ${owens}:attempt$i/'job_'$i'_detail.txt' 'owens_job_'$i'_detail.txt'
        
            echo 'Reading from the downloaded file'
            bestrunFromOwens=`cat 'owens_job_'$i'_detail.txt' | head -n 1`


            echo "the best computed distance on owens is "$bestrunFromOwens" "
            overallRunBest=$bestrunFromOwens
            echo "the current best distance to beat is "$bestDistance" "

            if [ "$overallRunBest" -lt "$bestDistance" ]; then
                echo 'FOUND'
                echo '***************************CONGRATULATIONS******************'
                echo "updating the database"                   

                bestFileName=`cat "owens_job_"$i"_detail.txt" | tail -n 1 | tr '[:upper:]' '[:lower:]'`
                echo "The pickle file to download from server is $bestFileName"
                destFileName="bestIFoundSoFar_withweight_$1_run_$i.txt"
                echo "$destFileName to send over"
                bestPickleFileName='bestIFoundSoFar_owens_job_'$i'.pickle'

                echo 'downloading the best owens pickle'
                sleep 2s
                # directory_file="attempt$1/$bestFileName.pickle"
                # echo $directory_file

                # scp ${owens}:"$directory_file" $bestPickleFileName
                scp ${owens}:attempt$i/''$bestFileName'.pickle' $bestPickleFileName

                echo 'converting files for submission'
                python3 core/utils.py 3 "$bestPickleFileName" "$destFileName"
                echo 'copying new best distance to owens for submission'
                echo "The best distance file name is $destFileName"
                scp "$destFileName" ${owens}:
                echo "linking relevant database and pickle file to home directory on owens"
                ssh -q ${owens} "ln -s ~nehrbajo/proj03data/distance0"$WEIGHT".pickle . 2> /dev/null"
                ssh -q ${owens} "ln -s ~nehrbajo/proj03data/database0"$WEIGHT".txt . 2> /dev/null"
                echo 
                
               
                echo "running the update03.sh"
                echo "Best distance that we're gonna use is $overallRunBest"
                # ssh ${owens} "source /users/PWSU0471/nehrbajo/proj03data/update03.sh "$WEIGHT" "$destFileName" "
                
                
                echo 'Removing Unwanted Files'
                scp "cleanupcrew.sh" ${owens}:
                ssh ${owens} "source cleanupcrew.sh" 

                ssh ${owens} "rm cleanupcrew.sh"

                echo $overallRunBest
                echo "Normal" > best.txt
                echo $overallRunBest >> best.txt

                echo "removing files locally"
                rm $PICKLEFILE
                rm $destFileName
                rm $bestPickleFileName
                rm $owensFileName
                rm 'owens_job_'$i'_detail.txt'
                echo 'BYBYE NOW'
                exit 1                       
                                
            else
                if [ "$END" -eq 1 ]; then
                    # scp "cleanupcrew.sh" ${owens}:
                    # ssh  ${owens} "source cleanupcrew.sh" 
                    sleep 1s
                    # ssh ${owens} "rm cleanupcrew.sh"
                    echo 'DID NOT GET BEST DISTANCE'
                    echo 'NOTFOUND' >best.txt
                    echo 'No Distance'>>best.txt

                    echo "removing files locally"
                    rm $PICKLEFILE
                    rm $destFileName
                    rm $bestPickleFileName
                    rm $owensFileName
                    rm 'owens_job_'$i'_detail.txt'
                    echo 'BYBYE NOW'

                    exit 0
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
                    
                    python3 core/utils.py 2 "$distance" "$path" "$filename"

                    echo 'The best from all three was '$overallRunBest''
                    echo 'but current POSTED best distance is '$bestDistance''
                    echo 'the above two values should be the same'

                    PICKLEFILE="$filename".pickle
                    echo "THE NEW FILE BEING SENT OVER IS $PICKLEFILE"
                    echo 'sending the new best to remote servers'
                  
                    scp "$PICKLEFILE" ${owens}:
                    echo 'new pickle file sent to the server for next run'

                   
                    echo $END
                    echo $finalval
                    if [ "$END" -eq "$i" ]; then

                        echo "DID NOT FIND BEST DISTANCE, running the cleanup job"
                        # scp "cleanupcrew.sh" ${owens}:
                        # ssh  ${owens} "source cleanupcrew.sh" 
                        sleep 1s
                        # ssh ${owens} "rm cleanupcrew.sh"
                        # echo 'DID NOT GET BEST DISTANCE'
                        echo "removing files locally"
                        rm $PICKLEFILE
                        rm $destFileName
                        rm $bestPickleFileName
                        rm $owensFileName
                        rm 'owens_job_'$i'_detail.txt'
                        echo 'BYBYE NOW'

                        exit
                    fi
                    LOOP_START=$(($LOOP_START+16))
                    LOOP_END=$(($LOOP_END+16))

                    echo "removing files locally"
                    rm $PICKLEFILE
                    rm $destFileName
                    rm $bestPickleFileName
                    rm $owensFileName
                    rm 'owens_job_'$i'_detail.txt'
                    echo 'looping back'
                fi               
            fi
           
        elif [ "$jobFinished" == "INCOMPLETE" ]; then
            echo '*****PROGRAM TERMINATED BY USER. GOT INSIDE INCOMPLETE LOOP*****'
            files=`ssh ${owens} "ls | grep attempt${i}/job_'$i'_detail.txt"`
            echo "The file has is to be checked $files"

            shouldbe="attempt${i}/job_'$i'_detail.txt"
            echo  "The file that is there $shouldbe"

            if [ "$files" == "$shouldbe" ]; then
                echo 'distance files found on server downloading the detail file from remote server'
                scp ${owens}:attempt$i/'job_'$i'_detail.txt' 'owens_job_'$i'_detail.txt'

                checkFile=`cat 'owens_job_'$i'_detail.txt' | wc -l`
                if [ "$checkFile" == 2 ]; then
                    bestrunFromOwens=`cat 'owens_job_'$i'_detail.txt' | head -n 1`
                    overallRunBest=$bestrunFromOwens

                    echo " from the incomplete run the current best distance is "$overallRunBest" "

                    if [ "$overallRunBest" -lt "$bestDistance" ]; then
                        echo 'FOUND after interrupt'
                        echo '***************************CONGRATULATIONS******************'
                        echo "starting the database update sequence"                   

                    
                        bestFileName=`cat "owens_job_"$i"_detail.txt" | tail -n 1 | tr '[:upper:]' '[:lower:]'`
                        echo 'The pickle file to download name is '$bestFileName
                        destFileName="bestIFoundSoFar_withweight_$1_run_$i.txt"
                        bestPickleFileName='bestIFoundSoFar_owens_job_'$i'.pickle'
                        echo 'downloading the best owens pickle'
                        echo "The destination text file to use is $destFileName"
                        echo "The best pickle file name is $bestPickleFileName"

                        scp ${owens}:attempt$i/''$bestFileName'.pickle' $bestPickleFileName

                    
                        python3 core/utils.py 3 "$bestPickleFileName" "$destFileName"
            
                        echo 'copying new best distance to owens for submission'
                        echo "The distance file being copied is $destFileName"
                        scp "$destFileName" ${owens}:
                        echo "linking relevant database and pickle file to home directory on owens"
                        ssh -q ${owens} "ln -s ~nehrbajo/proj03data/distance0"$WEIGHT".pickle . 2> /dev/null"
                        ssh -q ${owens} "ln -s ~nehrbajo/proj03data/database0"$WEIGHT".txt . 2> /dev/null"

                        # echo 'checking if saved state exists'
                        # if [ -f "SAVEDSTATE" ]; then
                        #     echo 'removing saved states'
                        #     rm "SAVEDSTATE"
                        # fi
                        echo
                    
                        echo "running the update03.sh"
                        # ssh ${owens} "source /users/PWSU0471/nehrbajo/proj03data/update03.sh "$WEIGHT" "$destFileName" "
                        echo "DB Updated with best distance $overallRunBest"
                        
                        echo 'Removing Unwanted Files'
                        # scp "cleanupcrew.sh" ${owens}:
                        # ssh ${owens} "source cleanupcrew.sh" 

                        # ssh ${owens} "rm cleanupcrew.sh"

                        echo $overallRunBest
                        echo "INTERRUPTED BY USER; BEST FOUND" > best.txt
                        echo $overallRunBest >> best.txt
                        exit 1
                    
                    fi
                else
                    echo 'INTERRUPTED BY USER' > best.txt
                    echo 'NOT FOUND'>> best.txt
                    exit
                fi
            fi
        fi
        if [ -f "STOP" ]; then
                # echo 'ITERNATION_STATE':$(($i+1)) >> SAVEDSTATE
                # echo 'WEIGHT':$1 >> SAVEDSTATE
                # echo 'BATCH_END':$5 >> SAVEDSTATE
                # echo 'RAND_SEED':$3 >> SAVEDSTATE
                # echo 'PICKLE_FILE_NAME':$PICKLEFILE >> SAVEDSTATE
                # echo 'NO_OF_TRYS':$4 >> SAVEDSTATE
                rm "STOP"
                exit 2
        fi
    done