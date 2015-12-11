#!/bin/sh
#
# Copyright 2014 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Milos Cernak, Apr 2015
#

# Kaldi
. ./cmd.sh
. ./path.sh

# English training data
wsj0=/idiap/resource/database/WSJ0
wsj1=/idiap/resource/database/WSJ1

ifeatdir=feats/att1 # EnUS cogn15 Kaldi setup
ofeatdir=feats/aho1
# DATA=data/train
# DATA=data

export N_JOBS=30
