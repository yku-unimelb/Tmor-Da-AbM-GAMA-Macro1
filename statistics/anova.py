
import numpy as np
import pandas as pd
import scipy
import scipy.stats as stats

import statsmodels
import statsmodels.api as sm
from statsmodels.formula.api import ols
import os
import csv



rootdir = '/home/yukiho/Documents/Final project/thesis_1/Results/e2'

data = pd.read_csv(os.path.join(rootdir,'e2-2016.csv'))

home_lm = ols('homes ~ C(unit)',data=data).fit()
shop_lm = ols('shops ~ C(unit)',data=data).fit()
home_table = sm.stats.anova_lm(home_lm,typ=2)
shop_table = sm.stats.anova_lm(shop_lm,typ=2)
print(home_table)
print(shop_table)

#~ data = pd.read_csv(os.path.join(rootdir,'e1-2016.csv'), index_col = 2)
data.set_index("unit", inplace=True)


all_homes = []
all_shops = []

i = 3

while i<=9:
    sample = data.loc[i, 'homes'].tolist()
    all_homes += [sample]
    sample = data.loc[i, 'shops'].tolist()
    all_shops += [sample]
    i += 1

print (stats.f_oneway(*all_homes))
print (stats.f_oneway(*all_shops))
print (stats.kruskal(*all_homes))
print (stats.kruskal(*all_shops))
with open(os.path.join(rootdir,'e2_anova.csv'),'w') as csvfile:
    csvwriter = csv.writer(csvfile, delimiter=',',quotechar='"',quoting=csv.QUOTE_MINIMAL)
    csvwriter.writerow(home_table)
    for row in np.asarray(home_table):
        csvwriter.writerow(row)
    csvwriter.writerow(shop_table)
    for row in np.asarray(shop_table):
        csvwriter.writerow(row)
