#!/usr/bin/zsh
#
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
# See the file COPYING for the licence associated with this software.
#
# Prepare data and train Phonological Encoders (DNNs).
#
# Milos Cernak, April 2016
#
echo Script: $0
source ../Config.sh

[ -f path.sh ] && . ./path.sh; 

ll=../lang/$lang
trainMLF=$ll/analysis-train.mlf
ldir=$ll/labels

if [[ ! -d $ldir ]]; then
    mkdir -p $ldir
fi

if [[ ! -e $ll/${phon}-map.sh ]]; then
    echo "Please create $ll/${phon}-map.sh"
    exit 1
fi
source $ll/${phon}-map.sh

feature_transform=dnns/pretrain-dbn-$lang/final.feature_transform
dbn=dnns/pretrain-dbn-$lang/$hlayers.dbn

#100 hour data
alignmnents=( feats/tri4b_ali_dev_clean feats/tri4b_ali_clean_100 )
mdl=feats/tri4b/final.mdl
# #460 hour data
# alignmnents=( feats/tri5b_ali_dev_clean feats/tri5b_ali_clean_460 )
# mdl=feats/tri5b/final.mdl
# #1000 hour data
# alignmnents=( feats/tri6b_ali_dev_clean feats/tri6b_ali_960 )
# mdl=feats/tri6b/final.mdl

geOpts=(
    -r y # Restart the job if the execution host crashes
    -b y # Pass a path, not a script, to the execution host
    -cwd # Retain working directory
    -V   # Retain environment variables
    -S /usr/bin/zsh
    # -e $ldir/log
    # -o $ldir/log
)

if [[ $paramType -eq 0 || $paramType -eq 2 ]]; then
    echo "TRAIN (MONO)PHONETIC ANALYSIS"

    echo "Generating alignment"
    postAli=$ldir/labels-phone.ark
    tmpPost=$ldir/phone-labels.txt
    
    echo -n "" > $tmpPost
    for aliDir in $alignmnents; do
    	nj=`cat $aliDir/num_jobs`
    	for n in {1..$nj}; do
    	    qsub $geOpts -e $ldir/aMapAlign.$n.e.log -o $ldir/aMapAlign.$n.log aMapAlign.sh $mdl $aliDir $n phone
    	    # exit
    	done
    	while true; do
    	    sleep 30
    	    njobs=`qstat | grep aMapAlign | wc -l`
    	    echo "$njobs aligners running"
    	    if [[ $njobs ==  0 ]]; then
    		break
    	    fi
    	done
    	cat $ldir/labels.*.txt >> $tmpPost
    	rm -f $ldir/labels.*.txt $ldir/*.log
    done
    cat $tmpPost | sort | copy-post ark,t:- ark:$postAli # convert to ark
    rm -f $tmpPost

    # ,hostname=gpub*
    echo "DNN training"
    dir=dnns/${lang}-${phon}/phone-${hlayers}l-dnn
    (tail --pid=$$ -F $dir/_train_nnet.log 2>/dev/null)&
    (queue.pl -l gpu,,hostname=gpub01 $dir/_train_nnet.log \
    	      steps/train_nnet.sh --feature-transform $feature_transform \
    	      --cmvn-opts "--norm-means=true --norm-vars=false"  \
    	      --delta-opts "--delta-order=2" --dbn $dbn \
    	      --hid-layers 0 --learn-rate 0.001 \
    	      --labels "ark:$postAli" --num-tgt 41 \
    	      $ll/data/train_960 $ll/data/dev_clean lang-dummy \
    	      ali-tr-dummy ali-cv-dummy $dir)& # || exit 1;
fi

if [[ $paramType -eq 1 || $paramType -eq 2 ]]; then
    echo "TRAIN PHONOLOGICAL ANALYSIS"
    for att in "${(@k)attMap}"; do
    	echo $att: $attMap[$att]

    	echo "Generating alignment"
    	postAli=$ldir/labels-${att}.ark
        tmpPost=$ldir/${att}-labels.txt

    	echo -n "" > $tmpPost
    	for aliDir in $alignmnents; do
    	    nj=`cat $aliDir/num_jobs`
    	    for n in {1..$nj}; do
    		qsub $geOpts -e $ldir/aMapAlign.$n.e.log -o $ldir/aMapAlign.$n.log aMapAlign.sh $mdl $aliDir $n $att
    	    done
    	    while true; do
    		sleep 30
    		njobs=`qstat | grep aMapAlign | wc -l`
    		echo "$njobs aligners running"
    		if [[ $njobs ==  0 ]]; then
    		    break
    		fi
    	    done
    	    cat $ldir/labels.*.txt >> $tmpPost
    	    rm -f $ldir/labels.*.txt $ldir/*.log
    	    # exit

    	done
    	cat $tmpPost | sort | copy-post ark,t:- ark:$postAli # convert to ark
	rm -f $tmpPost

	# echo "DNN training" ,h_vmem=8G
	dir=dnns/${lang}-${phon}/${att}-${hlayers}l-dnn
	(tail --pid=$$ -F $dir/_train_nnet.log 2>/dev/null)&
	(queue.pl -l gpu $dir/_train_nnet.log \
    	      steps/train_nnet.sh --feature-transform $feature_transform \
    	      --cmvn-opts "--norm-means=true --norm-vars=false"  \
    	      --delta-opts "--delta-order=2" --dbn $dbn \
    	      --hid-layers 0 --learn-rate 0.008 \
    	      --labels "ark:$postAli" --num-tgt 2 \
    	      $ll/data/train_clean_100 $ll/data/dev_clean lang-dummy \
    	      ali-tr-dummy ali-cv-dummy $dir)& # || exit 1;
	# exit
    done
fi
