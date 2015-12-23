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
echo "Working in $artDir with dnns/${lang}-${phon}"

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
    nnet-forward dnns/${lang}-${phon}/phone-3l-dnn/final.nnet ark:- ark,scp:$ifeatdir/phone.ark,$ifeatdir/phonefeats.scp
EOF
	done
fi
if [[ $paramType -eq 1 || $paramType -eq 2 ]]; then
    for att in "${(@k)attMap}"; do
qsub $geOpts << EOF    
	nnet-forward dnns/pretrain-dbn-$lang/final.feature_transform "${feats}" ark:- | \
        nnet-forward dnns/${lang}-${phon}/${att}-3l-dnn/final.nnet ark:- ark:- | \
        select-feats 1 ark:- ark:$ifeatdir/${att}.ark
EOF
    done
fi

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
    for att in "${(@k)attMap}"; do
	atts+=( ark:$ifeatdir/${att}.ark )
    done
    paste-feats $atts ark,scp:$ifeatdir/paramType1.ark,$ifeatdir/phnlfeats.scp
    cp $ifeatdir/phnlfeats.scp $ifeatdir/feats.scp

    if [[ $paramType -eq 2 ]]; then
	paste-feats scp:$ifeatdir/phnlfeats.scp scp:$ifeatdir/phonefeats.scp ark,scp:$ifeatdir/paramType2.ark,$ifeatdir/feats.scp
    fi
fi

echo -n "nan" > $ifeatdir/spk2utt
cat $ifeatdir/feats.scp | awk '{ printf " %s", $1}END{print ""}' >> $ifeatdir/spk2utt
utils/spk2utt_to_utt2spk.pl $ifeatdir/spk2utt > $ifeatdir/utt2spk
steps/compute_cmvn_stats.sh $ifeatdir $ifeatdir $ifeatdir || exit 1;

# 5. Chunks the training data

# copy-feats ark:$ifeatdir/attributes.ark ark,t:- | awk 'BEGIN{l=0;j=0;}{if(match($1,"^s")){a=$1; printf "%s-%03d [ ", a, j; j++} else { print; if (++l % 625 == 0) {printf "]\n%s-%03d [ ", a, j; j++} if (match($0,"]$")){j=0;l=0}} }' | copy-feats ark,t:- ark,scp:$ifeatdir/katt.ark,$ifeatdir/feats.scp
