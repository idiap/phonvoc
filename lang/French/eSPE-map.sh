#!/usr/bin/zsh
#
# Copyright 2015 by Idiap Research Institute, http://www.idiap.ch
# See the file COPYING for the licence associated with this software.
#
# A SPE map.
#
# Milos Cernak, Dec. 2015
#

typeset -A attMap
attMap=(
    # manner
    Vowel       i,y,u,e,e^,_2_,o,o^,@,E,_9_,O,a,a^,_9_^,_6_
    Fricative   f,v,s,S,z,Z,R
    Nasal       m,n,J,N,a^,o^,_9_^,e^
    Stop        b,d,g,p,t,k
    Approximant w,l,j,H
    # place
    Alveolar    s,z
    Postalveolar S,Z
    Coronal     d,l,n,s,t,z,S,Z
    High        y,i,S,u,j,g,k,N 
    Labial      b,f,m,p,v,w,H
    Low         a^,a,_9_^,O,o,o^
    Mid         _2_,e^,e,_9_,E
    Uvular      R
    Velar       g,k,N,J
    # others
    Anterior    b,d,f,l,m,n,p,s,t,v,z,w
    Back        g,k,o,o^,O,u
    Lennis      z,b,Z,v,g,d
    Fortis      f,t,s,p,k,S
    Dorsal      J,N,j,k,g,R
    Round       o,O,o^,u,_9_^,_9_,y,_2_
    Unround     a,a^,i,e^,e,E,_6_
    Voiced      i,y,u,e,e^,_2_,o,o^,@,E,_9_,O,a,a^,_9_^,_6_,z,j,l,m,H,w,b,Z,N,J,n,v,g,R,d
    Central     @,_6_
    Silence     sil
)

# reversed mapping for synthesis
typeset -A attRevMap
attRevMap=(
  XX sil
)
