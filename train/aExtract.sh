#!/bin/zsh
#
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Milos Cernak, Sept. 2015
#
echo Script: $0
source ../Config.sh

ll=../lang/$lang

for n in dev-clean dev-other train-clean-100 train-clean-360 train-other-500; do
    dname=`echo $n | sed s/-/_/g`
    echo "-- Data preparation for $dname set --"
    local/data_prep.sh $data/$n $ll/data/$dname || exit 1
    echo "-- Feature extraction for $dname set --"
    mfccdir=feats/mfcc_$dname
    steps/make_mfcc.sh --mfcc-config ../conf/mfcc.conf --nj $N_JOBS --cmd "$extract_cmd" $ll/data/$dname $ll/data/$dname/log $mfccdir
    steps/compute_cmvn_stats.sh $ll/data/$dname log/make_mfcc/$dname $mfccdir || exit 1;
done
