#!/usr/bin/zsh
#
# Copyright 2016 by Idiap Research Institute, http://www.idiap.ch
# See the file COPYING for the licence associated with this software.
#
# A Government Phonology (GP) map.
#
# Milos Cernak, Jan. 2016
#

typeset -A attMap
attMap=(
  A AA,AH,AE,AO,AW,AY,EY,OW,OY,EH,ER,R,T,TH,D,DH
  I IH,IY,EY,AE,AY,Y,EH,CH,JH,SH,ZH
  U UW,UH,OW,OY,AO,AW,W,R,B,F,M,P,V
  E IH,UH,AH,AO,EH,ER,K,G,NG,R,S,Z
  S L,B,P,M,T,D,G,CH,JH,K,N,NG
  h B,D,DH,F,G,HH,K,P,S,SH,T,TH,V,Z,ZH
  H CH,F,HH,K,P,S,SH,T,TH
  N M,N,NG
  a AA,AE
  i AY,EY,IY,OY,EH
  u AO,AW,OW,OY,UW
  sil sil
)

# reversed mapping for synthesis
typeset -A attRevMap
attRevMap=(
  XX sil
  M  U,S,N
  N  A,S,N
  NG E,S,N
  P  U,S,h,H
  T  A,S,h,H
  K  E,S,h,H
  B  U,S,h
  D  A,S,h
  G  S,h
  V  U,h
  DH A,h
  Z  E,h
  ZH I,h
  F  U,h,H
  TH A,h,H
  S  E,h,H
  SH I,h,H
  HH h,H
  R  A,U,E
  Y  I
  W  U
  L  A,S
  CH I,S,H
  JH I,S
  IY I,i
  UW U,u
  IH I
  UH U,E
  EH A,I
  ER A,E
  AH U,E
  AO A,U,E,u
  AE A
  AA A,a
  AX A,a
  EY A,I,i
  OW A,U,u
  OY A,I,U,i,u
  AW A,U,a,u
  AY A,I,a,i
)
