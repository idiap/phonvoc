#!/bin/zsh
#
# Copyright 2016 by Idiap Research Institute, http://www.idiap.ch
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Milos Cernak, Aug. 2016
#

########## MODIFY TO FIT YOUR ENVIRONMENT##############################
# Allow setshell
software=/idiap/resource/software
source $software/initfiles/shrc $software

export SSP_ROOT=/idiap/user/mcernak/Projects/ssp
# some speech common libraries
. /idiap/group/speech/common/lib/profile.sh

SETSHELL htk
SETSHELL sptk
SETSHELL kaldi

if [[ ! -d steps ]]; then ln -sf $KALDI_ROOT/egs/wsj/s5/steps steps; fi
if [[ ! -d utils ]]; then ln -sf $KALDI_ROOT/egs/wsj/s5/utils utils; fi

# Check for KALDI; add it to the path
if [ "$KALDI_ROOT" = "" ]
then
    echo
    "Please \"SETSHELL kaldi\" or point \$KALDI_ROOT to an KALDI
installation"
    exit 1
fi
# Check for SSP; add it to the path
if [ "$SSP_ROOT" = "" ]
then
    echo
    "Please install https://github.com/idiap/ssp and set \$ISS_ROOT"
    exit 1
fi

export PATH=$PWD/utils/:$PWD:$PATH

export phon=SPE
export lang=English
export voice=Anna

export vocod=cepgm
export lrate=0.001
export hlayers=4
export hdim=1024
export paramType=1

#######################################################################

inFile=$1
if [[ ! -e $inFile ]]; then
    echo cannot access the input file $inFile
    exit
fi

outFile=$2
if [[ $outFile == "" ]];then
    outFile=$inFile:t:r.nn.wav
fi

# load phonological map
if [[ ! -e ../lang/$lang/${phon}-map.sh ]]; then
    echo "Please create ../lang/$lang/${phon}-map.sh"
    exit 1
fi
source ../lang/$lang/${phon}-map.sh

id=$inFile:t:r
mkdir -p $id

### ENCODING ########################################
# 1. Phonological analysis using Deep NNs
echo "$id $inFile" > $id/wav.scp
echo "$id $voice" > $id/utt2spk
echo "$voice $id" > $id/spk2utt

echo "-- MFCC extraction for $id input --"
steps/make_mfcc.sh --mfcc-config ../conf/mfcc.conf --nj 1 \
		   --cmd "run.pl" $id $id/log $id/mfcc
steps/compute_cmvn_stats.sh $id $id/log $id/mfcc || exit 1;

echo "-- Feature extraction for $id input --"
feats="ark:copy-feats scp:$id/feats.scp ark:- |"
[ ! -r $id/cmvn.scp ] && echo "Missing $id/cmvn.scp" && exit 1;
feats="$feats apply-cmvn --norm-vars=false --utt2spk=ark:$id/utt2spk scp:$id/cmvn.scp ark:- ark:- |"
feats="$feats add-deltas --delta-order=2 ark:- ark:- |"

echo "-- Phonological analysis (forward pass) --"
for att in "${(@k)attMap}"; do
    echo $att
    nnet-forward ../train/dnns/pretrain-dbn-$lang/final.feature_transform "${feats}" ark:- | \
	nnet-forward ../train/dnns/${lang}-${phon}/${att}-${hlayers}l-dnn/final.nnet ark:- ark:- | \
	select-feats 1 ark:- ark:$id/${att}.ark
    atts+=( ark:$id/${att}.ark )
done
paste-feats $atts ark,scp:$id/paramType1.ark,$id/phnlfeats.scp

echo "-- Conversion to binary phonological posteriors --"
# count phonological classes
c=0
for att in "${(@k)attMap}"; do
    (( c = c + 1 ))
    echo $att $c
done
(( ce = c + 1 ))
cp $id/phnlfeats.scp $id/feats.continuous.scp
copy-feats scp:$id/phnlfeats.scp ark,t:- | \
    awk -v PHC=$c -v PHCE=$ce '{if (NF>2) {for(i=1; i<=PHC; i++) {printf "%1.0f ", $i} if ($PHCE != "") print $PHCE; else printf "\n"} else print $0}' | \
    copy-feats ark,t:- ark,scp:$id/feats.binary.ark,$id/phnlbin.scp

# 2. Syllable boundary extraction using Spiking NN
echo "-- Syllable boundary detection --"
HCopy -C ../conf/PLP_0.cfg $inFile $id/$id.htk
bin/nsylb -i $id/$id.htk > $id/$id.nsylb

echo "-- Continuous F0 extraction, DLOP pram. & quantization --"
$SSP_ROOT/codec.py -a -p -m 160 $inFile $id/$id.f0
cat $id/$id.f0 | x2x +af | sopr -LN > $id/$id.lf0
cat $id/$id.lf0 | x2x +fa > $id/$id.lf0.txt
# 2nd order DLOP
bin/dlop -f $id/$id.lf0 -l $id/$id.nsylb \
	 -t $id/$id.dlop -p $id/$id.dec.lf0 -n 2
# quantization
x2x +fa $id/$id.dlop | bquant.py 5.2518 0.2639 -0.0061 0.0957 3 | \
    x2x +af > $id/$id.q2.dlop
bin/dlop -f $id/$id.lf0 -q $id/$id.q2.dlop \
	 -l $id/$id.nsylb -t $id/$id.2.dlop \
	 -p $id/$id.qdec.lf0 -n 2

# gnuplot -e "p '$id/$id.lf0.txt' title 'LogF0', '$id/$id.dec.lf0' title 'DLOP 2nd order LogF0'"

### DECODING ########################################
# 3. Phonological synthesis using Deep NN

ift=../train/dnns/dbn-${lang}-${phon}-${voice}-paramType$paramType/final.feature_transform
infeats_tst="ark:nnet-forward $ift scp:$id/phnlbin.scp ark:- |"
dnn=../train/dnns/${hlayers}-${hdim}-${lrate}-${lang}-${voice}-${phon}-${vocod}-paramType$paramType

echo "-- Phonological synthesis (forward pass) --"
nnet-forward --no-softmax=true $dnn/final.nnet "${infeats_tst}" ark,t:- | \
    nnet-forward --no-softmax=true $dnn/reverse_cmvn_out_glob.nnet ark:- ark,t:- | \
    awk -v dir=$id/ '($2 == "["){if (out) close(out); out=dir $1 ".lsf";}($2 != "["){if ($NF == "]") $NF=""; print $0 > out}'

echo "-- Phonological synthesis (LPC re-synthesis) --"
../train/toHTK.py $id/$id.lsf $id/$id.htk $id/$id.hnr $id/$id.synth.f0
hnrNum=`cat $id/$id.hnr | wc -l`
f0Num=`cat $id/$id.qdec.lf0 | wc -l`
(( f0Diff = hnrNum - f0Num + 4 ))
if [[ $f0Diff -le 0 ]]; then
    echo "orig pitch align: removing $f0Diff f0 frames"
    cat $id/$id.qdec.lf0 | tail -n +4 | head -n $hnrNum > $id/$id.f0
else
    echo "orig pitch align: adding $f0Diff f0 frames"
    cp $id/$id.qdec.lf0 $id/$id.f0
    lastPitch=`cat $id/$id.qdec.lf0 | tail -n 1`
    ((f0Diff = f0Diff - 4)) #jiangkid's fix
    for d ({1..$f0Diff}); do
    	echo $lastPitch >> $id/$id.f0
    done 
fi
$SSP_ROOT/codec.py -d -a -l -m 160 -s 'cepgm' $id/$id.htk $outFile
echo "-- Encoded: $inFile, Decoded: $outFile --"
