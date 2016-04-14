#!/usr/bin/zsh
#
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
# See the file COPYING for the licence associated with this software.
#
# Prepare data and train Phonological Encoders (DNNs).
#
# Milos Cernak, April 2016
#
echo Script: $0
source ../Config.sh

[ -f path.sh ] && . ./path.sh; 

mdl=$1
aliDir=$2
n=$3
mappingType=$4 # phone/$att

ll=../lang/$lang
ldir=$ll/labels

echo "$0 $@"  # Print the command line for logging

if [[ ! -d $ldir ]]; then
    mkdir -p $ldir
fi

if [[ ! -e $ll/${phon}-map.sh ]]; then
    echo "Please create $ll/${phon}-map.sh"
    exit 1
fi
source $ll/${phon}-map.sh

# LibriSpeech
echo "loading phone map"
typeset -A itop
while read l; do
    p=`echo $l | awk '{ match($1, /^([A-Z]+)/, phone); print phone[1]}'`
    i=`echo $l | awk '{print $2}'`
    itop[$i]=$p
done < $ll/data/lang/phones.txt

typeset -A ptoi # phoneme to index (39 phns + SIL + SPN)
if [[ $mappingType == "phone" ]]; then
    i=0
    for p in ${(@k)attRevMap}; do
	if [[ $p = 'XX' ]]; then
	    p='SIL'
	fi
	# echo $p $i
	ptoi[$p]=$i
	(( i = i + 1 ))
    done
    ptoi[SPN]=$i   # add optional spoken noise phone
else
    phonemes=`echo $attMap[$mappingType] | sed 's/,/ /g'`
    for p in ${=phonemes}; do
	# echo $p $i
	ptoi[$p]=$p
    done
fi

post=$ldir/labels.$n.txt
echo -n "" > $post

a=$aliDir/ali.$n.gz
t=$ldir/ali.$n.txt
ali="gunzip -c ${a}|"
ali-to-phones --per-frame $mdl ark:"${ali}" ark,t:$t
while read l; do
    la=(${=l})       # line to array
    pline=( $la[1] ) # new posterior line
    la[1]=()         # remove utt id
    if [[ $mappingType == "phone" ]]; then
	for i in $la; do # convert alignment to monophone id
	    pline+=( [ $ptoi[$itop[$i]] 1 ] )
	done
    else
	for i in $la; do # convert alignment to phonological feature occurence
    	    if [[ $ptoi[$itop[$i]] = "" ]]; then
		pline+=( [ 0 1 ] )
	    else
		pline+=( [ 1 1 ] )
	    fi
	done
    fi
    echo $pline >> $post
done < $t
rm -f $t

echo "$0 successfuly finished.. $dir"

# sleep 3
exit 0
