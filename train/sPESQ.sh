#!/usr/bin/zsh
#
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
# See the file COPYING for the licence associated with this software.
#
# Split data to the dev and test sets
#
# Milos Cernak, November 2015
#
source ../Config.sh

# Check for ISS; add it to the path
if [ "$PESQ_ROOT" = "" ]
then
    echo
    "Please install PESQ and set \$PESQ_ROOT"
    exit 1
fi

data=../lang/$lang/data/$voice/test-audio
echo -n "" > pesq_results.txt
for f in `ls $data`; do
    echo $f
    $PESQ_ROOT/pesq +8000 $data/$f enc/$lang-$phon-$voice-$vocod-paramType$paramType/htk/$f:r.8k.wav
    # exit
done

mv pesq_results.txt pesq_results_$lang-$phon-$voice-$vocod-paramType$paramType.txt
