#!/usr/bin/zsh
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Milos Cernak, November 2015
#
# Run synthesis of input data files
#
source Config.sh

inDir=$1
if [[ -e $inDir.$paramType.wav ]]; then
    exit 0;
fi
if [[ ! -e $inDir/feats.scp ]]; then
    echo "PhonVoc analysis: $inDir/feats.scp file does not exist!"
    exit 1;
fi

if [[ ! -d steps ]]; then ln -sf $KALDI_ROOT/egs/wsj/s5/steps steps; fi
if [[ ! -d utils ]]; then ln -sf $KALDI_ROOT/egs/wsj/s5/utils utils; fi

ift=train/dnns/pretrain-synthesis-dbn-${lang}-${voice}-paramType$paramType/final.feature_transform
infeats_tst="ark:nnet-forward $ift scp:$inDir/feats.scp ark:- |"
dnn=train/dnns/${hlayers}-${hdim}-${lrate}-${lang}-${voice}-${vocod}-paramType$paramType

if [ -e $dnn/cmvn_out_glob.ark ]; then
    echo "using $dnn/cmvn_out_glob.ark"
    cmvn-to-nnet --binary=false $dnn/cmvn_out_glob.ark - | \
	train/convert_transform.sh > $dnn/reverse_cmvn_out_glob.nnet
    nnet-forward --no-softmax=true $dnn/final.nnet "${infeats_tst}" ark,t:- | \
	nnet-forward --no-softmax=true $dnn/reverse_cmvn_out_glob.nnet ark:- ark,t:- | \
	awk -v dir=$inDir/ '($2 == "["){if (out) close(out); out=dir $1 ".lsf";}($2 != "["){if ($NF == "]") $NF=""; print $0 > out}'
  else
      nnet-forward --no-softmax=true $dnn/final.nnet "${infeats_tst}" ark,t:- | \
	  awk -v dir=$inDir/ '($2 == "["){if (out) close(out); out=dir $1 ".lsf";}($2 != "["){if ($NF == "]") $NF=""; print $0 > out}'
fi

# echo "toHTK.py $f $htk $hnr $pitch"
train/toHTK.py $inDir/id.lsf $inDir/$inDir.htk $inDir/$inDir.hnr $inDir/$inDir.f0
# rewrite synthesized pitch with the original one
$SSP_ROOT/codec.py -p -a -m 160 $inDir/$inDir.orig.wav $inDir/$inDir.f0
train/toLog.py $inDir/$inDir.f0 > $inDir/$inDir.orig.f0
hnrNum=`cat $inDir/$inDir.hnr | wc -l`
f0Num=`cat $inDir/$inDir.orig.f0 | wc -l`
(( f0Diff = hnrNum - f0Num ))
if [[ $f0Diff -le 0 ]]; then
    echo "orig pitch align: removing $f0Diff f0 frames"
    cat $inDir/$inDir.orig.f0 | head -n $hnrNum > $inDir/$inDir.f0
  else
    echo "orig pitch align: adding $f0Diff f0 frames"
    cp $inDir/$inDir.orig.f0 $inDir/$inDir.f0
    lastPitch=`cat $inDir/$inDir.orig.f0 | tail -n 1`
    for f ({1..$f0Diff}); do
      echo $lastPitch >> $inDir/$inDir.f0
    done 
fi

$SSP_ROOT/codec.py -d -a -l -m 160 -s 'cepgm' $inDir/$inDir.htk $inDir/$inDir.$paramType.wav
