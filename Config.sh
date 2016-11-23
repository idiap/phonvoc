#!/bin/sh
#
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Milos Cernak, Sept. 2015
#

# ------- UPDATE THESE PATHS TO FIT YOUR ENVIRONMENT ------ !!!
# SSP and Kaldi paths
export SSP_ROOT=path-to-SSP
export KALDI_ROOT=path-to-Kaldi

# Optional (required only for training): English training data
export data=path-to-LibriSpeech
export dataLM=$data/resource
export voiceData=path-to-annakarenina_mas_1202_librivox/wav
# ------- UPDATE THESE PATHS TO FIT YOUR ENVIRONMENT ------ !!!

# Check for KALDI; add it to the path
if [ "$KALDI_ROOT" = "" ]
then
    echo
    "Please \"SETSHELL kaldi\" or point \$KALDI_ROOT to an KALDI
installation"
    exit 1
fi
# Check for SSP; add it to the path
if [ "$SSP_ROOT" = "" ]
then
    echo
    "Please install https://github.com/idiap/ssp and set \$ISS_ROOT"
    exit 1
fi

# IDIAP
export extract_cmd="queue.pl "
export train_cmd="queue.pl -l h_vmem=2G"
# export train_cmd="queue.pl -l q1d,h_vmem=2G"
export decode_cmd="queue.pl -l q1d,h_vmem=2G"
export decode_nnet_cmd="queue.pl -l q1d,h_vmem=2G -v LD_LIBRARY_PATH"
export decode_big_cmd="queue.pl -l q1d,h_vmem=4G"
export mkgraph_cmd="queue.pl -l q1d,h_vmem=4G"
export cuda_cmd="queue.pl -l gpu"

export PATH=$PWD/utils/:$PWD:$PATH
export LC_ALL=C

export N_JOBS=60
export USE_SGE=0

################################################################
### PHONVOC SETTINGS ###

# phonological speech representation
## GP       - Government Phonology of Harris and Lindsey (1995)
## SPE      - Sound Patter of English of Chomsky and Halle (1968)
## eSPE     - extended SPE
export phon=SPE

# language  - used training database for phonological analysis
## English  - LibriSpeech db
## French   - Ester db
## Mandarin - Emime db
# export lang=French
export lang=English

# synthesis voice
# English - Anna voice (~36h LibriVox female voice)
export voice=Anna
# export voice=siwis
# export voice=Nancy

# Re-synthesis vocoder
# export vocod=LPC
export vocod=cepgm
# training parameters
export lrate=0.001
export hlayers=4
export hdim=1024
# phonetic and phonological parametrization
# parametrization | paramType
# phonetic        | 0
# phonological    | 1
# phonetic+phonol.| 2
export paramType=1
