#!/usr/bin/zsh
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Milos Cernak, November 2015
#
# Run analysis of an input audio file
#
source Config.sh

inAudio=$1
inType=$2

if [[ -z $inAudio ]]; then
    echo "PhonVoc analysis: input audio not provided!"
    exit 1;
fi
if [[ $inType == "" ]]; then
    $inType=0
fi

if [[ ! -d steps ]]; then ln -sf $KALDI_ROOT/egs/wsj/s5/steps steps; fi
if [[ ! -d utils ]]; then ln -sf $KALDI_ROOT/egs/wsj/s5/utils utils; fi

# load phonological map
if [[ ! -e lang/$lang/${phon}-map.sh ]]; then
    echo "Please create lang/$lang/${phon}-map.sh"
    exit 1
fi
source lang/$lang/${phon}-map.sh

id=$inAudio:t:r
mkdir -p $id

if [[ $inType -eq 0 ]]; then
    echo "$id $inAudio" > $id/wav.scp
    echo "$id $voice" > $id/utt2spk
    echo "$voice $id" > $id/spk2utt
else
    echo -n "" > $id/wav.temp.scp
    for f in `cat $inAudio`; do
	echo "$f:t:r $f" >> $id/wav.temp.scp
    done
    cat $id/wav.temp.scp | sort > $id/wav.scp
    cat $id/wav.scp | awk -v voice=$voice '{print $1" "voice}' > $id/utt2spk
    cat $id/utt2spk | utils/utt2spk_to_spk2utt.pl | sort > $id/spk2utt
    rm $id/wav.temp.scp
fi

echo "-- MFCC extraction for $id input --"
steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --nj 1 --cmd "run.pl" $id $id/log $id/mfcc
steps/compute_cmvn_stats.sh $id $id/log $id/mfcc || exit 1;

echo "-- Feature extraction for $id input --"
feats="ark:copy-feats scp:$id/feats.scp ark:- |"
[ ! -r $id/cmvn.scp ] && echo "Missing $id/cmvn.scp" && exit 1;
feats="$feats apply-cmvn --norm-vars=false --utt2spk=ark:$id/utt2spk scp:$id/cmvn.scp ark:- ark:- |"
feats="$feats add-deltas --delta-order=2 ark:- ark:- |"

echo "-- Parameter extraction for paramType $paramType --"
if [[ $paramType -eq 0 || $paramType -eq 2 ]]; then
    nnet-forward train/dnns/pretrain-dbn-$lang/final.feature_transform "${feats}" ark:- | \
    nnet-forward train/dnns/${lang}-${phon}/phone-${hlayers}l-dnn/final.nnet ark:- ark,scp:$id/phone.ark,$id/phone.scp
fi
if [[ $paramType -eq 1 || $paramType -eq 2 ]]; then
    for att in "${(@k)attMap}"; do
	echo $att
	nnet-forward train/dnns/pretrain-dbn-$lang/final.feature_transform "${feats}" ark:- | \
        nnet-forward train/dnns/${lang}-${phon}/${att}-${hlayers}l-dnn/final.nnet ark:- ark:- | \
        select-feats 1 ark:- ark:$id/${att}.ark
    done
fi

if [[ $paramType -eq 0 ]]; then
    cp $id/phone.scp $id/feats.scp
else
    for att in "${(@k)attMap}"; do
    	atts+=( ark:$id/${att}.ark )
    done
    paste-feats $atts ark,scp:$id/paramType1.ark,$id/phnlfeats.scp
    cp $id/phnlfeats.scp $id/feats.scp

    if [[ $paramType -eq 2 ]]; then
	paste-feats scp:$id/phnlfeats.scp scp:$id/phone.scp ark,scp:$id/paramType2.ark,$id/feats.scp
    fi
fi

# TO BINARY
# count phonological classes
c=0
for att in "${(@k)attMap}"; do
    (( c = c + 1 ))
    echo $att $c
done
(( ce = c + 1 ))
# exit
cp $id/feats.scp $id/feats.continuous.scp
copy-feats scp:$id/feats.continuous.scp ark,t:- | \
    awk -v PHC=$c -v PHCE=$ce '{if (NF>2) {for(i=1; i<=PHC; i++) {printf "%1.0f ", $i} if ($PHCE != "") print $PHCE; else printf "\n"} else print $0}' | \
    copy-feats ark,t:- ark,scp:$id/feats.binary.ark,$id/feats.binary.scp
