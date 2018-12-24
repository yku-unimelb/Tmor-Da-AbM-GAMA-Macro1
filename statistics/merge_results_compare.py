import os
import csv
#~ import statistics
#~ from scipy import stats
#~ import scipy as sp
import numpy as np



rootdir = '/home/yukiho/results'
#~ Date,Population,Capacity,home,shop,greens,temple,church,orphanage,1,2,3,4,5
csvheader = ['scenario','year','homes','shops']


csvrows = []
# write header first
with open(os.path.join(rootdir,'e1-2016.csv'),'w') as csvfile:
    writer = csv.writer(csvfile,delimiter=',',quotechar='"',quoting=csv.QUOTE_MINIMAL)
    writer.writerow(csvheader)
    

i = 1979
while i <= 2016:
    for dirs in os.listdir(rootdir):
        print (dirs)

        for subdir, sdirs, files in os.walk(os.path.join(rootdir,dirs)):
            for file in files:
                if file.endswith('.csv'):
                    with open(os.path.join(subdir,file),'r') as csvfile:
                        reader = csv.reader(csvfile, delimiter=',')
                        next(reader)

                        for row in reader:

                            if row[0] == str(i):
                                #~ population += [float(row[1])]
                                #~ capacity += [float(row[2])]
                                #~ homes += [float(row[3])]
                                #~ shops += [float(row[4])]
                                #~ greens += [float(row[5])]
                                #~ temple += [float(row[6])]
                                #~ church += [float(row[7])]
                                #~ orphanage += [float(row[8])]
                                #~ floor1 += [float(row[9])]
                                #~ floor2 += [float(row[10])]
                                #~ floor3 += [float(row[11])]
                                #~ floor4 += [float(row[12])]
                                #~ floor5 += [float(row[13])]
                                parms = dirs.replace('results','')
                                csvrow = [parms,i,float(row[3]),float(row[4])]
                                csvrows += [csvrow]
    i+=1
        
        
with open(os.path.join(rootdir,'e1-2016.csv'),'a') as csvfile:
    csvwriter = csv.writer(csvfile, delimiter=',',quotechar='"',quoting=csv.QUOTE_MINIMAL)
    for row in csvrows:
        csvwriter.writerow(row)

    
