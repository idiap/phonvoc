#!/usr/bin/zsh
#
# Copyright 2016 by Idiap Research Institute, http://www.idiap.ch
# See the file COPYING for the licence associated with this software.
#
# Split data to the dev and test sets
#
# Milos Cernak, Jan. 2016
#
source ../Config.sh

SETSHELL sptk

data=../lang/$lang/data/$voice/test-audio
echo -n "" > enc/$lang-$phon-$voice-$vocod-paramType$paramType.cdist
for f in `find $data -name "*.wav"`; do
    ref=$f
    voc=enc/$lang-$phon-$voice-$vocod-paramType$paramType/htk/$f:t:r.wav
    sox $ref $ref:r.raw
    sox $voc $voc:r.raw
    x2x +sf < $ref:r.raw | frame -l 400 -p 160 | window -l 400 -L 512 | \
	mcep -l 512 -m 25 -a 0.42 -e 0.000001 | x2x +fa26 | \
	sed -n '20,180p' | x2x +af > $ref:r.mcep
    x2x +sf < $voc:r.raw | frame -l 400 -p 160 | window -l 400 -L 512 | \
	mcep -l 512 -m 25 -a 0.42 -e 0.000001 | x2x +fa26 | \
	sed -n '20,180p' | x2x +af > $voc:r.mcep
    # mean normalisation
    vstat -l 26 -o 1 $ref:r.mcep > mean
    vopr -l 26 -s $ref:r.mcep mean > $ref:r.n.mcep
    vstat -l 26 -o 1 $voc:r.mcep > mean
    vopr -l 26 -s $voc:r.mcep mean > $voc:r.n.mcep
    # mcepdistance=`cdist -m 25 $ref:r.mcep $voc:r.mcep | dmp +f`
    mcepdistance=`cdist -m 25 $ref:r.n.mcep $voc:r.n.mcep | dmp +f | awk '{print $2}'`
    echo $f
    echo $mcepdistance >> enc/$lang-$phon-$voice-$vocod-paramType$paramType.cdist
    cdist -f -m 25 $ref:r.n.mcep $voc:r.n.mcep | x2x +fa > $voc:r.cdist
    rm $ref:r.mcep $ref:r.n.mcep $voc:r.mcep $voc:r.n.mcep
    # exit
done

rm mean
