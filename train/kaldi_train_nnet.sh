#!/bin/bash
#
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Milos Cernak, November 2015
#
# Copyright 2012  Karel Vesely, Shakti Rath (Brno University of Technology)
# Apache 2.0

# Begin configuration.

# nnet config
model_size=8000000 # nr. of parameteres in MLP
hid_layers=6      # nr. of hidden layers (prior to sotfmax or bottleneck)
bn_dim=           # set value to get a bottleneck network
hid_dim=          # set this to override the $model_size
mlp_init=         # set this to override MLP initialization
dbn=              # set the DBN to use for hidden layers
input_feature_transform= # set the feature transform in front of the trained MLP
feature_transform= # set the feature transform at the back of the trained MLP
speak_transform=         # file that contains the fmllr transformations
# training config
learn_rate=0.008  # initial learning rate
momentum=0.0      # momentum
l1_penalty=0.0     # L1 regualrization constant (lassoo)
l2_penalty=0.0     # L2 regualrization constant (weight decay)
# data processing config
bunch_size=40     # size of the training block
cache_size=100000   # size of the randomization cache
randomize=true    # do the frame level randomization
copy_feats=false   # resave the features in the re-shuffled order to tmpdir (faster reading)
# feature config
delta_order=0
apply_cmvn=false
apply_minmax=true
norm_vars=true # normalize the FBANKs (CVN)
apply_glob_cmvn=true
splice_lr=5    # temporal splicing
splice_step=1   # stepsize of the splicing (1 is no gap between frames, just like splice_feats does)
feat_type=plain
traps_dct_basis=11 # nr. od DCT basis (applies to `traps` feat_type, splice10 )
lda_rand_prune=4.0 # LDA estimation random pruning (applies to `lda` feat_type)
lda_dim=350        # LDA dimension (applies to `lda` feat_type)
mlpOption="--gauss --negbias --linOutput"
activationOutput="<sigmoid>"

# scheduling config
min_iters=10    # set to enforce minimum number of iterations
max_iters=20  # maximum number of iterations
start_halving_inc=0.01 # frm-accuracy improvement ratio to begin learn_rate reduction
end_halving_inc=0.001   # frm-accuracy improvement ratio to terminate the training
halving_factor=0.5    # factor to multiply learn_rate
# tool config
#TRAIN_TOOL="nnet-train-mse-tgtmat-frmshuff-phonvoc" # training tool used for training / cross validation
use_gpu=yes # new format
#analyze_alignments=true # run the alignment analysis script
seed=777    # seed value used for training data shuffling and initialization
# End configuration.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh; 


. parse_options.sh || exit 1;

if [ "$use_gpu_id" == "" ]; then
# assumes new format
    gpu_option=--use_gpu=$use_gpu
    gpu_option_off=--use_gpu=no
else
    gpu_option=--use_gpu_id=$use_gpu_id
    gpu_option_off=--use_gpu_id=-1
fi


if [ $# != 5 ]; then
   echo "Usage: $0 <indata-train> <indata-dev> <outdata-train> <outdata-dev> <exp-dir>"
   echo " e.g.: $0 data/train data/cv data/out data/out_cv exp/mono_nnet"
   echo "main options (for others, see top of script file)"
   echo "  --config <config-file>  # config containing options"
   exit 1;
fi

data=$1
data_cv=$2
#lang=$3
odata=$3
odata_cv=$4
dir=$5

#silphonelist=`cat $lang/phones/silence.csl` || exit 1;


for f in $data/feats.scp $data_cv/feats.scp $odata/feats.scp $odata_cv/feats.scp; do
    [ ! -f $f ] && echo "$0: no such file $f" && exit 1;
done

echo "$0 [info]: Training Neural Network"
printf "\t dir       : $dir \n"
printf "\t Train-set : $data $odata \n"
printf "\t CV-set    : $data_cv $odata_cv \n"

mkdir -p $dir/{log,nnet}

#skip when already trained
[ -e $dir/final.nnet ] && printf "\nSKIPPING TRAINING... ($0)\nnnet already trained : $dir/final.nnet ($(readlink $dir/final.nnet))\n\n" && exit 0


###### PREPARE FEATURES ######
# shuffle the list
echo "Preparing train/cv lists"
cat $data/feats.scp | utils/shuffle_list.pl --srand ${seed:-777} > $dir/intrain.scp
cp $data_cv/feats.scp $dir/incv.scp
cat $odata/feats.scp |awk -v lst=$data/feats.scp 'BEGIN{ while (getline < lst) w[$1] = 1}{if (w[$1]) print}' | utils/shuffle_list.pl --srand ${seed:-777} > $dir/train.scp
cat $odata_cv/feats.scp | awk -v lst=$data_cv/feats.scp 'BEGIN{ while (getline < lst) w[$1] = 1}{if (w[$1]) print}' > $dir/cv.scp
# print the list sizes
wc -l $dir/train.scp $dir/cv.scp

#re-save the shuffled features, so they are stored sequentially on the disk in /tmp/
if [ "$copy_feats" == "true" ]; then
  tmpdir=$(mktemp -d); mv $dir/train.scp $dir/train.scp_non_local
  utils/nnet/copy_feats.sh $dir/train.scp_non_local $tmpdir $dir/train.scp
  mv $dir/intrain.scp $dir/intrain.scp_non_local
  utils/nnet/copy_feats.sh $dir/intrain.scp_non_local $tmpdir $dir/intrain.scp
  #remove data on exit...
  trap "echo \"Removing features tmpdir $tmpdir @ $(hostname)\"; rm -r $tmpdir" EXIT
fi

#create a 10k utt subset for global cmvn estimates
head -n 10000 $dir/train.scp > $dir/train.scp.10k



###### PREPARE FEATURE PIPELINE ######

#read the features
cat $dir/intrain.scp $dir/incv.scp > $dir/infull.scp
if [ "$input_feature_transform" != "" ]; then
    infeats_tr="ark:nnet-forward $input_feature_transform scp:$dir/intrain.scp ark:- |"
    infeats_cv="ark:nnet-forward $input_feature_transform scp:$dir/incv.scp ark:- |"
    infeats_fl="ark:nnet-forward $input_feature_transform scp:$dir/infull.scp ark:- |"
else
    infeats_tr="ark:copy-feats scp:$dir/intrain.scp ark:- |"
    infeats_cv="ark:copy-feats scp:$dir/incv.scp ark:- |"
    infeats_fl="ark:copy-feats scp:$dir/infull.scp ark:- |"
fi
cat $dir/train.scp $dir/cv.scp > $dir/full.scp
cat $odata/utt2spk $odata_cv/utt2spk > $dir/utt2spk
cat $odata/cmvn.scp $odata_cv/cmvn.scp | sort | uniq > $dir/cmvn.scp
feats_tr="ark:copy-feats scp:$dir/train.scp ark:- |"
feats_cv="ark:copy-feats scp:$dir/cv.scp ark:- |"
feats_fl="ark:copy-feats scp:$dir/full.scp ark:- |"

#moved my MC
#optionally add deltas
if [ "$delta_order" != "" ]; then
  feats_tr="$feats_tr add-deltas --delta-order=$delta_order ark:- ark:- |"
  feats_cv="$feats_cv add-deltas --delta-order=$delta_order ark:- ark:- |"
  feats_fl="$feats_fl add-deltas --delta-order=$delta_order ark:- ark:- |"
  echo "$delta_order" > $dir/delta_order
  echo "add-deltas (delta_order $delta_order)"
fi

#optionally add per-speaker CMVN
if [ $apply_cmvn == "true" ]; then
  echo "Will use CMVN statistics : $odata/cmvn.scp, $odata_cv/cmvn.scp"
  [ ! -r $odata/cmvn.scp ] && echo "Cannot find cmvn stats $odata/cmvn.scp" && exit 1;
  [ ! -r $odata_cv/cmvn.scp ] && echo "Cannot find cmvn stats $odata_cv/cmvn.scp" && exit 1;
  cmvn="scp:$odata/cmvn.scp"
  cmvn_cv="scp:$odata_cv/cmvn.scp"
  cmvn_fl="scp:$dir/cmvn.scp"
  feats_tr_orig="$feats_tr"
  feats_tr="$feats_tr apply-cmvn --print-args=false --norm-vars=false --utt2spk=ark:$odata/utt2spk $cmvn ark:- ark:- |"
  feats_cv="$feats_cv apply-cmvn --print-args=false --norm-vars=false --utt2spk=ark:$odata_cv/utt2spk $cmvn_cv ark:- ark:- |"
  feats_fl="$feats_fl apply-cmvn --print-args=false --norm-vars=false --utt2spk=ark:$dir/utt2spk $cmvn_fl ark:- ark:- |"
  # keep track of norm_vars option
  echo "$norm_vars" >$dir/norm_vars 
else
  echo "apply_cmvn disabled (per speaker norm. on acoustic features)"
  if [ "$apply_glob_cmvn" == "true" ]; then
      echo "Computing global cmvn on output features"
      compute-cmvn-stats --binary=false  "$feats_tr" $dir/cmvn_out_glob.ark
      feats_tr="$feats_tr apply-cmvn --print-args=false --norm-vars=$norm_vars $dir/cmvn_out_glob.ark ark:- ark:- |"
      feats_cv="$feats_cv apply-cmvn --print-args=false --norm-vars=$norm_vars $dir/cmvn_out_glob.ark ark:- ark:- |"
      feats_fl="$feats_fl apply-cmvn --print-args=false --norm-vars=$norm_vars $dir/cmvn_out_glob.ark ark:- ark:- |"
  fi
fi

#optionally add fmllr transformations
if [[ "$speak_transform" != "" && -f $speak_transform ]]; then
   feats_tr="$feats_tr transform-feats --utt2spk=ark:$data/utt2spk ark:$speak_transform ark:- ark:- |"
   feats_cv="$feats_cv transform-feats --utt2spk=ark:$data_cv/utt2spk ark:$speak_transform ark:- ark:- |"
   feats_fl="$feats_fl transform-feats --utt2spk=ark:$dir/utt2spk ark:$speak_transform ark:- ark:- |"
   echo "added fmllr from $speak_transform"
fi

#get feature dim
echo -n "Getting feature dim : "
feat_dim=$(feat-to-dim --print-args=false "$feats_tr" -)
echo $feat_dim

# Now we will start building complex feature_transform which will 
# be forwarded in CUDA to gain more speed.
#
# We will use 1GPU for both feature_transform and MLP training in one binary tool. 
# This is against the kaldi spirit, but it is necessary, because on some sites a GPU 
# cannot be shared accross by two or more processes (compute exclusive mode),
# and we would like to use single GPU per training instance,
# so that the grid resources can be used efficiently...

if [ "$feature_transform" != "" ]; then
  echo "Using pre-computed feature-transform $feature_transform"
  cp $feature_transform $dir/$(basename $feature_transform)
  feature_transform=$dir/$(basename $feature_transform)
else
  # Generate the splice transform
  echo "Using splice +/- $splice_lr , step $splice_step"
  feature_transform=$dir/tr_splice$splice_lr-$splice_step.nnet
  utils/nnet/gen_splice.py --fea-dim=$feat_dim --splice=$splice_lr --splice-step=$splice_step > $feature_transform

  # Choose further processing of spliced features
  echo "Feature type : $feat_type"
  case $feat_type in
    plain)
    ;;
    traps)
      #generate hamming+dct transform
      transf=$dir/hamm_dct${traps_dct_basis}.mat
      echo "Preparing Hamming DCT transform : $transf"
      utils/nnet/gen_hamm_mat.py --fea-dim=$feat_dim --splice=$splice_lr > $dir/hamm.mat
      utils/nnet/gen_dct_mat.py --fea-dim=$feat_dim --splice=$splice_lr --dct-basis=$traps_dct_basis > $dir/dct.mat
      compose-transforms --binary=false $dir/dct.mat $dir/hamm.mat $transf 2>${transf}_log || exit 1
      #convert transform to nnet format
      transf-to-nnet --binary=false $transf $transf.nnet 2>$transf.nnet_log || exit 1
      #append it to the feature_transform
      {
        tag=$(basename $transf .mat)
        feature_transform_old=$feature_transform
        feature_transform=${feature_transform%.nnet}_${tag}.nnet
        cp $feature_transform_old $feature_transform
        cat $transf.nnet >> $feature_transform
      }
    ;;
    transf)
      transf=$dir/final.mat
      [ ! -f $alidir/final.mat ] && echo "Missing transform $alidir/final.mat" && exit 1;
      cp $alidir/final.mat $transf
      echo "Copied transform $transf from $alidir/final.mat"
      #convert transform to nnet format
      transf-to-nnet --binary=false $transf $transf.nnet 2>$transf.nnet_log || exit 1
      #append it to the feature_transform
      {
        feature_transform_old=$feature_transform
        feature_transform=${feature_transform%.nnet}_alidir-transf.nnet
        cp $feature_transform_old $feature_transform
        cat $transf.nnet >> $feature_transform
      }
    ;;
    lda)
      transf=$dir/lda$lda_dim.mat
      #get the LDA statistics
      if [ ! -r "$dir/lda.acc" ]; then
        echo "LDA: Converting alignments to posteriors $dir/lda_post.scp"
        ali-to-post "ark:gunzip -c $alidir/ali.*.gz|" ark:- | \
          weight-silence-post 0.0 $silphonelist $alidir/final.mdl ark:- ark,scp:$dir/lda_post.ark,$dir/lda_post.scp 2> $dir/lda_post.scp_log || exit 1;
        echo "Accumulating LDA statistics $dir/lda.acc on top of spliced feats"
        acc-lda --rand-prune=$lda_rand_prune $alidir/final.mdl "$feats_tr nnet-forward $feature_transform ark:- ark:- |" scp:$dir/lda_post.scp $dir/lda.acc 2> $dir/lda.acc_log || exit 1;
      else
        echo "LDA: Using pre-computed stats $dir/lda.acc"
      fi
      #estimate the transform  
      echo "Estimating LDA transform $dir/lda.mat from the statistics $dir/lda.acc"
      est-lda --write-full-matrix=$dir/lda.full.mat --dim=$lda_dim $transf $dir/lda.acc 2>${transf}_log || exit 1;
      #convert the LDA matrix to nnet format
      transf-to-nnet --binary=false $transf $transf.nnet 2>$transf.nnet_log || exit 1;
      #append LDA matrix to feature_transform
      {
        tag=$(basename $transf .mat)
        feature_transform_old=$feature_transform
        feature_transform=${feature_transform%.nnet}_${tag}.nnet
        cp $feature_transform_old $feature_transform
        cat $transf.nnet >> $feature_transform
      }
      #remove the accu
      #rm $dir/lda.acc 
      rm $dir/lda_post.{ark,scp}
    ;;
    *)
      echo "Unknown feature type $feat_type"
      exit 1;
    ;;
  esac
  # keep track of feat_type
  echo $feat_type > $dir/feat_type

  # if [ "$apply_minmax" == "true" ]; then
  #     feature_transform_old=$feature_transform
  #     feature_transform=${feature_transform%.nnet}_cmvn-g.nnet
  #     echo "Renormalizing MLP output features using minmax into $feature_transform"
  #     nnet-forward $feature_transform_old "$(echo $feats_tr | sed 's|train.scp|train.scp.10k|')" \
  # 	  ark:- 2>$dir/log/cmvn_glob_fwd.log |\
  #         compute-minmax-stats ark:- - | minmax-to-nnet - - |\
  #         nnet-concat --binary=false $feature_transform_old - $feature_transform
  #     # nnet-forward ${use_gpu_id:+ --use-gpu-id=$use_gpu_id} \
  #     # 	  $feature_transform_old "$(echo $feats_tr | sed 's|train.scp|train.scp.10k|')" \
  #     # 	  ark:- 2>$dir/log/cmvn_glob_fwd.log |\
  #     #     compute-minmax-stats ark:- - | minmax-to-nnet - - |\
  #     #     nnet-concat --binary=false $feature_transform_old - $feature_transform
  # fi
  #renormalize the MLP output to zero mean and unit variance
  if [ "$apply_glob_cmvn" == "true" ]; then
      if [ "$apply_cmvn" == "true" ]; then
  	  echo "Computing global cmvn on output from pre-speaker cmvn"
  	  compute-cmvn-stats --binary=false  "$feats_tr_orig" $dir/cmvn_out_glob.ark
      fi
      echo "Computing global cmvn on input"
      compute-cmvn-stats --binary=false  "$infeats_fl" $dir/cmvn_glob.ark
  else
      echo "No global CMVN used on MLP front/back-end"
  fi
fi

if  [ "$apply_glob_cmvn" == "true" ]; then
    # if an input feature transform is provided, we consider it takes care of the global cmvn
    # on input
    if [ -z "$dbn" -o -z "$input_feature_transform" ]; then 
	infeats_tr="$infeats_tr apply-cmvn --print-args=false --norm-vars=$norm_vars $dir/cmvn_glob.ark ark:- ark:- |"
	infeats_cv="$infeats_cv apply-cmvn --print-args=false --norm-vars=$norm_vars $dir/cmvn_glob.ark ark:- ark:- |"
    fi
fi


###### MAKE LINK TO THE FINAL feature_transform, so the other scripts will find it ######
(cd $dir; ln -sf $(basename $feature_transform) final.feature_transform )


###### INITIALIZE THE NNET ######

echo "# NN-INITIALIZATION"
if [ ! -z "$mlp_init" ]; then
  echo "Using pre-initalized network $mlp_init";
else
  echo "Getting input/output dims :"
  #initializing the MLP, get the i/o dims...
  #input-dim
  #if [ "$input_feature_transform" == "" ]; then
  num_in=$(feat-to-dim "$infeats_tr" -);
  #else
  #num_in=$(feat-to-dim "$infeats_tr nnet-forward $input_feature_transform ark:- ark:- |" - )
      { #optionally take output dim of DBN
	  [ ! -z $dbn ] && num_in=$(nnet-forward $dbn "$infeats_tr" ark:- | feat-to-dim ark:- -)
	  [ -z "$num_in" ] && echo "Getting nnet input dimension failed!!" && exit 1
      }
  # fi

  #output-dim
  num_out=$(feat-to-dim "$feats_tr nnet-forward $feature_transform ark:- ark:- |" - )

  #run the MLP initializing script
  mlp_init=$dir/nnet.init
  kaldi_init_nnet.sh --model_size $model_size --hid_layers $hid_layers \
    ${bn_dim:+ --bn-dim $bn_dim} \
    ${hid_dim:+ --hid-dim $hid_dim} \
    --seed $seed ${init_opts} \
    ${config:+ --config $config} \
    --activation-output $activationOutput --init-opts "$mlpOption" \
    $num_in $num_out $mlp_init || exit 1

  #optionally prepend dbn to the initialization
  if [ ! -z $dbn ]; then
    mlp_init_old=$mlp_init; mlp_init=$dir/nnet_$(basename $dbn)_dnn.init
    nnet-concat $dbn $mlp_init_old $mlp_init 
  fi
fi

###### TRAIN ######
# feature_transform=
# echo "Starting training : "

feat-to-post "$feats_tr" ark:$dir/labels_tr.ark
feat-to-post "$feats_cv" ark:$dir/labels_cv.ark

echo "# RUNNING THE NN-TRAINING SCHEDULER"
  # --feature-transform $feature_transform \
kaldi_train_scheduler.sh \
  --learn-rate $learn_rate \
  --randomizer-seed $seed \
  ${train_opts} \
  ${train_tool:+ --train-tool "$train_tool"} \
  ${frame_weights:+ --frame-weights "$frame_weights"} \
  ${config:+ --config $config} \
  $mlp_init "$infeats_tr" "$infeats_cv" \
  ark:$dir/labels_tr.ark ark:$dir/labels_cv.ark $dir || exit 1

echo "Training finished."
