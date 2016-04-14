#
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Milos Cernak, Sept. 2015
#
echo Script: $0
source ../Config.sh

ll=../lang/$lang
dir=dnns/pretrain-dbn-$lang
(tail --pid=$$ -F $dir/_pretrain_dbn.log 2>/dev/null)&
$cuda_cmd $dir/_pretrain_dbn.log steps/nnet/pretrain_dbn.sh --rbm-iter 20 --nn_depth 4 --hid_dim 1024 --config ../conf/pretrain.conf $ll/data/dev_clean $dir || exit 1;
