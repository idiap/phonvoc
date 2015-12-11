#!/bin/zsh
#
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Milos Cernak, Sept 2015
#
source ../Config.sh
source ./Config.sh

# Variables
temp=/idiap/temp/$(whoami)/dbase/phonvoc-${lang}

# Link in the temp dir
feats=$temp/feats
echo Write features to $feats
mkdir -p $feats
ln -sf $feats feats

# link KALDI
echo Linking Kaldi: $KALDI_ROOT/egs/wsj/s5
ln -sf $KALDI_ROOT/egs/wsj/s5/steps steps
ln -sf $KALDI_ROOT/egs/wsj/s5/utils utils
