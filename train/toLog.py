#!/usr/bin/env python
# a bar plot with errorbars
import sys
import numpy as np

inputFile=sys.argv[1]

hnr=np.genfromtxt(inputFile, dtype='float')
lhnr=np.log(hnr)

for hnr in lhnr:
  if ( hnr > 10):
    hnr=10;
  if ( hnr < -10):
    hnr=-10;
  
  print hnr
