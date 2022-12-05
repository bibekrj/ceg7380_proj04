import subprocess
from django.shortcuts import render
from django.http import HttpResponse
from .forms import *
import os
import subprocess
from .utils import *

from django.conf import settings
value = settings.BASE_DIR

# Create your views here.

owens = 'w140bxj@owens.osc.edu'



def index(request):
    jbstatus = ''
    context = {
        'form': TSPForm(),
        'jbstatus': 'nstarted',
        'message': 'NOT STARTED'
    }

    if 'update' in request.POST:
        # todo: add a check if the job is running,
        # if the job is running,
        # get the batch number of the job
        # send context message accordingly and don't update the form.
        # disable other buttons such that it only updates the status of the job
        # if no job is running return user the form with data and the best distance

        form = TSPForm(request.POST)

        print(request.POST['weightType'])
        weightType = request.POST['weightType']
        currentBest = os.popen('ssh ' + owens + " source ~nehrbajo/proj03data/update03.sh " + weightType).read().rstrip('\n')
        context = {
            'form': form,
            'newdist': 'found',
            'distVal': currentBest,
            'jbstatus': 'nstarted',
            'message': 'NOT STARTED'
        }


    if 'submit' in request.POST:
        form = TSPForm(request.POST)
        weightType = request.POST.get('weightType')
        randomSeed = request.POST.get('randomSeed')
        numOfTrys = request.POST.get('numOfTrys')
        numOfBatch = request.POST.get('numOfBatch')

        print('The submitted weight is', weightType)
        print('The randomSeedValue is ', randomSeed)
        print('The number ofTrys is ', numOfTrys)
        print('The number of batches is ', numOfBatch)

        context = {
            'form': form,
            'jbstatus': '',
            'message': 'STARTED'
        }
        print(request.POST)

        #creating pickles 
        current_best_distance = os.popen('ssh ' + owens + ' "cat ~nehrbajo/proj03data/database0'+weightType+'.txt| tail -n 5 | head -n 1" ').read().rstrip('\n')
        current_best_path = os.popen('ssh ' + owens + ' "cat ~nehrbajo/proj03data/database0'+weightType+'.txt| tail -n 5 | head -n 2 | tail -n 1" ').read().rstrip('\n')

        #creating the best pickle based on the current best distance
        pickleCreator(current_best_distance, current_best_path, "initialGuess" )
        picklefilename = pickleReader('initialGuess.pickle')

        print('about to call workflow')
        

        # workflow_command = "workflow.sh " + weightType + " "+picklefilename+" "+randomSeed+" "+numOfTrys+" "+numOfBatch+" "+ current_best_distance

        subprocess.Popen([value/"core/workflow.sh", weightType, picklefilename, randomSeed, numOfTrys, numOfBatch, current_best_distance ])


        print('workflow  should be complete')
        # print(batchStatus.read())
       
        # for i in range(int(numOfBatch)):
        #     owensFileName="owensJob"+str(i)+".sbatch"
        #     os.popen("sed -e 's/MYATTEMPT/"+str(i)+"/g' -e 's/MYDIR/attempt"+str(i)+"/g' -e 's/DISTANCEPICKLENUMBER/"+str(weightType)+"/g' -e 's/PICKLEFILENAME/"+picklefilename+"/g' -e 's/RANDSEED/"+randomSeed+"/g' -e 's/NOOFTRYS/"+numOfTrys+"/g' -e 's/LOOPSTART/0/g' -e 's/LOOPEND/15/g' owensTemplate.sbatch >"+owensFileName)
        #     # os.popen("scp "+owens+ " ")
        #     os.popen("scp "+ picklefilename +" "+ owens+":")
        #     os.popen("scp "+ owensFileName +" "+ owens+":")

        #     os.popen('ssh '+owens+ ' "sbatch '+owensFileName+' "')
            
        #     jobFinished = False
        #     while not jobFinished:
        #         os.popen('')



 
        


    if 'reset' in request.POST:
        form = TSPForm()
        context = {
            'form': form,
            'jbstatus': 'nstarted',
            'message': 'cleared'
        }

    if 'stop' in request.POST:
        form = TSPForm(request.POST)
        context = {
            'form': form,
            'message': 'STOPPED'
        }
    return render(request, 'core/index.html', context)
