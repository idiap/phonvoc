#!/usr/bin/zsh
#
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
# See the file COPYING for the licence associated with this software.
#
# Prepare data and train Phonological Encoders (DNNs).
#
# Milos Cernak, Sept. 2015
#
echo Script: $0
source ../Config.sh

ll=../lang/$lang
trainMLF=$ll/analysis-train.mlf
adir=$ll/labels

if [[ ! -d $adir ]]; then
    mkdir -p $adir
fi

if [[ ! -e $ll/${phon}-map.sh ]]; then
    echo "Please create $ll/${phon}-map.sh"
    exit 1
fi
source $ll/${phon}-map.sh

feature_transform=dnns/pretrain-dbn-$lang/final.feature_transform
dbn=dnns/pretrain-dbn-$lang/3.dbn

if [[ $paramType -eq 0 || $paramType -eq 2 ]]; then
    echo "TRAIN (MONO)PHONETIC ANALYSIS"
    phonemes=`echo ${(@k)attRevMap} | sed 's/ /,/g'`
    echo "DNN training"
    dir=dnns/${lang}-${phon}/phone-3l-dnn
    (tail --pid=$$ -F $dir/_train_nnet.log 2>/dev/null)&
    (queue.pl -l gpu $dir/_train_nnet.log \
	      steps/train_nnet.sh --feature-transform $feature_transform \
	      --cmvn-opts "--norm-means=true --norm-vars=false"  \
	      --delta-opts "--delta-order=2" --dbn $dbn \
	      --hid-layers 0 --learn-rate 0.001 \
	      --labels "ark:$adir/phonfeats.post" --num-tgt 40 \
	      $ll/data/train/ $ll/data/dev/ lang-dummy \
	      ali-tr-dummy ali-cv-dummy $dir)& # || exit 1;
fi
if [[ $paramType -eq 1 || $paramType -eq 2 ]]; then
    echo "TRAIN PHONOLOGICAL ANALYSIS"
    for att in "${(@k)attMap}"; do
	echo $att: $attMap[$att]

	echo "Generating alignment"
	postAli=$adir/labels-${att}.ark
	# if [[ ! -s $postAli ]]; then
        tmpPost=$adir/post
        mlf2post.py $trainMLF $tmpPost $attMap[$att]         # create posteriors
        cat $tmpPost | sort | copy-post ark,t:- ark:$postAli # convert to ark
        rm -f $tmpPost
	# fi

	echo "DNN training"
	dir=dnns/${lang}-${phon}/${att}-3l-dnn
	(tail --pid=$$ -F $dir/_train_nnet.log 2>/dev/null)&
	(queue.pl -l gpu $dir/_train_nnet.log \
    	      steps/train_nnet.sh --feature-transform $feature_transform \
    	      --cmvn-opts "--norm-means=true --norm-vars=false"  \
    	      --delta-opts "--delta-order=2" --dbn $dbn \
    	      --hid-layers 0 --learn-rate 0.008 \
    	      --labels "ark:$postAli" --num-tgt 2 \
    	      $ll/data/train/ $ll/data/dev/ lang-dummy \
    	      ali-tr-dummy ali-cv-dummy $dir)& # || exit 1;
	# exit
    done
fi
