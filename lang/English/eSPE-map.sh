#!/usr/bin/zsh
#
# Copyright 2016 by Idiap Research Institute, http://www.idiap.ch
# See the file COPYING for the licence associated with this software.
#
# An extended SPE map.
#
# Milos Cernak, Jan. 2016
#

typeset -A attMap
attMap=(
  # manner
  vowel       IY,IH,EH,EY,AE,AA,AW,AY,AH,AO,OY,OW,UH,UW,ER
  fricative   JH,CH,S,SH,Z,ZH,F,TH,V,DH,HH
  nasal       M,N,NG
  stop        B,D,G,P,T,K
  approximant W,Y,L,R
  # place
  coronal     D,L,N,S,T,Z
  high        CH,IH,IY,JH,SH,UH,UW,Y,OW,G,K,NG
  dental      DH,TH
  glottal     HH
  labial      B,F,M,P,V,W
  low         AA,AE,AW,AY,OY
  mid         AH,EH,EY,OW
  retroflex   ER,R
  velar       G,K,NG
  # others
  anterior    B,D,DH,F,L,M,N,P,S,T,TH,V,Z,W
  back        AY,AA,AH,AO,AW,OW,OY,UH,UW,G,K
  continuant  AA,AE,AH,AO,AW,AY,DH,EH,ER,R,EY,L,F,IH,IY,OY,OW,S,SH,TH,UH,UW,V,W,Y,Z
  round       AW,OW,UW,AO,UH,V,Y,OY,R,W
  tense       AA,AE,AO,AW,AY,EY,IY,OW,OY,UW,CH,S,SH,F,TH,P,T,K,HH
  voiced      AA,AE,AH,AW,AY,AO,B,D,DH,EH,ER,EY,G,IH,IY,JH,L,M,N,NG,OW,OY,R,UH,UW,V,W,Y,Z
  sil         sil
)

# reversed mapping for synthesis
typeset -A attRevMap
attRevMap=(
  XX sil
  M  nasal,labial,anterior,voiced
  N  nasal,coronal,anterior,voiced
  NG nasal,high,velar,voiced
  P  stop,labial,anterior,tense
  T  stop,coronal,anterior,tense
  K  stop,high,velar,back,tense
  B  stop,labial,anterior,voiced
  D  stop,coronal,anterior,voiced
  G  stop,high,velar,back,voiced
  V  fricative,labial,anterior,continuant,round,voiced
  DH fricative,dental,anterior,continuant,voiced
  Z  fricative,coronal,anterior,continuant,voiced
  ZH fricative
  F  fricative,labial,anterior,continuant,tense
  TH fricative,dental,anterior,continuant,tense
  S  fricative,coronal,anterior,continuant,tense
  SH fricative,high,continuant,tense
  CH fricative,high,tense
  JH fricative,high,voiced
  HH glottal
  R  approximant,retroflex,continuant,round,voiced
  Y  approximant,high,continuant,round,voiced
  W  approximant,labial,anterior,continuant,round,voiced
  L  approximant,coronal,anterior,continuant,voiced
  IY vowel,high,continuant,tense,voiced
  IH vowel,high,continuant,voiced
  UW vowel,high,back,continuant,round,tense,voiced
  UH vowel,high,back,continuant,round,voiced
  EH vowel,mid,continuant,voiced
  ER vowel,retroflex,continuant,voiced
  AH vowel,mid,back,continuant,voiced
  AO vowel,back,round,continuant,tense,voiced
  AE vowel,low,continuant,tense,voiced
  AA vowel,low,back,continuant,tense,voiced
  AX vowel,mid,back,continuant,voiced
  EY vowel,mid,continuant,tense,voiced
  OW vowel,high,mid,back,round,continuant,tense,voiced
  OY vowel,back,round,continuant,voiced
  AW vowel,low,back,round,continuant,tense,voiced
  AY vowel,low,back,continuant,tense,voiced
)
