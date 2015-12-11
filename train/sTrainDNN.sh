#
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Milos Cernak, November 2015
#
source ../Config.sh

# with pre-training
dbn=dnns/pretrain-synthesis-dbn-${lang}-${voice}-paramType$paramType
dir=dnns/${hlayers}-${hdim}-${lrate}-${lang}-${voice}-${vocod}-paramType$paramType
itrain=../lang/$lang/data/$voice/itrain
idev=../lang/$lang/data/$voice/idev
otrain=../lang/$lang/data/$voice/otrain
odev=../lang/$lang/data/$voice/odev
# linear output with mse objective function
$cuda_cmd $dir/_train_nnet.log kaldi_train_nnet.sh \
  --config ../conf/add-layer-nn.conf --learn_rate $lrate \
  --randomize true --apply_cmvn false \
  --apply_glob_cmvn true --dbn $dbn/4.dbn --hid-dim 1024 \
  --input-feature-transform $dbn/final.feature_transform \
  $itrain $idev $otrain $odev $dir

# softmax output --mlpOption " "
