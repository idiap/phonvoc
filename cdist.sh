#!/usr/bin/zsh
#
# Copyright 2016 by Idiap Research Institute, http://www.idiap.ch
# See the file COPYING for the licence associated with this software.
#
# Calculate Mel Cepstral Distance
#
# Milos Cernak, Jan. 2016
#
source Config.sh

SETSHELL sptk

inDir=$1

if [[ ! -e $inDir/wav.scp ]]; then
    echo "MCD: $inDir/wav.scp file does not exist!"
    exit 1;
fi

while read l; do
    id=`echo $l | awk '{print $1}'`
    ref=`echo $l | awk '{print $2}'`
    voc=$inDir/$id.wav
    if [[ -e $voc && -e $ref ]]; then
	sox $ref $inDir/ref.raw
	x2x +sf < $inDir/ref.raw | frame -l 400 -p 256 | window -l 400 -L 512 | \
	    mcep -l 512 -m 25 -a 0.42 -e 0.000001 | x2x +fa26 | \
	    x2x +af > $inDir/ref.mcep
	vstat -l 26 -o 1 $inDir/ref.mcep > $inDir/mean
	vopr -l 26 -s $inDir/ref.mcep $inDir/mean > $inDir/ref.n.mcep

	sox $voc $inDir/voc.raw
	x2x +sf < $inDir/voc.raw | frame -l 400 -p 256 | window -l 400 -L 512 | \
	    mcep -l 512 -m 25 -a 0.42 -e 0.000001 | x2x +fa26 | \
	    x2x +af > $inDir/voc.mcep
	vstat -l 26 -o 1 $inDir/voc.mcep > $inDir/mean
	vopr -l 26 -s $inDir/voc.mcep $inDir/mean > $inDir/voc.n.mcep
	mcepdistance=`cdist -m 25 $inDir/ref.n.mcep $inDir/voc.n.mcep | dmp +f | awk '{print $2}'`
	echo "$id MCD = $mcepdistance dB"
	# cdist -f -m 25 $inDir/ref.n.mcep $inDir/voc.n.mcep | dmp +f | awk '{print $2}' > $inDir/$id.cdist
	rm $inDir/*.mcep $inDir/mean $inDir/*.raw
	# echo "Per-frame Mel Cepstral Distortion calculated in $inDir/$id.cdist"
    fi
    # exit
done < $inDir/wav.scp
