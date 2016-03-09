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

inFile=$1
inType=0 # 0 - input is an audio file; 1 - input is list of the audio files

if  [[ ! -r $inFile ]]; then
    echo "$inFile not accessible.";
    exit 1;
elif [[ $inFile =~ "\.wav$" ]]; then
    echo "A single input file mode"
else
    echo "A multiple input files (a list) mode"
    inType=1
fi

analysis.sh $inFile $inType
synthesis.sh $inFile:t:r $inType
cdist.sh $inFile:t:r

echo "Done."
