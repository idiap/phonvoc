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
if [[ -z $inAudio ]]; then
    echo "PhonVoc analysis: input audio not provided!"
    exit 1;
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
# Create Kaldi data sets in $ll
mkdir -p $id
cp $inAudio $id/$id.orig.wav

echo "id $inAudio" > $id/wav.scp
echo "id id" > $id/utt2spk
cp $id/utt2spk $id/spk2utt

echo "-- MFCC extraction for $id input --"
steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --nj 1 --cmd "run.pl" $id $id/log $id/mfcc
steps/compute_cmvn_stats.sh $id $id/log $id/mfcc || exit 1;

echo "-- Feature extraction for $id input --"
feats="ark:copy-feats scp:$id/feats.scp ark:- |"
[ ! -r $id/cmvn.scp ] && echo "Missing $id/cmvn.scp" && exit 1;
feats="$feats apply-cmvn --norm-vars=false --utt2spk=ark:$id/utt2spk scp:$id/cmvn.scp ark:- ark:- |"
feats="$feats add-deltas --delta-order=2 ark:- ark:- |"

if [[ $paramType -eq 0 || $paramType -eq 2 ]]; then
    nnet-forward train/dnns/pretrain-dbn-$lang/final.feature_transform "${feats}" ark:- | \
    nnet-forward train/dnns/${lang}-${phon}/phone-3l-dnn/final.nnet ark:- ark,scp:$id/phone.ark,$id/phonefeats.scp
fi
if [[ $paramType -eq 1 || $paramType -eq 2 ]]; then
    for att in "${(@k)attMap}"; do
	nnet-forward train/dnns/pretrain-dbn-$lang/final.feature_transform "${feats}" ark:- | \
        nnet-forward train/dnns/${lang}-${phon}/${att}-3l-dnn/final.nnet ark:- ark:- | \
        select-feats 1 ark:- ark:$id/${att}.ark
    done
fi

if [[ $paramType -eq 0 ]]; then
    cp $id/phonefeats.scp $id/feats.scp
else
    for att in "${(@k)attMap}"; do
	atts+=( ark:$id/${att}.ark )
    done
    paste-feats $atts ark,scp:$id/attributes.ark,$id/attfeats.scp
    cp $id/attfeats.scp $id/feats.scp

    if [[ $paramType -eq 2 ]]; then
	paste-feats scp:$id/attfeats.scp scp:$id/phonefeats.scp ark,scp:$id/paramType2.ark,$id/feats.scp
    fi
fi

