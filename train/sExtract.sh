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
if [[ $voice == "Nancy" ]]; then
    nancyDir=/idiap/temp/alaza/ImprovedLabels_Hui/lib/blizzard2011
    audio=$nancyDir/wavs
    datad=$ll/data/$voice
    cat $nancyDir/prompts.data_v2 | \
	awk -v audio=$audio '{print $1" "audio"/"$1".wav" }' > $datad/wav.scp
elif [[ $voice == "siwis" ]]; then
    siwisDir=/idiap/project/siwis/Siwis.04.09.2015
    find /idiap/project/siwis/Siwis.04.09.2015/FR/ -name "*.wav"
fi

if [[ ! -e $datad ]]; then
    mkdir -p $datad
fi

cat $datad/wav.scp | awk '{print $1" nan"}' > $datad/utt2spk
cat $datad/utt2spk | utils/utt2spk_to_spk2utt.pl | sort > $datad/spk2utt

echo "-- Feature extraction for $datad set --"
mfccdir=feats/mfcc_$voice
steps/make_mfcc.sh --mfcc-config ../conf/mfcc.conf --nj $N_JOBS --cmd "$extract_cmd" $datad $datad/log ${mfccdir}
steps/compute_cmvn_stats.sh $datad log/make_mfcc/$voice $mfccdir || exit 1;

