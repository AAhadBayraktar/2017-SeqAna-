#!/bin/python 3
# Abdulahad Bayraktar
import os
import re
import math
import sys

a = open(sys.argv[1]).readlines()

x = sys.argv[2]
count = 0
ad_header = str(x) + ".AD"
adr_header = str(x) + ".ADR"
adrl_header = str(x) + ".ADRL"
adr = ""
adrl= ""
for c in a[1:len(a)]:
    count += 1
    colInd = a[0].split("\t").index(ad_header)
    try:
        b = c.split("\t")[colInd].strip('\"').split(',')
        if(len(b)==2):
            try:
                adr = str(abs(int(b[0])-int(b[1]))/(int(b[0])+int(b[1])))
            except Exception as e:
                adr = "zero depth"
            try:
                adrl= str(math.log10(int(b[0])+int(b[1]))*float(adr))
            except Exception as e:
                adrl= "zero depth"
            a[count] = re.sub("\n","\t"+adr+"\t"+adrl+"\n",c)
        else:
                a[count] = re.sub("\n","\tNA\tNA\n",c)
    except IndexError:
        None
        
a[0] = re.sub("\n","\t"+adr_header+"\t"+adrl_header+"\n",a[0])

    
f = open(sys.argv[1],"w+")
for i in a:
    f.write(i)
f.close
