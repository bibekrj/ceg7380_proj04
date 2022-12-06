#!/usr/bin/bash
#SBATCH --account=PWSU0493
#SBATCH -N 1
#SBATCH --cpus-per-task=1
#SBATCH --tasks-per-node=16
#SBATCH --job-name=job_1
#SBATCH --output=results1.txt
#SBATCH --time=00:15:00

#sed strings to replace
#1 : my attempt number
#attempt1     : my working directory


#make a working directory
mkdir -p attempt1

#change to working directory
cd attempt1

#for initial and consequent pickles
ln -s ../initialGuess.pickle initialGuess.pickle

ln -s ~nehrbajo/proj03data/distance0* . 2> /dev/null


touch STARTED

for task in $(seq 0 16);
do
    singularity exec -B /users/PWSU0471/nehrbajo/proj03data -B /users/PWSU0471/nehrbajo/proj03data/tspMod.py ~nehrbajo/python3.sif python3 /users/PWSU0471/nehrbajo/proj03data/tspMod.py 0 initialGuess.pickle $(($task+1)) 100000000 & 
done
wait

current_best_1_NUM=`cut -d ":" -f2 ../results1.txt| uniq |sort | head -n1`
#echo $current_best_1_NUM

best_pickle_file=`grep "$current_best_1_NUM" ../results1.txt | cut -d ":" -f1 | head -n 1`

#touch best_ATTEMPTNUM_detail.txt
echo $current_best_1_NUM >>  job_1_detail.txt

echo $best_pickle_file >> job_1_detail.txt

mv STARTED FINISHED
