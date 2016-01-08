#!/usr/bin/zsh
#
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
# See the file COPYING for the licence associated with this software.
#
# Evaluate attributes
#
# Milos Cernak, November 2015
#
source ../Config.sh

data=../lang/$lang/data/$voice
ofeatdir=feats/out-${lang}-${vocod}-${voice}
if [[ ! -e $ofeatdir ]]; then
  mkdir -p $ofeatdir
fi

tmpark=$ofeatdir/tmp_out_feat.ark
tmpscp=$ofeatdir/feats.scp
txtark=$ofeatdir/txt_out_feat.ark
binark=$ofeatdir/out_feat.ark

echo -n "" > $txtark
rm -f $tmpscp $txtark

while read l; do
  f=`echo $l | awk '{ print $2 }'`
  id=`echo $l | awk '{ print $1 }'`
  echo $f
  # sox $f $ofeatdir/$f:t
  htk=$ofeatdir/$f:t:r.htk
  f0=$ofeatdir/$f:t:r.f0
  hnr=$ofeatdir/$f:t:r.hnr
  lhnr=$ofeatdir/$f:t:r.log.hnr
  tmpark=$ofeatdir/$f:t:r.htk.ark
  # LPC
  $SSP_ROOT/codec.py -e -a -l -m 160 -s 'cepgm' $f $htk
  toLog.py $hnr > $lhnr

  vecsize=`tail -c +9 $htk | head -c 2 | swab | perl -nle 'print int(unpack "s")/4;'`
  # s1=`HList -h -s 0 -e 0 $htk | grep HTK | awk '{print $3}'`
  # s2=`cat $f0 | wc -l`
  # s3=`cat $lhnr | wc -l`
  # echo htk: $s1, f0: $s2, hnr: $s3
  cat $htk | tail -c +13 | swab +f | x2x +f +a$vecsize  | tr '\t' ' '  > $tmpark
  # paste -d ' ' $tmpark $lhnr $f0 | head -n $s1 | \
  paste -d ' ' $tmpark $lhnr $f0 | \
      awk -v n=$id 'BEGIN{printf "%s [ ", n}{print}END{print "]"}' >> $txtark
  
  rm -f $tmpark $lhnr
  # exit
done < $data/wav.scp

cat $txtark | copy-feats ark,t:- ark,scp:$binark,$tmpscp
echo -n "nan" > $ofeatdir/spk2utt
cat $ofeatdir/feats.scp | awk '{ printf " %s", $1}END{print ""}' >> $ofeatdir/spk2utt
utils/spk2utt_to_utt2spk.pl $ofeatdir/spk2utt > $ofeatdir/utt2spk
steps/compute_cmvn_stats.sh $ofeatdir $ofeatdir $ofeatdir || exit 1;

rm -f $txtark
