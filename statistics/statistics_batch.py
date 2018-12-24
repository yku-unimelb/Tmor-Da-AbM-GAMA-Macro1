import os
import csv
import statistics
from scipy import stats
import scipy as sp
import numpy as np



rootdir = '/home/yukiho/results'
#~ Date,Population,Capacity,home,shop,greens,temple,church,orphanage,1,2,3,4,5
csvheader = ['unit','space','percycle','year','N']
#~ csvheader += ['population mean','population sd']
#~ csvheader += ['Capacity mean','Capacity sd']
csvheader += ['homemean','homesd','homeste', 'homelb', 'homeub', 'homemin', 'homemax' ]
csvheader += ['shopmean','shopsd', 'shopste', 'shoplb', 'shopub', 'shopmin', 'shopmax']
#~ csvheader += ['greens mean','greens sd']
#~ csvheader += ['temple mean','temple sd']
#~ csvheader += ['church mean','church sd']
#~ csvheader += ['orphanage mean','orphanage sd']
#~ csvheader += ['1 storey mean','1 storey sd']
#~ csvheader += ['2 storey mean','2 storey sd']
#~ csvheader += ['3 storey mean','3 storey sd']
#~ csvheader += ['4 storey mean','4 storey sd']
#~ csvheader += ['5 storey mean','5 storey sd']

csvrows = []
# write header first
with open(os.path.join(rootdir,'e1-all.csv'),'w') as csvfile:
    writer = csv.writer(csvfile,delimiter=',',quotechar='"',quoting=csv.QUOTE_MINIMAL)
    writer.writerow(csvheader)
    

i = 1979
while i <= 2016:
    for dirs in os.listdir(rootdir):
        print (dirs)
        
        population = []
        capacity = []
        homes = []
        shops = []
        greens = []
        temple = []
        church = []
        orphanage = []
        floor1 = []
        floor2 = []
        floor3 = []
        floor4 = []
        floor5 = []
        

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
                                homes += [float(row[3])]
                                shops += [float(row[4])]
                                #~ greens += [float(row[5])]
                                #~ temple += [float(row[6])]
                                #~ church += [float(row[7])]
                                #~ orphanage += [float(row[8])]
                                #~ floor1 += [float(row[9])]
                                #~ floor2 += [float(row[10])]
                                #~ floor3 += [float(row[11])]
                                #~ floor4 += [float(row[12])]
                                #~ floor5 += [float(row[13])]
                            

        if homes != []:
            parms = dirs.split('_')
            csvrow = [parms[1],parms[3],parms[5],i]

    #~ csvheader += ['home mean','home sd','home cv','home ste', 'home 95 lb', 'home 95 ub', 'home min', 'home max' ]
    #~ csvheader += ['shop mean','shop sd','shop cv', 'shop ste', 'shop 95 lb', 'shop 95 ub', 'shop min', 'shop max']
            # stats for homes
            n, (min,max), mean, var, skew, kurt = stats.describe(homes[0:20])
            std = np.std(homes[0:20])
            lb, ub = stats.norm.interval(0.05,loc=mean,scale=std)
            ste = stats.sem(homes[0:20],axis=None)
            csvrow += [n, mean, std, ste,lb,ub,min,max]
            
            #stats for shops
            n, (min,max), mean, var, skew, kurt = stats.describe(shops[0:20])
            std = np.std(shops[0:20])
            lb, ub = stats.norm.interval(0.05,loc=mean,scale=std)
            ste = stats.sem(shops[0:20],axis=None)
            csvrow += [mean, std, ste,lb,ub,min,max]
            
            
            
            #~ homesmean = statistics.mean(homes)
            #~ shopsmean = statistics.mean(shops)
            #~ greensmean = statistics.mean(greens)
            #~ templemean = statistics.mean(temple)
            #~ churchmean = statistics.mean(church)
            #~ orphanagemean = statistics.mean(orphanage)
            #~ floor1mean = statistics.mean(floor1)
            #~ floor2mean = statistics.mean(floor2)
            #~ floor3mean = statistics.mean(floor3)
            #~ floor4mean = statistics.mean(floor4)
            #~ floor5mean = statistics.mean(floor5)
            #~ populationstdev = statistics.stdev(population)
            #~ capacitystdev = statistics.stdev(capacity)
            #~ homesstdev = statistics.stdev(homes)
            #~ shopsstdev = statistics.stdev(shops)
            #~ greensstdev = statistics.stdev(greens)
            #~ templestdev = statistics.stdev(temple)
            #~ churchstdev = statistics.stdev(church)
            #~ orphanagestdev = statistics.stdev(orphanage)
            #~ floor1stdev = statistics.stdev(floor1)
            #~ floor2stdev = statistics.stdev(floor2)
            #~ floor3stdev = statistics.stdev(floor3)
            #~ floor4stdev = statistics.stdev(floor4)
            #~ floor5stdev = statistics.stdev(floor5)
            
            


            #~ f_value, p_value = stats.f_oneway(*all_homes)
            #~ csvrow += [p_value]
            #~ csvrow += [populationmean,populationstdev]
            #~ csvrow += [capacitymean,capacitystdev]
            #~ csvrow += [homesmean,homesstdev]
            #~ csvrow += [shopsmean,shopsstdev]
            #~ csvrow += [greensmean,greensstdev]
            #~ csvrow += [templemean,templestdev]
            #~ csvrow += [churchmean,churchstdev]
            #~ csvrow += [orphanagemean,orphanagestdev]
            #~ csvrow += [floor1mean,floor1stdev]
            #~ csvrow += [floor2mean,floor2stdev]
            #~ csvrow += [floor3mean,floor3stdev]
            #~ csvrow += [floor4mean,floor4stdev]
            #~ csvrow += [floor5mean,floor5stdev]
            
            csvrows += [csvrow]
    i += 1

        
with open(os.path.join(rootdir,'e1-all.csv'),'a') as csvfile:
    csvwriter = csv.writer(csvfile, delimiter=',',quotechar='"',quoting=csv.QUOTE_MINIMAL)
    for row in csvrows:
        csvwriter.writerow(row)

    
