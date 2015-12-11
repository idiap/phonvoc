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

if [[ $lang == 'English' ]]; then
    # Link WSJ audio in $ll
    for d in audio/wv1 audio/wv2
    do
	mkdir -p $ll/$d
	ln -sf $wsj0/$d/wsj0 $ll/$d/wsj0
	ln -sf $wsj1/$d/wsj1 $ll/$d/wsj1
    done

    # Create Kaldi data sets in $ll
    for n in init train dev; do
	echo $n
	mkdir -p $ll/data/${n}
	cat $ll/${n}.list.txt | awk -v ll=$ll '{ n=split($1,a,"/"); split(a[n],b,"."); print b[1]" "ll"/audio/wv1/"$0".wav" }' > $ll/data/${n}/files
	cat $ll/data/${n}/files | sort -u > $ll/data/${n}/wav.scp
	cat $ll/data/${n}/wav.scp | awk '{spk=substr($1,1,3); print $1" "spk}' > $ll/data/${n}/utt2spk
	cat $ll/data/${n}/utt2spk | utils/utt2spk_to_spk2utt.pl | sort > $ll/data/${n}/spk2utt
    done
fi

for n in train dev; do
    echo "-- Feature extraction for ${n} set --"
    mfccdir=feats/mfcc_${n}
    steps/make_mfcc.sh --mfcc-config ../conf/mfcc.conf --nj $N_JOBS --cmd "$extract_cmd" $ll/data/${n} $ll/data/${n}/log ${mfccdir}
    steps/compute_cmvn_stats.sh $ll/data/$n log/make_mfcc/$n $mfccdir || exit 1;
done
