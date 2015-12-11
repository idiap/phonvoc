#!/usr/bin/env python
# Copyright 2014 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Milos Cernak, Oct 2014
#
import sys
import numpy as np
from struct import pack, unpack
from os import makedirs
from os.path import dirname, exists

# mcepFile=sys.argv[1]
inputFile=sys.argv[1]
htkFile=sys.argv[2]
hnrFile=sys.argv[3]
pitchFile=sys.argv[4]

alpha=0.5 # formant enhancement
D=24      # LPC order

# HTK parameter kinds
parmKind = {
    "LPC":       1,
    "LPREFC":    2,
    "LPCEPSTRA": 3,
    "MFCC":      6,
    "FBANK":     7,
    "MELSPEC":   8,
    "USER":      9,
    "PLP":      11,
    "E":   0000100,
    "N":   0000200,
    "D":   0000400,
    "A":   0001000,
    "Z":   0004000,
    "0":   0020000,
    "T":   0100000
}

# Sink to HTK file
def HTKSink(fileName, a, period=0.01, kind="USER", native=False):
    if (a.ndim != 2):
        print "Dimension must be 2, not %d" % (a.ndim)
        exit(1)

    htkKind = 0
    for k in kind.split('_'):
        htkKind |= parmKind[k]
    htkPeriod = period * 1e7 + 0.5
    fmt = '>iihh'
    if native:
        fmt = 'iihh'
    header = pack(fmt, a.shape[0], htkPeriod, a.shape[1]*4, htkKind)

    dir = dirname(fileName)
    if dir and not exists(dir):
        makedirs(dir)
    with open(fileName, 'wb') as f:
        # Need to create a new array here of type float32 ('f') such
        # that it is written as 4 bytes.  Casting doesn't seem to
        # work.
        f.write(header)
        v = np.array(a, dtype='f')
        if ((not native) and (sys.byteorder == 'little')):
            v = v.byteswap()
        v.tofile(f)

# mcep=np.genfromtxt(mcepFile, dtype='float')
lsf=np.genfromtxt(inputFile, dtype='float')
# pitch=lsf[:,-1]
# lhnr=lsf[:,-2]
# sf=lsf[:,:-2]

# pitch=lsf[:,26]
# lhnr=lsf[:,25]
# sf=lsf[:,0:25]

#-s 'cepgm' French
pitch=lsf[:,28]
lhnr=lsf[:,27]
#-s 'synth' French
# pitch=lsf[:,26]
# lhnr=lsf[:,25]
# # # sf=lsf[:,0:27]

# formant enhancement accorging to
# http://festvox.org/blizzard/bc2006/ustc_blizzard2006.pdf
[m,n]=np.shape(lsf)
sf=np.zeros((m,n))
sf[:,0]=lsf[:,0]
d=alpha*(lsf[:,1]-lsf[:,0])
for i in range(1,D-1):
    di=alpha*(lsf[:,i+1]-lsf[:,i])
    d2=np.power(d,2)
    di2=np.power(di,2)
    sf[:,i]=lsf[:,i-1]+d+(lsf[:,i+1]-lsf[:,i-1]-di-d)*d2/(d2+di2)
    d=di
sf[:,23:n]=lsf[:,23:n]

# # write out mcep
# np.savetxt(mcepOutFile,sf,fmt='%2.7f',delimiter='\t')

# write htk
HTKSink(htkFile, sf[:,0:27])
# write htk
# HTKSink(htkFile, sf[:,0:25])
# # write smoothed
# HTKSink(htkFile, mcep)

# write hnr
hnr=np.exp(lhnr)
with open(hnrFile, 'w') as f:
    for l in hnr:
        f.write("%f\n" % l)

with open(pitchFile, 'w') as f:
    for l in pitch:
        f.write("%f\n" % l)
