import pickle
import sys


def pickleReader(fileName):
    rfile = open(fileName, 'rb')
    val1= pickle.load(rfile)
    val = pickle.load(rfile)
    # print(val1)
    # print(val)
    rfile.close()
    return fileName

def pickleCreator(totalDistance, pathway, fileName):
    readyName=fileName+".pickle"
    ofile = open(readyName, 'wb')
    a=pathway.rstrip(']')
    # print(a)
    b = a.lstrip('[')
    # print(pathway)
    list1=b.split(',')
    pathwaylist=list(map(int,list1))
    pickle.dump(int(totalDistance),ofile)
    pickle.dump(pathwaylist, ofile)
    ofile.close()
    return 'Success'

def pickleToText(fileName, destFile):
    # readyName=fileName
    rfile = open(fileName, 'rb')
    val1= pickle.load(rfile)
    val = pickle.load(rfile)
    asciiFile = open(destFile, 'w')
    asciiFile.write(str(val1))
    asciiFile.write('\n')
    asciiFile.write(str(val))
    asciiFile.write('\n')
    rfile.close()
    asciiFile.close()



if __name__ == '__main__':
    option = int(sys.argv[1])

    if option == 1:
        # print('option 1 selected')
        pickleReader(sys.argv[2])
    elif option == 2:
        pickleCreator(sys.argv[2],sys.argv[3],sys.argv[4])
    elif option == 3:
        pickleToText(sys.argv[2],sys.argv[3])
