#!/usr/bin/zsh
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Milos Cernak, November 2015
#
source ../Config.sh

tst=../lang/$lang/data/$voice/itest

cp $tst/feats.scp $tst/feats.continuous.scp

copy-feats scp:$tst/feats.scp ark,t:- | \
    awk '{if (NF>2) {for(i=1; i<=15; i++) {printf "%1.0f ", $i} if ($16 != "") print $16; else printf "\n"} else print $0}' | \
    copy-feats ark,t:- ark,scp:$tst/feats.binary.ark,$tst/feats.binary.scp

cp $tst/feats.binary.scp $tst/feats.scp



