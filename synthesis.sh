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
inType=$2
hlayers=4

if [[ ! -e $inDir/feats.scp ]]; then
    echo "PhonVoc analysis: $inDir/feats.scp file does not exist!"
    exit 1;
fi
if [[ $inType == "" ]]; then
    $inType=0
fi

if [[ ! -d steps ]]; then ln -sf $KALDI_ROOT/egs/wsj/s5/steps steps; fi
if [[ ! -d utils ]]; then ln -sf $KALDI_ROOT/egs/wsj/s5/utils utils; fi
ift=train/dnns/dbn-${lang}-${phon}-${voice}-paramType$paramType/final.feature_transform
infeats_tst="ark:nnet-forward $ift scp:$inDir/feats.scp ark:- |"
dnn=train/dnns/${hlayers}-${hdim}-${lrate}-${lang}-${voice}-${phon}-${vocod}-paramType$paramType

# if true; then
if false; then
    echo "re-synthesis only"
    while read l; do
	id=`echo $l | awk '{print $1}'`
	echo $id
	htk=train/feats/out-${lang}-${voice}-cepgm/$id.htk
	# cp feats/out-${lang}-${phon}-${voice}-cepgm/$id.f0 feats/out-${lang}-${phon}-${voice}-cepgm/$id.hnr .
	$SSP_ROOT/codec.py -d -a -l -m 160 -s 'cepgm' $htk $inDir/$id.wav
	# rm $id.f0 $id.hnr
    done < $inDir/wav.scp
    exit
fi

if [ -e $dnn/cmvn_out_glob.ark ]; then
    echo "using $dnn/cmvn_out_glob.ark"
    # cmvn-to-nnet --binary=false $dnn/cmvn_out_glob.ark - | \
    # 	train/convert_transform.sh > $dnn/reverse_cmvn_out_glob.nnet
    nnet-forward --no-softmax=true $dnn/final.nnet "${infeats_tst}" ark,t:- | \
	nnet-forward --no-softmax=true $dnn/reverse_cmvn_out_glob.nnet ark:- ark,t:- | \
	awk -v dir=$inDir/ '($2 == "["){if (out) close(out); out=dir $1 ".lsf";}($2 != "["){if ($NF == "]") $NF=""; print $0 > out}'
  else
      nnet-forward --no-softmax=true $dnn/final.nnet "${infeats_tst}" ark,t:- | \
	  awk -v dir=$inDir/ '($2 == "["){if (out) close(out); out=dir $1 ".lsf";}($2 != "["){if ($NF == "]") $NF=""; print $0 > out}'
fi

typeset -A wavs
while read l; do
    id=`echo $l | awk '{print $1}'`
    wav=`echo $l | awk '{print $2}'`
    files+=( $id )
    wavs[$id]=$wav
done < $inDir/wav.scp

for f in $files; do
    echo $f
    train/toHTK.py $inDir/$f.lsf $inDir/$f.htk $inDir/$f.hnr $inDir/$f.f0
    # rewrite synthesized pitch with the original one
    $SSP_ROOT/codec.py -p -a -m 160 $wavs[$f] $inDir/$f.f0
    # cp train/feats/out-English-Nancy-cepgm/$f.f0 $inDir/$f.orig.f0
    train/toLog.py $inDir/$f.f0 > $inDir/$f.orig.f0
    hnrNum=`cat $inDir/$f.hnr | wc -l`
    f0Num=`cat $inDir/$f.orig.f0 | wc -l`
    (( f0Diff = hnrNum - f0Num ))
    if [[ $f0Diff -le 0 ]]; then
    	echo "orig pitch align: removing $f0Diff f0 frames"
    	cat $inDir/$f.orig.f0 | head -n $hnrNum > $inDir/$f.f0
    else
    	echo "orig pitch align: adding $f0Diff f0 frames"
    	cp $inDir/$f.orig.f0 $inDir/$f.f0
    	lastPitch=`cat $inDir/$f.orig.f0 | tail -n 1`
    	for d ({1..$f0Diff}); do
    	    echo $lastPitch >> $inDir/$f.f0
    	done 
    fi
    $SSP_ROOT/codec.py -d -a -l -m 160 -s 'cepgm' $inDir/$f.htk $inDir/$f.wav
done

