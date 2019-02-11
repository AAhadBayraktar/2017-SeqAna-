#!/bin/python 3
# Abdulahad Bayraktar
import os
import re
import math
import sys

a = open(sys.argv[1]).readlines()

arg2 = sys.argv[2]
count = 0
genotype_header = str(arg2) + ".GT"
zygosity_header = str(arg2) + ".Zygosity"
for c in a[1:len(a)]:
    count += 1
    colInd = a[0].strip("\n").split("\t").index(genotype_header)
    try:
        c = c.strip("\n").split("\t")
        c[colInd] = re.sub("\|","/",c[colInd].strip("\""))
        ref = c[a[0].strip("\n").split("\t").index("Ref")]
        alt = c[a[0].strip("\n").split("\t").index("Alt")]
        b = c[colInd].split("/")
        c = "".join(str(x+"\t") for x in c).strip("\t")+"\n"
        if(b[0]=="NA"):
            a[count] = re.sub("\n","\tunavailable\n",c)
        elif(b[0]==b[1]):
            if(b[0]==ref):
                a[count] = re.sub("\n","\thom ref\n",c)
            elif(b[0]==alt):
            	a[count] = re.sub("\n","\thom alt\n",c)
            elif(b[0]=="."):
                a[count] = re.sub("\n","\tmissing\n",c)
        elif(b[0]!=b[1]):
            a[count] = re.sub("\n","\thet\n",c)
    except IndexError:
        None
#    print(c)
#    print(b,ref,alt)
#    print(a[count])

a[0] = re.sub("\n","\t"+zygosity_header+"\n",a[0])
    
f = open(sys.argv[1],"w+")
for i in a:
    f.write(i)
f.close
