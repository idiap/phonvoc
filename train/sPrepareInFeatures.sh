#!/usr/bin/zsh
#
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
# See the file COPYING for the licence associated with this software.
#
# Extract phonological features from the audio book data
#
# Milos Cernak, Sept. 2015
#
source ../Config.sh

ll=../lang/$lang
# load phonological map
if [[ ! -e $ll/${phon}-map.sh ]]; then
    echo "Please create $ll/${phon}-map.sh"
    exit 1
fi
source $ll/${phon}-map.sh

geLogDir=log
artDir=`cd $(dirname $0); pwd`
echo "Working in $artDir with dnns/${lang}-${phon}-${voice}"

if [[ ! -e $geLogDir ]]; then
  mkdir -p $geLogDir
fi

geOpts=(
    -r y # Restart the job if the execution host crashes
    # -b y # Pass a path, not a script, to the execution host
    -cwd # Retain working directory
    -V   # Retain environment variables
    # -S /usr/bin/python2
    -e $geLogDir
    -o $geLogDir
    # -l q1d
    -l h_vmem=4G
)

data=$ll/data/$voice

# read the features,
feats="ark:copy-feats scp:$data/feats.scp ark:- |"
# add per-speaker CMVN,
[ ! -r $data/cmvn.scp ] && echo "Missing $data/cmvn.scp" && exit 1;
feats="$feats apply-cmvn --norm-vars=false --utt2spk=ark:$data/utt2spk scp:$data/cmvn.scp ark:- ark:- |"
# add deltas,
feats="$feats add-deltas --delta-order=2 ark:- ark:- |"

ifeatdir=feats/in-${lang}-${phon}-${voice}
if [[ ! -e $ifeatdir ]]; then
  mkdir -p $ifeatdir
fi

if [[ $paramType -eq 0 ]]; then
    forwardDNNs="phone"
elif [[ $paramType -eq 1 ]]; then
    forwardDNNs="${(@k)attMap}"
else
    forwardDNNs="${(@k)attMap} phone"
fi

echo "-- Forward pass for $data set with param $paramType --"
if [[ $paramType -eq 0 || $paramType -eq 2 ]]; then
	mfcc=feats/mfcc_$voice
	for n in $(seq $N_JOBS); do
	    feats="ark:copy-feats scp:$mfcc/raw_mfcc_$voice.$n.scp ark:- |"
	    [ ! -r $data/cmvn.scp ] && echo "Missing $data/cmvn.scp" && exit 1;
	    feats="$feats apply-cmvn --norm-vars=false --utt2spk=ark:$data/utt2spk scp:$data/cmvn.scp ark:- ark:- |"
	    feats="$feats add-deltas --delta-order=2 ark:- ark:- |"
qsub $geOpts << EOF    
    nnet-forward dnns/pretrain-dbn-$lang/final.feature_transform "${feats}" ark:- | \
    nnet-forward dnns/${lang}-${phon}/phone-3l-dnn/final.nnet ark:- ark,scp:$id/phone.ark,$id/phonefeats.scp
EOF
fi
if [[ $paramType -eq 1 || $paramType -eq 2 ]]; then
    for att in "${(@k)attMap}"; do
qsub $geOpts << EOF    
	nnet-forward dnns/pretrain-dbn-$lang/final.feature_transform "${feats}" ark:- | \
        nnet-forward dnns/${lang}-${phon}/${att}-3l-dnn/final.nnet ark:- ark:- | \
        select-feats 1 ark:- ark:$id/${att}.ark
EOF
    done
fi

# for att in $forwardDNNs; do
#     # att=Voiced
#     echo "Forward pass of $att"
#     if [[ $att = "phone" ]]; then
# 	mfcc=feats/mfcc_$voice
# 	for n in $(seq $N_JOBS); do
# 	    feats="ark:copy-feats scp:$mfcc/raw_mfcc_$voice.$n.scp ark:- |"
# 	    [ ! -r $data/cmvn.scp ] && echo "Missing $data/cmvn.scp" && exit 1;
# 	    feats="$feats apply-cmvn --norm-vars=false --utt2spk=ark:$data/utt2spk scp:$data/cmvn.scp ark:- ark:- |"
# 	    feats="$feats add-deltas --delta-order=2 ark:- ark:- |"
# qsub $geOpts << EOF    
#     nnet-forward dnns/pretrain-dbn-$lang/final.feature_transform "${feats}" ark:- | \
#     nnet-forward dnns/${lang}-${phon}/${att}-3l-dnn/final.nnet ark:- ark,scp:$ifeatdir/${att}.$n.ark,$ifeatdir/${att}.$n.scp
# EOF
# 	done
#     else
# qsub $geOpts << EOF    
#     nnet-forward dnns/pretrain-dbn-$lang/final.feature_transform "${feats}" ark:- | \
#     nnet-forward dnns/${lang}-${phon}/${att}-3l-dnn/final.nnet ark:- ark:- | \
#     select-feats 1 ark:- ark:$ifeatdir/${att}.ark
# EOF
#     fi
# # exit
# done

while true; do
    sleep 10
    njobs=`qstat | grep STDIN | wc -l`
    echo "$njobs detectors running"
    if [[ $njobs ==  0 ]]; then
      break
    fi
done
# exit
# 4. Merging

if [[ $paramType -eq 0 ]]; then
    cp $ifeatdir/phonefeats.scp $ifeatdir/feats.scp
else
    if [[ $phon == "SPE" ]]; then
	paste-feats ark:$id/sil.ark ark:$id/vocalic.ark ark:$id/consonantal.ark ark:$id/high.ark ark:$id/back.ark ark:$id/low.ark ark:$id/anterior.ark ark:$id/coronal.ark ark:$id/round.ark ark:$id/ris.ark ark:$id/tense.ark ark:$id/voice.ark ark:$id/continuant.ark ark:$id/nasal.ark ark:$id/strident.ark ark,scp:$id/attributes.ark,$id/attfeats.scp
        cp $id/attfeats.scp $id/feats.scp
	rm -f $id/sil.ark $id/vocalic.ark $id/consonantal.ark $id/high.ark $id/back.ark $id/low.ark $id/anterior.ark $id/coronal.ark $id/round.ark $id/ris.ark $id/tense.ark $id/voice.ark $id/continuant.ark $id/nasal.ark $id/strident.ark
    fi
    if [[ $paramType -eq 2 ]]; then
	paste-feats scp:$id/attfeats.scp scp:$id/phonefeats.scp ark,scp:$id/paramType2.ark,$id/feats.scp
    fi
fi



if [[ $paramType -eq 0 ]]; then
    phone_arks=""
    for n in $(seq $N_JOBS); do
	phone_arks="$phone_arks ark:$ifeatdir/${att}.$n.ark"
	cat $ifeatdir/${att}.$n.scp || exit 1;
    done > $ifeatdir/feats.scp
else
    if [[ $phon == "SPE" ]]; then
	paste-feats ark:$ifeatdir/sil.ark ark:$ifeatdir/vocalic.ark ark:$ifeatdir/consonantal.ark ark:$ifeatdir/high.ark ark:$ifeatdir/back.ark ark:$ifeatdir/low.ark ark:$ifeatdir/anterior.ark ark:$ifeatdir/coronal.ark ark:$ifeatdir/round.ark ark:$ifeatdir/ris.ark ark:$ifeatdir/tense.ark ark:$ifeatdir/voice.ark ark:$ifeatdir/continuant.ark ark:$ifeatdir/nasal.ark ark:$ifeatdir/strident.ark ark,scp:$ifeatdir/paramType1.ark,$ifeatdir/attfeats.scp
    fi
    if [[ $paramType -eq 2 ]]; then
	paste-feats scp:$ifeatdir/attfeats.scp scp:$ifeatdir/phonefeats.scp ark,scp:$ifeatdir/paramType2.ark,$ifeatdir/feats.scp
    fi
fi

echo -n "nan" > $ifeatdir/spk2utt
cat $ifeatdir/feats.scp | awk '{ printf " %s", $1}END{print ""}' >> $ifeatdir/spk2utt
utils/spk2utt_to_utt2spk.pl $ifeatdir/spk2utt > $ifeatdir/utt2spk
steps/compute_cmvn_stats.sh $ifeatdir $ifeatdir $ifeatdir || exit 1;

# 5. Chunks the training data

# copy-feats ark:$ifeatdir/attributes.ark ark,t:- | awk 'BEGIN{l=0;j=0;}{if(match($1,"^s")){a=$1; printf "%s-%03d [ ", a, j; j++} else { print; if (++l % 625 == 0) {printf "]\n%s-%03d [ ", a, j; j++} if (match($0,"]$")){j=0;l=0}} }' | copy-feats ark,t:- ark,scp:$ifeatdir/katt.ark,$ifeatdir/feats.scp
