#!/usr/bin/zsh
#
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
# See the file COPYING for the licence associated with this software.
#
# A SPE map.
#
# Milos Cernak, Sept. 2015
#

typeset -A attMap
attMap=(
  vocalic     IY,IH,UW,UH,EY,EH,OW,OY,AO,AA,AE,AH,AW,AY,ER,R,L
  consonantal B,CH,D,DH,F,G,JH,K,L,M,N,NG,P,R,S,SH,T,TH,V,Z,ZH
  high        IY,IH,UW,UH,Y,W,CH,JH,SH,ZH,K,G,NG
  back        AA,AH,AO,AW,W,G,K,NG,OW,OY,UH,UW
  low         AA,AE,AW,AY,HH
  anterior    B,D,DH,F,L,M,N,P,S,T,TH,V,Z
  coronal     CH,D,DH,JH,L,R,S,SH,T,TH,Z,ZH,N
  round       UW,UH,OW,OY,AO,W
  ris         EY,OW,OY,AW,AY
  tense       AA,IY,UW,EY,ER,OW,AW,AY
  voice       AA,AE,AH,AO,AW,AY,B,D,DH,EH,ER,EY,G,IH,IY,JH,L,M,N,NG,OW,OY,R,UH,UW,V,W,Z,ZH
  continuant  AA,AE,AH,AO,AW,AY,DH,EH,ER,EY,F,HH,IH,IY,L,OW,OY,R,S,SH,TH,UH,UW,V,W,Z,ZH
  nasal       M,N,NG
  strident    CH,F,JH,S,SH,V,Z,ZH
  sil         sil
)

# reversed mapping for synthesis
typeset -A attRevMap
attRevMap=(
  XX sil
  M  cons,ant,voi,nas
  N  cons,ant,cor,voi,nas
  NG cons,hig,bac,voi,nas
  P  cons,ant
  T  cons,ant,cor
  K  cons,hig,bac
  B  cons,ant,voi
  D  cons,ant,cor,voi
  G  cons,hig,bac,voi
  V  cons,ant,voi,cont,str
  DH cons,ant,cor,voi,cont
  Z  cons,ant,cor,voi,cont,str
  ZH cons,hig,cor,voi,cont,str
  F  cons,ant,cont,str
  TH cons,ant,cor,cont
  S  cons,ant,cor,cont,str
  SH cons,hig,cor,cont,str
  HH low,cont
  R  voc,cons,cor,voi,cont
  Y  hig,voi,cont
  W  hig,bac,rou,voi,cont
  L  voc,cons,ant,cor,voi,str
  CH cons,hig,cor,str
  JH cons,hig,cor,voi,str
  IY voc,hig,ten,voi,cont
  IH voc,hig,voi,cont
  UW voc,hig,bac,rou,ten,voi,cont
  UH voc,hig,bac,rou,voi,cont
  EH voc,voi,cont
  ER voc,voi,ten,cont
  AH voc,bac,voi,cont
  AO voc,bac,rou,voi,cont
  AE voc,low,voi,cont
  AA voc,bac,low,ten,voi,cont
  EY voc,ten,voi,cont,ris
  OW voc,bac,rou,ten,voi,cont,ris
  OY voc,bac,rou,voi,cont,ris
  AW voc,bac,low,ten,voi,cont,ris
  AY voc,low,ten,voi,cont,ris
)
