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
datad=$ll/data/$voice
if [[ ! -e $datad ]]; then
    mkdir -p $datad
fi

echo -n "" > $datad/wav.scp
if [[ -d $voiceData ]]; then
    find $voiceData -name "*.wav"  | \
	awk -F "/" '{ split($NF,a,"."); print a[1]" "$0 }' | sort > $datad/wav.scp
    cat $datad/wav.scp | awk -v voice=$voice '{print $1" "voice}' | sort > $datad/utt2spk
else
    echo "Synthesis training data does not exist"
    exit
fi

cat $datad/utt2spk | utils/utt2spk_to_spk2utt.pl | sort > $datad/spk2utt

echo "-- Feature extraction for $datad set --"
mfccdir=feats/mfcc_$voice
steps/make_mfcc.sh --mfcc-config ../conf/mfcc.conf --nj $N_JOBS --cmd "$extract_cmd" $datad $datad/log ${mfccdir}
steps/compute_cmvn_stats.sh $datad log/make_mfcc/$voice $mfccdir || exit 1;

