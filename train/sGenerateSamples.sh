#!/usr/bin/zsh
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Milos Cernak, November 2015
#
source ../Config.sh

# vocod=cepgm-blaise
dbn=dnns/dbn-${lang}-${phon}-${voice}-paramType$paramType
dnn=dnns/${hlayers}-${hdim}-${lrate}-${lang}-${voice}-${phon}-${vocod}-paramType$paramType

tst=../lang/$lang/data/$voice/itest
otst=enc/${lang}-${phon}-${voice}-$vocod-paramType$paramType

echo "Working in $otst with $dnn"
# geLogDir=$otst/log
# if [[ ! -e $geLogDir ]]; then
#   mkdir -p $geLogDir
# fi

htkDir=$otst/htk
mkdir -p $htkDir

# geOpts=(
#     -r y # Restart the job if the execution host crashes
#     -b y # Pass a path, not a script, to the execution host
#     -cwd # Retain working directory
#     -V   # Retain environment variables
#     -S /usr/bin/python
#     -e $geLogDir
#     -o $geLogDir
# )

# if true; then
if false; then
    echo "re-synthesis only"
    otst=enc/${lang}-${voice}-$vocod-resynthesis-20ms
    if [[ ! -d $otst ]]; then
	mkdir $otst
    fi
    while read l; do
	id=`echo $l | awk '{print $1}'`
	echo $id
	htk=feats/out-${lang}-${voice}-cepgm/$id.htk
	# $SSP_ROOT/codec.py -d -a -l -m 160 -s 'cepgm' $htk $otst/$id.wav
	# $SSP_ROOT/codec.py -d -a -l -m 256 -s 'cepgm' $htk $otst/$id.wav
	$SSP_ROOT/codec.py -d -a -l -m 320 -s 'cepgm' $htk $otst/$id.wav
    done < $tst/feats.scp
    exit
fi

if [[ ! -d $otst/lsf ]]; then
  echo "Creating $otst/lsf"
  mkdir -p $otst/lsf

  # infeats_tst="ark:copy-feats scp:$tst/feats.scp ark:- |"
  ##apply input transform for splicing
  ift=$dbn/final.feature_transform
  infeats_tst="ark:nnet-forward $ift scp:$tst/feats.scp ark:- |"
  
  if [ -e $dnn/cmvn_out_glob.ark ]; then
    echo "using $dnn/cmvn_out_glob.ark"
    cmvn-to-nnet --binary=false $dnn/cmvn_out_glob.ark - | \
	convert_transform.sh > $dnn/reverse_cmvn_out_glob.nnet
    nnet-forward --no-softmax=true $dnn/final.nnet "${infeats_tst}" ark,t:- | \
	nnet-forward --no-softmax=true $dnn/reverse_cmvn_out_glob.nnet ark:- ark,t:- | \
	awk -v dir=$otst/lsf/ '($2 == "["){if (out) close(out); out=dir $1 ".lsf";}($2 != "["){if ($NF == "]") $NF=""; print $0 > out}'
  else
      nnet-forward --no-softmax=true $dnn/final.nnet "${infeats_tst}" ark,t:- | \
	  awk -v dir=$otst/lsf/ '($2 == "["){if (out) close(out); out=dir $1 ".lsf";}($2 != "["){if ($NF == "]") $NF=""; print $0 > out}'
  fi
fi

# exit
echo "Generating individual samples"
for f in `find $otst/lsf -name "*.lsf"`; do
  echo $f
  hnr=$htkDir/$f:t:r.hnr
  htk=$htkDir/$f:t:r.htk
  pitch=$htkDir/$f:t:r.f0
  wav=$htkDir/$f:t:r.wav
  # wav8k=$htkDir/$f:t:r.8k.wav

  # echo "toHTK.py $f $htk $hnr $pitch"
  toHTK.py $f $htk $hnr $pitch
  # SSP -s 'cepgm' with original pitch
  # origPitch=train/feats/out-${lang}-${phon}-${voice}-${vocod}/$f:t:r.f0
  origPitch=feats/out-${lang}-${voice}-${vocod}/$f:t:r.f0
  hnrNum=`cat $hnr | wc -l`
  f0Num=`cat $origPitch | wc -l`
  (( f0Diff = hnrNum - f0Num ))
  if [[ $f0Diff -le 0 ]]; then
    echo "orig pitch align: removing $f0Diff f0 frames"
    cat $origPitch | head -n $hnrNum > $pitch
  else
    echo "orig pitch align: adding $f0Diff f0 frames"
    cp $origPitch $pitch  
    lastPitch=`cat $origPitch | tail -n 1`
    for f ({1..$f0Diff}); do
      echo $lastPitch >> $pitch
    done 
  fi
  # qsub $geOpts -s 'cepgm'
  $SSP_ROOT/codec.py -d -a -l -m 160 -s 'cepgm' $htk $wav
  # $SSP_ROOT/codec.py -d -a -l -m 256 -s 'cepgm' $htk $wav
  # $SSP_ROOT/codec.py -d -a -l -m 320 -s 'cepgm' $htk $wav
  # sox $wav -r 8k $wav8k
  rm $htk $hnr $pitch

  # exit
done
