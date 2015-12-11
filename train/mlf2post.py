#!/usr/bin/env python2
#
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Milos Cernak, April 2015
#
# Converts HTK mlf to Kaldi posterior aligment
#

import sys, re, os

if len(sys.argv) != 4:
    print "USAGE: %s inlabel.mlf outlabel.post phonemes" % sys.argv[0]
    sys.exit()

phonemes = sys.argv[3].split(',')
unikeys={}

# wasFirst=0
fw = open(sys.argv[2], 'w')
with open(sys.argv[1], 'r') as f:
    for line in f.readlines():
        # print "%s" % line
        if re.search("^#", line):
            # print "skipping %s" % line
            continue
        elif re.search("^\"", line):
            # if wasFirst:
            #     fw.write("\n")
                # sys.exit(0)
            # line = re.sub(r"^\"\.\.\.\/", "", line)
            # line.replace(line[:5],'')
            line = re.sub(r"\.lab\"$", "", line[33:])
            line = line.rstrip('\r\n')
            if unikeys.has_key(line):
                writeLabels=False
            else:
                unikeys[line]=1
                fw.write(line)
                writeLabels=True
            # wasFirst=1
        elif re.search("^\.", line):
            if writeLabels:
                fw.write("\n")
        else:
            if writeLabels:
                items = line.split()
                triphone = items[2]
                items[2] = '0' # label no = 2
                for p in phonemes:
                    regex = re.compile('^%s$' % p)
                    #if (p == 'sil'):
                    #    regex = re.compile('^sil$')
                    #else:
                    #    regex = re.compile('-%s\+' % p)
                
                    if regex.search(triphone):
                        items[2] = '1' # label yes = 1
                        break

                # convert interval to frames
                d = int(items[1]) - int(items[0])
                d = d / 10e4 # 10ms frame shift
                while d > 0:
                    fw.write(" [ %s 1 ]" % items[2])
                    d = d - 1
                # fw.write("%s %s %s\n" % (items[0], items[1], items[2]))

fw.write("\n")
fw.close()
