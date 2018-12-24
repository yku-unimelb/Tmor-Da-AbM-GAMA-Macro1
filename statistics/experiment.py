from mpl_toolkits.mplot3d import Axes3D
import matplotlib.pyplot as plt
from matplotlib import cm
from matplotlib.ticker import LinearLocator, FormatStrFormatter
import numpy as np
from matplotlib.colors import LogNorm
import math
import random


f2=open("/Dropbox/gama_workspace_1.8/project1/result/test2.txt","r")
f1=open("/Dropbox/gama_workspace_1.8/project1/result/test1.txt","r")


def getvalue(file_number):
    name = list()
    data_list = list()
    for line in file_number.readlines():
        data_list.append(line)
    only_number_list = list()
    only_yellow_list = list()
    only_blue_list = list()
    only_cyan_list = list()
    only_pink_list = list()
    only_grey_lits = list()
    only_green_list = list()
    only_black_list = list()
    for i in range(48):
        only_number_list.append(0)
        only_yellow_list.append([])
        only_blue_list.append([])
        only_pink_list.append([])
        only_cyan_list.append([])
        only_black_list.append([])
        only_green_list.append([])
        only_grey_lits.append([])
    for line in data_list[0:2016]:
        current_list3 = line.split(" ")
        if current_list3[3] not in name:
            name.append(current_list3[3])
    for line in data_list[0:2016]:
        current_list2 = line.split(" ")
        for i in range(len(name)):
            if name[i] == current_list2[3]:
                only_yellow_list[i].append((current_list2[11]))
                only_blue_list[i].append((current_list2[9]))
                only_pink_list[i].append((current_list2[5]))
                only_cyan_list[i].append((current_list2[7]))
                only_grey_lits[i].append(current_list2[25])
                only_green_list[i].append(current_list2[27])
                only_black_list[i].append(current_list2[29])
                only_number_list[i] = only_number_list[i] + 1
    return only_yellow_list,only_blue_list,only_pink_list,only_cyan_list,only_green_list,only_grey_lits,only_black_list,name



only_yellow_list1,only_blue_list1,only_pink_list1,only_cyan_list1,only_green_list1,only_grey_list1,only_black_list1,name=getvalue(f1)
only_yellow_list2,only_blue_list2,only_pink_list2,only_cyan_list2,only_green_list2,only_grey_list2,only_black_list2,name=getvalue(f2)
print(only_yellow_list2)

print(len(only_yellow_list2))
print(len(only_yellow_list2[0]))
all_color_list=list()
all_color_list.append((only_yellow_list1,only_yellow_list2))
all_color_list.append((only_blue_list1,only_blue_list2))
all_color_list.append((only_pink_list1,only_pink_list2))
all_color_list.append((only_cyan_list1,only_cyan_list2))
all_color_list.append((only_green_list1,only_green_list2))
all_color_list.append((only_grey_list1,only_grey_list2))


def time_as (number,color_list1,color_list2):
    if color_list1==color_list2:
        z=random.uniform(-1.645,0)
        print("equale")
        return z
    only_yellow_list1_int = list()
    only_yellow_list2_int = list()
    for i in color_list1[number]:
        only_yellow_list1_int.append(int(i))
    for i in color_list2[number]:
        only_yellow_list2_int.append(int(i))
    only_yellow_list2_int.sort()
    only_yellow_list1_int.sort()
    we_need_list = list()
    i = 0
    k = 0
    while (i <= len(only_yellow_list1_int) and k <= len(only_yellow_list2_int)):

        if i == len(only_yellow_list1_int) and k != len(only_yellow_list2_int):
            for i1 in range(k, len(only_yellow_list2_int)):
                we_need_list.append((only_yellow_list2_int[i1], 2))
            break
        if k == len(only_yellow_list2_int) and i != len(only_yellow_list1_int):
            for i2 in range(i, len(only_yellow_list1_int)):
                we_need_list.append((only_yellow_list1_int[i2], 1))
            break
        if k == len(only_yellow_list2_int) and i == len(only_yellow_list1_int):
            break
        if only_yellow_list1_int[i] < only_yellow_list2_int[k]:
            we_need_list.append((only_yellow_list1_int[i], 1))
            i = i + 1
            continue
        if only_yellow_list1_int[i] > only_yellow_list2_int[k]:
            we_need_list.append((only_yellow_list2_int[k], 2))
            k = k + 1
            continue
        if only_yellow_list1_int[i] == only_yellow_list2_int[k]:
            we_need_list.append((only_yellow_list1_int[i], 1))
            we_need_list.append((only_yellow_list2_int[k], 2))
            i = i + 1
            k = k + 1
            continue

    rank = list()
    for i in range(len(we_need_list)):
        rank.append(i + 1)

    same_position = {}
    for i in range(len(we_need_list)):
        if we_need_list[i][0] not in same_position:
            same_position[we_need_list[i][0]] = [i]
        else:
            same_position[we_need_list[i][0]].append(i)

    rank_sum = 0
    for k, v in same_position.items():
        for j in v:
            rank_sum = rank[j] + rank_sum
        rank_sum = rank_sum / len(v)
        for i in v:
            rank[i] = (rank_sum,)
        rank_sum = 0
    for i in range(len(we_need_list)):
        we_need_list[i] = we_need_list[i] + rank[i]
    rank1 = list()
    rank2 = list()
    for i in we_need_list:
        if i[1] == 1:
            rank1.append(i[2])
        if i[1] == 2:
            rank2.append(i[2])
    same_sum = 0
    for k, v in same_position.items():
        if len(v) > 1:
            same_sum = same_sum + len(v) ** 3 - len(v)

    z = (sum(rank1) - (42 * (42 + 42 + 1) / 2) + 0.5) / math.sqrt(((42 * 42 * (42 + 42 + 1) / 12) - ((42 * 42 * same_sum) / (12 * (42 + 42) * (42 + 42 - 1))))+1)
    return z


result=list()
fini=list()
for k in all_color_list:
    for i in range(48):
        result.append(time_as(i,k[0],k[1]))
        print(time_as(i,k[0],k[1]))
    fini.append(result)
    result=[]
    print("=============")

new_name=list()
for i in range(len(name)):
    if i % 2 ==0:
        new_name.append(name[i])
x=name

y1 = fini[0]
y2 = fini[1]
y3 = fini[2]
y4 = fini[3]
y5 = fini[4]
y6 = fini[5]
y7=list()
y8=list()

for i in range(48):
    y7.append(1.645)
    y8.append(-1.645)

plt.plot(x, y1, label='yellow cube', linewidth=1, color='yellow', marker='o',
             markerfacecolor='yellow', markersize=2)
plt.plot(x, y2, label='blue cube', linewidth=1, color='blue', marker='o',
             markerfacecolor='blue', markersize=2)
plt.plot(x, y3, label='pink cube', linewidth=1, color='pink', marker='o',
             markerfacecolor='pink', markersize=2)
plt.plot(x, y4, label='cyan cube', linewidth=1, color='cyan', marker='o',
             markerfacecolor='cyan', markersize=2)
plt.plot(x, y5, label='grey cell', linewidth=1, color='grey', marker='o',
             markerfacecolor='grey', markersize=2)
plt.plot(x, y6, label='green cell', linewidth=1, color='green', marker='o',
             markerfacecolor='green', markersize=2)
plt.plot(x, y7, label='stander', linewidth=2, color='red', marker='o',
             markerfacecolor='red', markersize=2)
plt.plot(x, y8, label='stander', linewidth=2, color='red', marker='o',
             markerfacecolor='red', markersize=2)

plt.xticks(x, name, rotation=45)
plt.xlabel('time')
plt.ylabel('rank')
plt.legend()
plt.show()


#color_name=["yellow","blue","pink","cyan","green","grey"]

#X = np.arange(len(color_name))
#X = np.arange(len(name))
#Y=fini[4]
#print(len(Y))




#print(y)
#plt.imshow(y, cmap=plt.cm.hot, vmin=0, vmax=1)
#plt.colorbar()
#plt.show()
