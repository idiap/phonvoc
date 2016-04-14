#!/usr/bin/zsh
#
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
# See the file COPYING for the licence associated with this software.
#
# Extract phonological features from the audio book data
#
# Milos Cernak, Feb. 2016
#
source ../Config.sh

ll=../lang/$lang
# load phonological map
if [[ ! -e $ll/${phon}-map.sh ]]; then
    echo "Please create $ll/${phon}-map.sh"
    exit 1
fi
source $ll/${phon}-map.sh

# prepare dictionary
local/prepare_dict.sh --stage 3 --cmd "$train_cmd" \
   $dataLM dummy $ll/data/dict || exit 1

utils/prepare_lang.sh $ll/data/dict "<SPOKEN_NOISE>" $ll/data/lang_tmp $ll/data/lang || exit 1;

utils/subset_data_dir.sh --shortest $ll/data/train_clean_100 2000 $ll/data/train_2kshort
utils/subset_data_dir.sh $ll/data/train_clean_100 5000 $ll/data/train_5k
utils/subset_data_dir.sh $ll/data/train_clean_100 10000 $ll/data/train_10k

# train a monophone system
steps/train_mono.sh --boost-silence 1.25 --nj 20 --cmd "$train_cmd" \
  $ll/data/train_2kshort $ll/data/lang feats/mono || exit 1;

steps/align_si.sh --boost-silence 1.25 --nj 10 --cmd "$train_cmd" \
  $ll/data/train_5k $ll/data/lang feats/mono feats/mono_ali_5k

# train a first delta + delta-delta triphone system on a subset of 5000 utterances
steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    2000 10000 $ll/data/train_5k $ll/data/lang feats/mono_ali_5k feats/tri1 || exit 1;

steps/align_si.sh --nj 10 --cmd "$train_cmd" \
  $ll/data/train_10k $ll/data/lang feats/tri1 feats/tri1_ali_10k || exit 1;

# train an LDA+MLLT system.
steps/train_lda_mllt.sh --cmd "$train_cmd" \
   --splice-opts "--left-context=3 --right-context=3" \
   2500 15000 $ll/data/train_10k $ll/data/lang feats/tri1_ali_10k feats/tri2b || exit 1;

# Align a 10k utts subset using the tri2b model
steps/align_si.sh  --nj 10 --cmd "$train_cmd" \
     --use-graphs true $ll/data/train_10k $ll/data/lang feats/tri2b feats/tri2b_ali_10k || exit 1;

# train tri3b, which is LDA+MLLT+SAT on 10k utts
steps/train_sat.sh --cmd "$train_cmd" \
  2500 15000 $ll/data/train_10k $ll/data/lang feats/tri2b_ali_10k feats/tri3b || exit 1;

# align the entire train_clean_100 subset using the tri3b model
steps/align_fmllr.sh --nj 20 --cmd "$train_cmd" \
  $ll/data/train_clean_100 $ll/data/lang feats/tri3b feats/tri3b_ali_clean_100 || exit 1;

# train another LDA+MLLT+SAT system on the entire 100 hour subset
steps/train_sat.sh  --cmd "$train_cmd" \
  4200 40000 $ll/data/train_clean_100 $ll/data/lang feats/tri3b_ali_clean_100 feats/tri4b || exit 1;

# align train_clean_100 using the tri4b model
steps/align_fmllr.sh --nj 30 --cmd "$train_cmd" \
  $ll/data/train_clean_100 $ll/data/lang feats/tri4b feats/tri4b_ali_clean_100 || exit 1;

# # align dev_clean using the tri4b model
steps/align_fmllr.sh --nj 30 --cmd "$train_cmd" \
  $ll/data/dev_clean $ll/data/lang feats/tri4b feats/tri4b_ali_dev_clean || exit 1;

# ... and then combine the two sets into a 460 hour one
utils/combine_data.sh $ll/data/train_clean_460 $ll/data/train_clean_100 $ll/data/train_clean_360 || exit 1

# align the new, combined set, using the tri4b model
steps/align_fmllr.sh --nj 40 --cmd "$train_cmd" \
  $ll/data/train_clean_460 $ll/data/lang feats/tri4b feats/tri4b_ali_clean_460 || exit 1;

# create a larger SAT model, trained on the 460 hours of data.
steps/train_sat.sh  --cmd "$train_cmd" \
  5000 100000 $ll/data/train_clean_460 $ll/data/lang feats/tri4b_ali_clean_460 feats/tri5b || exit 1;

# combine all the data
utils/combine_data.sh $ll/data/train_960 $ll/data/train_clean_460 $ll/data/train_other_500 || exit 1

steps/align_fmllr.sh --nj 60 --cmd "$train_cmd" \
  $ll/data/train_960 $ll/data/lang feats/tri5b feats/tri5b_ali_960 || exit 1;

# train a SAT model on the 960 hour mixed data.  Use the train_quick.sh script
# as it is faster.
steps/train_quick.sh --cmd "$train_cmd" \
  7000 150000 $ll/data/train_960 $ll/data/lang feats/tri5b_ali_960 feats/tri6b || exit 1;

# align 960 hour mixed data using the tri6b model
steps/align_fmllr.sh --nj 60 --cmd "$train_cmd" \
  $ll/data/train_960 $ll/data/lang feats/tri6b feats/tri6b_ali_960 || exit 1;

# align dev_clean using the tri6b model
steps/align_fmllr.sh --nj 30 --cmd "$train_cmd" \
  $ll/data/dev_clean $ll/data/lang feats/tri6b feats/tri6b_ali_dev_clean || exit 1;

# align dev_clean using the tri6b model
steps/align_fmllr.sh --nj 30 --cmd "$train_cmd" \
  $ll/data/dev_other $ll/data/lang feats/tri6b feats/tri6b_ali_dev_other || exit 1;
