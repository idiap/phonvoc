#!/usr/bin/python
#
# Copyright 2016 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Milos Cernak, Jan. 2016

import sys, re
import numpy as np

mean1=float(sys.argv[1])
std1 =float(sys.argv[2])
mean2=float(sys.argv[3])
std2 =float(sys.argv[4])
qbits =int(sys.argv[5])

nqlevels=2**qbits

cb1=np.linspace(mean1-3*std1, mean1+3*std1, num=nqlevels) # 7 quantisation levels - 3 bits
cb2=np.linspace(mean2-3*std2, mean2+3*std2, num=nqlevels) # 7 quantisation levels - 3 bits

# print cb1
# print cb2

# print nqlevels, cb
def quantize(value, qbook):
    N = len(qbook)
    qval=-1;
    if (value <= qbook[0]):
        qval = 0
    elif (value >= qbook[-1]):
        # print "Value %f is higher that %f" % (value, qbook[-2])
        qval = N-1
    else:
        for idx in range(0,N-1):
            # print idx, qbook[idx], qbook[idx+1]
            if (value > qbook[idx] and value < qbook[idx+1]):
                if (value < np.mean(qbook[idx:idx+2])):
                    qval = idx
                else:
                    qval = idx+1
                break
    return qbook[qval]

for line in sys.stdin:
    features=line.split( )
    N=len(features)
    for i, f in enumerate(features):
        #if i>1:
        cb = cb1
        if (float(f) < 1):
            cb = cb2
        if i==N-1:
            sys.stdout.write (str(quantize(float(f), cb))+'\n')
        else:
            sys.stdout.write (str(quantize(float(f), cb))+' ')
        #else:
        #    sys.stdout.write (f+' ')
