#!/usr/bin/zsh
#
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
# See the file COPYING for the licence associated with this software.
#
# A SPE map.
#
# Milos Cernak, Dec. 2015
#   -the maps created by Xingyu Na
#

typeset -A attMap
attMap=(
  # basic
  vocalic     i,i:,y,y:,i2,i3,I,u,u:,z2,Ml,s@,s7,s@r,U,e,E,E_r,ae,o,a,a2,A,a3,Ml
  consonantal Mm,Mn,n2,N,Mp,ph,Mt,th,Mk,kh,f,s,s1,z2,s3,Ml,ts,ts2,ts3,tsh,tsh2,tsh3
  # place
  high        N,o,Mk,kh,s3,s2,j,w,ts3,tsh3,i,i:,I,u,y,y:,i3,u:,U,s@,ts2,tsh2
  back        A,N,o,Mk,kh,s2,w,u,i3,u:,U,E_r,o,A,a3
  low         A,a,E,e,x,E_r,ae,o,A,a2
  anterior    Mm,Mn,e,Mp,ph,Mt,th,f,s,Ml,ts,ts2,tsh
  coronal     Mn,n2,Mt,th,s,z2,s3,Ml,ts,ts3,tsh,tsh3,i2
  # manner
  round       w,u,y,u:,U,o
  tense       i,i:,u,y,i2,u:,s@r,E_r
  voice       Mm,Mn,n2,N,Mp,Mt,Mk,z2,j,Ml,w,ts,ts3,i,i:,I,u,y,y:,i2,i3,u:,E,s7,s@r,U,E_r,o,A,a,a2,a3
  continuant  f,s,z2,s3,s2,x,j,Ml,w,ts,ts3,i,I,u,y,y:,E,s@,U,e,ae,o,A,a
  nasal       Mm,Mn,n2,N
  strident    f,s,s3,s2,ts,ts3,tsh3,ts2,tsh,tsh2
  sil         sil
)

# reversed mapping for synthesis
typeset -A attRevMap
attRevMap=(
  XX sil
  A      vocalic,back,low,voice,continuant
  a      vocalic,low,voice,continuant
  a2     vocalic,low,voice
  a3     vocalic,back,voice
  e      vocalic,low,anterior,continuant
  E      vocalic,low,voice,continuant
  E_r    vocalic,back,low,tense,voice
  ae     vocalic,low,continuant
  i      vocalic,high,tense,voice,continuant
  i:     vocalic,high,tense,voice
  y      vocalic,high,round,tense,voice,continuant
  y:     vocalic,high,voice,continuant
  i2     vocalic,coronal,tense,voice
  i3     vocalic,high,back,voice
  I      vocalic,high,voice,continuant
  o      vocalic,back,low,round,voice,continuant
  u      vocalic,high,back,round,tense,voice,continuant
  u:     vocalic,high,back,round,tense,voice
  U      vocalic,high,back,round,voice,continuant
  z2     vocalic,coronal,voice,continuant
  Ml     vocalic,anterior,coronal,voice,continuant
  s@     vocalic,high,continuant
  s7     vocalic,voice
  s@r    vocalic,tense,voice
  Mm     consonantal,anterior,voice,nasal
  Mn     consonantal,anterior,coronal,voice,nasal
  n2     consonantal,coronal,voice,nasal
  N      consonantal,high,back,voice,nasal
  Mp     consonantal,anterior,voice
  ph     consonantal,anterior
  Mt     consonantal,anterior,coronal,voice
  th     consonantal,anterior,coronal
  Mk     consonantal,high,back,voice
  kh     consonantal,high,back
  f      consonantal,anterior,continuant,strident
  s      consonantal,anterior,coronal,continuant,strident
  s1     consonantal
  s2     consonantal,high,back,continuant,strident
  s3     consonantal,high,coronal,continuant,strident
  ts     consonantal,anterior,coronal,voice,continuant,strident
  ts2    consonantal,high,anterior,strident
  ts3    consonantal,high,coronal,voice,continuant,strident
  tsh    consonantal,anterior,coronal,strident
  tsh2   consonantal,high,strident
  tsh3   consonantal,high,coronal,strident
)
