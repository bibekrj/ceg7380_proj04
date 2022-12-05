#!/usr/bin/bash
#SBATCH --account=PWSU0493
#SBATCH -N 1
#SBATCH --cpus-per-task=1
#SBATCH --tasks-per-node=16
#SBATCH --job-name=job_MYATTEMPT
#SBATCH --output=resultsMYATTEMPT.txt
#SBATCH --time=00:15:00

#sed strings to replace
#MYATTEMPT : my attempt number
#MYDIR     : my working directory


#make a working directory
mkdir -p MYDIR

#change to working directory
cd MYDIR

#for initial and consequent pickles
ln -s ../PICKLEFILENAME PICKLEFILENAME

ln -s ~nehrbajo/proj03data/distance0* . 2> /dev/null


touch STARTED

for task in $(seq LOOPSTART LOOPEND);
do
    singularity exec -B /users/PWSU0471/nehrbajo/proj03data -B /users/PWSU0471/nehrbajo/proj03data/tspMod.py ~nehrbajo/python3.sif python3 /users/PWSU0471/nehrbajo/proj03data/tspMod.py DISTANCEPICKLENUMBER PICKLEFILENAME $(($task+RANDSEED)) NOOFTRYS & 
done
wait

current_best_MYATTEMPT_NUM=`cut -d ":" -f2 ../resultsMYATTEMPT.txt| uniq |sort | head -n1`
#echo $current_best_MYATTEMPT_NUM

best_pickle_file=`grep "$current_best_MYATTEMPT_NUM" ../resultsMYATTEMPT.txt | cut -d ":" -f1 | head -n 1`

#touch best_ATTEMPTNUM_detail.txt
echo $current_best_MYATTEMPT_NUM >>  job_MYATTEMPT_detail.txt

echo $best_pickle_file >> job_MYATTEMPT_detail.txt

mv STARTED FINISHED
