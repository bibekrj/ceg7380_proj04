import subprocess
from django.shortcuts import render
from django.http import HttpResponse
from .forms import *
import os
import subprocess
from .utils import *
import time



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
        form = TSPForm(request.POST)
        j_status = os.popen("ssh "+ owens + " squeue -u w140bxj | tail -1 | awk '{print $5}' " ).read().rstrip('\n')
        print(j_status)

       
        bestFile = os.path.exists('best.txt')
        if bestFile:
            print('bestfileFound')
            bestFile_ = open('best.txt','r')
            bestFile_all_content = bestFile_.readlines()
            bestFile_type = bestFile_all_content[0].rstrip('\n')
            bestFile_distance = bestFile_all_content[1].rstrip('\n')
            print(bestFile_type, "The type of response")
            print(bestFile_distance, "the distance")
            bestFile_.close()
            os.popen('rm best.txt')

            context={
                'form': form,
                'newdist': 'found',
                'distVal': bestFile_distance,
                'jbstatus': 'nstarted',
                'message': "Best Distance Found"
            }

        elif j_status == "PD":
            jobnumner = os.popen("ssh "+ owens + " squeue -u w140bxj | tail -1 | awk '{print $3}' " ).read().rstrip('\n')
            context = {
                'form': form,
                'newdist': 'found',
                'distVal': "PENDING",
                'jbstatus': '',
                'message': 'JOB NOT STARTED'
            }

        elif j_status == "R":
            jobnumber = os.popen("ssh "+ owens + " squeue -u w140bxj | tail -1 | awk '{print $3}' " ).read().rstrip('\n')
            batch_number = jobnumber+ " of "+str(request.POST['numOfBatch']) 
            context = {
                'form': form,
                'newdist': 'found',
                'distVal': batch_number,
                'jbstatus': '',
                'message': 'Running'
            }
        
        else:  
            print("The weight selected was ",request.POST['weightType'])
            weightType = request.POST['weightType']
            currentBest = os.popen('ssh ' + owens + " source ~nehrbajo/proj03data/update03.sh " + weightType).read().rstrip('\n')
            context = {
                'form': form,
                'newdist': 'found',
                'distVal': currentBest,
                'jbstatus': 'nstarted',
                'message': 'NOT STARTED, weight selected '+str(weightType)
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

        print(request.POST)

        #creating pickles 
        current_best_distance = os.popen('ssh  ' + owens + ' "cat ~nehrbajo/proj03data/database0'+weightType+'.txt| tail -n 5 | head -n 1" ').read().rstrip('\n')
        current_best_path = os.popen('ssh ' + owens + ' "cat ~nehrbajo/proj03data/database0'+weightType+'.txt| tail -n 5 | head -n 2 | tail -n 1" ').read().rstrip('\n')

        # print(current_best_distance, current_best_path)
        #creating the best pickle based on the current best distance
        pickleCreator(current_best_distance, current_best_path, "initialGuess" )
        picklefilename = pickleReader('initialGuess.pickle')

        print('about to call workflow')
        global work 
        work = subprocess.Popen([value/"workflow.sh", weightType, picklefilename, randomSeed, numOfTrys, numOfBatch, current_best_distance ])
        # print(work)

        context = {
            'form': form,
            'jbstatus': 'STARTED',
            'message': 'STARTED',
            # 'distVal': bestcontent,
        }

    if 'stop' in request.POST:
        form = TSPForm(request.POST)

        j_status = os.popen("ssh "+ owens + " squeue -u w140bxj | tail -1 | awk '{print $5}' " ).read().rstrip('\n')
        print(j_status)
        if j_status == "PD" or j_status == 'R': 
            j_id = os.popen("ssh "+ owens + " squeue -u w140bxj | tail -1 | awk '{print $1}' " ).read().rstrip('\n')
            print('First condition: looking for  running job on owens')
            os.system('touch STOP')
            os.system("ssh " +owens+" scancel "+str(j_id))
            message_d = 'Stopped'
        
        else:
            time.sleep(10)
            j_id = os.popen("ssh "+ owens + " squeue -u w140bxj | tail -1 | awk '{print $1}' " ).read().rstrip('\n')
            # print('Second Condition: looking for   runnign job on owens')
            os.system("ssh " +owens+" scancel "+str(j_id))
            work.kill()
            message_d = 'Stopped with Values'
            os.system("scp cleanupcrew.sh"+owens+":")
            os.system('ssh '+owens+' "source cleanupcrew.sh" ')    
            os.system('ssh '+owens+' "rm cleanupcrew.sh" ') 

        context = {
            'form': form,
            'message': message_d,
            'jbstatus': 'nstarted'
        }
 

    if 'reset' in request.POST:
        form = TSPForm()
        context = {
            'form': form,
            'jbstatus': 'Force Stopping',
            'message': 'Cleared /Force Stopped',
            'jbstatus': 'nstarted'
        }
        j_status = os.popen("ssh "+ owens + " squeue -u w140bxj | tail -1 | awk '{print $5}' " ).read().rstrip('\n')
        if j_status == "R":
            j_id = os.popen("ssh "+ owens + " squeue -u w140bxj | tail -1 | awk '{print $1}' " ).read().rstrip('\n')
            os.system("ssh " +owens+" scancel "+str(j_id))
        work.kill()
        os.system("scp cleanupcrew.sh"+owens+":")
        os.system('ssh '+owens+' "source cleanupcrew.sh" ')    
        os.system('ssh '+owens+' "rm cleanupcrew.sh" ') 
        
          

    
    return render(request, 'core/index.html', context)