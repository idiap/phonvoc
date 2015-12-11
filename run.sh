#!/usr/bin/zsh
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Milos Cernak, November 2015
#
# Run analysis/synthesis of input audio files
#
source Config.sh

inAudio=$1

if [[ ! -r $inAudio ]]; then echo "$inAudio not accessible."; exit 1; fi

analysis.sh $inAudio
synthesis.sh $inAudio:t:r

echo "$inAudio:t:r/$inAudio:t:r.$paramType.wav generated."
