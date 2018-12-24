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

results = '/home/yukiho/Documents/Final project/thesis_1/Results/e1/e1-all.csv'

unit = []
space = []
percycle = []
homemean = []
shopmean = []
year = []

with open(results) as csvfile:
    reader = csv.reader(csvfile, delimiter=',')
    next(reader)
    for row in reader:
        unit += [float(row[0])]
        space += [float(row[1])]
        percycle += [float(row[2])]
        year += [float(row[3])]
        homemean += [float(row[5])/1000]
        shopmean += [float(row[12])/1000]

plotx,ploty = np.meshgrid(np.linspace(np.min(percycle),np.max(percycle),10),np.linspace(np.min(year),np.max(year),10))


fig = plt.figure()
#plot_surface
# homes
#~ ax = fig.add_subplot(1,2,1,projection='3d')
ax = fig.add_subplot(1,2,1)
plotz = interp.griddata((percycle,year),homemean,(plotx,ploty),method='linear')
surf = ax.contourf(plotx, ploty, plotz, cmap=cm.coolwarm,linewidth=1, antialiased=False)
#~ surf = ax.plot_surface(plotx, ploty, plotz, cmap=cm.coolwarm,linewidth=1, antialiased=False)

bar = fig.colorbar(surf, aspect=10, orientation = 'horizontal')
bar.set_label('Floor area (1000 $m^{2}$)')
plt.xlabel('Maximum number of units built in each cycle')
plt.ylabel('Year')
plt.title('Homes')
#shops
plotz = interp.griddata((percycle,year),shopmean,(plotx,ploty),method='linear')
ax = fig.add_subplot(1,2,2)
surf = ax.contourf(plotx, ploty, plotz, cmap=cm.coolwarm,linewidth=1, antialiased=False)
bar = fig.colorbar(surf, aspect=10, orientation = 'horizontal')
bar.set_label('Floor area (1000 $m^{2}$)')
plt.xlabel('Maximum number of units built in each cycle')
plt.ylabel('Year')
plt.title('Shops')

# Add a color bar which maps values to colors.

plt.show()
