import matplotlib.pyplot as plt
from datetime import datetime
from datetime import timedelta



name = list()
yellow_list = list()

blue_list = list()

cyan_list = list()

pink_list = list()



number=list()

grey_lits = list()

green_list = list()

black_list = list()


data_list=list()

current_day=list()
current_time=list()
line_list=list()
line_list_s=list()
f=open("/Dropbox/gama_workspace_1.8/project1/result/data.txt","r")

for line in f.readlines():
    data_list.append(line)

for line in data_list:
    current_list1 = line.split(" ")
    current_time.append(current_list1[1]+":"+current_list1[3])

for i in range((len(current_time))-1):
    now = datetime.strptime(current_time[i], "%d:%H:%M")
    now_next = now + timedelta(minutes=30)
    next = datetime.strptime(current_time[i + 1], "%d:%H:%M")
    if now_next==next:
        line_list.append(data_list[i])
    if i==len(current_time)-2:
        line_list.append(data_list[i+1])
        line_list_s.append(line_list)
        line_list = []
    if now_next!=next:
        line_list_s.append(line_list)
        line_list = []




def make_grag(data_list,currnt_experiment):
    only_yellow_list = list()
    only_blue_list = list()
    only_cyan_list = list()
    only_pink_list = list()
    only_number_list = list()
    only_grey_lits = list()
    only_green_list = list()
    only_black_list = list()
    for i in range(48):
        only_yellow_list.append(0)
        only_blue_list.append(0)
        only_pink_list.append(0)
        only_cyan_list.append(0)
        only_number_list.append(0)
        only_black_list.append(0)
        only_green_list.append(0)
        only_grey_lits.append(0)
    for line in data_list:
        current_list3 = line.split(" ")
        if current_list3[3] not in name:
            name.append(current_list3[3])
    for line in data_list:
        current_list2 = line.split(" ")
        for i in range(len(name)):
            if name[i] == current_list2[3]:
                only_yellow_list[i] = only_yellow_list[i] + float(current_list2[11])
                only_blue_list[i] = only_blue_list[i] + float(current_list2[9])
                only_pink_list[i] = only_pink_list[i] + float(current_list2[5])
                only_cyan_list[i] = only_cyan_list[i] + float(current_list2[7])
                only_grey_lits[i] = only_grey_lits[i] + float(current_list2[13])
                only_green_list[i] = only_green_list[i] + float(current_list2[15])
                only_black_list[i] = only_black_list[i] + float(current_list2[17])
                only_number_list[i] = only_number_list[i] + 1
    for i in range(len(only_yellow_list)):
        only_pink_list[i] = only_pink_list[i] / only_number_list[i]
        only_yellow_list[i] = only_yellow_list[i] / only_number_list[i]
        only_blue_list[i] = only_blue_list[i] / only_number_list[i]
        only_cyan_list[i] = only_cyan_list[i] / only_number_list[i]
        only_black_list[i] = only_black_list[i] / only_number_list[i]
        only_green_list[i] = only_green_list[i] / only_number_list[i]
        only_grey_lits[i] = only_grey_lits[i] / only_number_list[i]

    for i in range(len(only_pink_list)):
        if only_pink_list[i] != 0:
            only_pink_list[i] = only_pink_list[i]/20
    for i in range(len(only_grey_lits)):
        if only_grey_lits[i] != 0:
            only_grey_lits[i] = only_grey_lits[i]/40
    for i in range(len(only_blue_list)):
        if only_blue_list[i] != 0:
            only_blue_list[i] = only_blue_list[i]/40
    for i in range(len(only_yellow_list)):
        if only_yellow_list[i] != 0:
            only_yellow_list[i] = only_yellow_list[i]/50
    for i in range(len(only_black_list)):
        if only_black_list[i] != 0:
            only_black_list[i] = only_black_list[i]/40
    for i in range(len(only_green_list)):
        if only_green_list[i] != 0:
            only_green_list[i] = only_green_list[i]/20
    for i in range(len(only_cyan_list)):
        if only_cyan_list[i] != 0:
            only_cyan_list[i] = only_cyan_list[i]*5

    x = range(len(name))
    y1 = only_yellow_list
    y2 = only_blue_list
    y3 = only_pink_list
    y4 = only_cyan_list
    y5 = only_grey_lits
    y6 = only_green_list
    y7 = only_black_list
    yellow_list.append(only_yellow_list)
    blue_list.append(only_blue_list)
    pink_list.append(only_pink_list)
    cyan_list.append(only_cyan_list)
    grey_lits.append(only_grey_lits)
    green_list.append(only_green_list)
    black_list.append(only_black_list)

    plt.plot(x, y1, label='yellow line', linewidth=1, color='yellow', marker='o',
             markerfacecolor='yellow', markersize=2)
    plt.plot(x, y2, label='blue line', linewidth=1, color='blue', marker='o',
             markerfacecolor='blue', markersize=2)
    plt.plot(x, y3, label='pink line', linewidth=1, color='pink', marker='o',
             markerfacecolor='pink', markersize=2)
    plt.plot(x, y4, label='cyan line', linewidth=1, color='cyan', marker='o',
             markerfacecolor='cyan', markersize=2)
    plt.plot(x, y5, label='grey line', linewidth=1, color='grey', marker='o',
             markerfacecolor='grey', markersize=2)
    plt.plot(x, y6, label='green line', linewidth=1, color='green', marker='o',
             markerfacecolor='green', markersize=2)
#    plt.plot(x, y7, label='black line', linewidth=1, color='black', marker='o',
#            markerfacecolor='black', markersize=2)

    new_name=list()
    for i in range(len(name)):
        if i % 2 ==0:
            new_name.append(name[i])

    plt.xticks(x, name, rotation=45)
    plt.xlabel('time')
    plt.ylabel('cube number')
    plt.title("experiment " + str(currnt_experiment) + ": " + "average cube number")
    plt.legend()
    plt.show()

i=1
for k in line_list_s:
    if(len(k)>48):
        make_grag(k,i)
        i=i+1

def compare_graph(list,title):
    x=range(48)
    i = 1
    for k in list:
        if i%5==1:
            plt.plot(x, k, label="experiment " + str(i), linewidth=1, color="green", marker='o',
                     markerfacecolor="green", markersize=2)
        if i%5==2:
            plt.plot(x, k, label="experiment " + str(i), linewidth=1, color="red", marker='o',
                     markerfacecolor="red", markersize=2)
        if i%5==0:
          plt.plot(x, k, label="experiment " + str(i), linewidth=1, color="black", marker='o',
                 markerfacecolor="black", markersize=2)
        if i%5==3:
            plt.plot(x, k, label="experiment " + str(i), linewidth=1, color="blue", marker='o',
                     markerfacecolor="blue", markersize=2)
        if i%5==4:
            plt.plot(x, k, label="experiment " + str(i), linewidth=1, color="purple", marker='o',
                     markerfacecolor="purple", markersize=2)
        i=i+1
    plt.xticks(x, name, rotation=45)
    plt.xlabel('time')
    plt.ylabel('cube number')
    plt.title(title)
    plt.legend()
    plt.show()

compare_graph(yellow_list,"yellow compare")
compare_graph(blue_list,"blue compare")
compare_graph(pink_list,"pink compare")
compare_graph(grey_lits,"grey compare")
compare_graph(green_list,"green compare")
compare_graph(black_list,"black comapre")
compare_graph(cyan_list,"cyan compare")







