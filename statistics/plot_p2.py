import os
import csv
import matplotlib.patches as mpatches
import matplotlib.lines as mlines
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from matplotlib import cm
from matplotlib.ticker import LinearLocator, FormatStrFormatter
import numpy as np
import scipy.interpolate as interp

results = '/home/yukiho/results/'

x1,x2,x3 = [],[],[]
y1,y2,y3 = [],[],[]
unit1,unit2,unit3 = [],[],[]

with open(os.path.join(results,'1.csv')) as csvfile:
    reader = csv.reader(csvfile, delimiter=',')
    next(reader)
    next(reader)
    for row in reader:
        if not (row[0].startswith("Wander")):
            x1 += [float(row[0])]
            y1 += [float(row[1])]
            unit1 += [float(row[2])]
with open(os.path.join(results,'2.csv')) as csvfile:
    reader = csv.reader(csvfile, delimiter=',')
    next(reader)
    next(reader)
    for row in reader:
        if not(row[0].startswith("Wander")):
            x2 += [float(row[0])]
            y2 += [float(row[1])]
            unit2 += [float(row[2])]
with open(os.path.join(results,'3.csv')) as csvfile:
    reader = csv.reader(csvfile, delimiter=',')
    next(reader)
    next(reader)
    for row in reader:
        if not (row[0].startswith("Wander")):
            x3 += [float(row[0])]
            y3 += [float(row[1])]
            unit3 += [float(row[2])]
        
plotx,ploty = np.meshgrid(np.linspace(np.min(x1),np.max(x1),10),np.linspace(np.min(y1),np.max(y1),10))
fig = plt.figure()
ax = fig.add_subplot(1,3,1,projection='3d')
plotz = interp.griddata((x1,y1),unit1,(plotx,ploty),method='linear')
surf1 = ax.scatter(x1, y1, unit1,c='b', label='No extra target')
ax.invert_zaxis()
#~ plt.title('No extra target')
#~ ax.legend()
plt.xlabel('X')
plt.ylabel('Y')
ax.set_zlabel('Home units')

plotx,ploty = np.meshgrid(np.linspace(np.min(x2),np.max(x2),10),np.linspace(np.min(y2),np.max(y2),10))
ax = fig.add_subplot(1,3,2,projection='3d')
plotz = interp.griddata((x2,y2),unit2,(plotx,ploty),method='linear')
surf2 = ax.scatter(x2, y2, unit2,c='r', label='Extra target {138,304}')
ax.invert_zaxis()
#~ plt.title('Extra target {138,304}')
#~ ax.legend()
plt.xlabel('X')
plt.ylabel('Y')
ax.set_zlabel('Home units')

plotx,ploty = np.meshgrid(np.linspace(np.min(x3),np.max(x3),10),np.linspace(np.min(y3),np.max(y3),10))
ax = fig.add_subplot(1,3,3,projection='3d')
plotz = interp.griddata((x3,y3),unit3,(plotx,ploty),method='linear')
surf3 = ax.scatter(x3, y3, unit3,c='g', label = 'Extra targets {138,304},{215,353}')
#~ plt.title('Extra targets {138,304},{215,353}')
#~ bar = fig.colorbar(surf2, aspect=10, orientation = 'horizontal')
#~ bar.set_label('Floor area (1000 $m^{2}$)')
plt.xlabel('X')
plt.ylabel('Y')
ax.set_zlabel('Home units')

#~ plt.title('Homes')
ax.invert_zaxis()
fig.legend((surf1,surf2,surf3),('No extra target','Extra target {138,304}','Extra targets {138,304},{215,353}'),'upper left')
plt.show()
