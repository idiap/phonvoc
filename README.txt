PhonVoc: Phonetic and Phonological vocoding
=======================================================

This is a computational platform for Phonetic and Phonological
vocoding, released under the BSD licence. See file COPYING for
details. The software is based on Kaldi (v. 489a1f5) and Idiap SSP.
For training of the analysis and synthesis models, follow please 
train/README.txt. 

For analysis and synthesis with the pre-trained models, set first
language and phonology systems, a synthesis voice and re-synthesis
vocoder in Config.sh. The following setup is pre-trained:

export lang=English # analysis trained on the LibriSPeech corpus
export phon=SPE     # the Sound Patterns of English
export voice=Anna   # synthesis trained on a LibriVox voice
export vocod=cepgm  # Idiap LPC vocoder with cepgm

======================= ANALYSIS ========================

1. analysis.sh examples/recording.wav

- this runs MFCC extraction and DNNs forward pass
- feature posteriors are prepared in recording/feats.scp

======================= SYNTHESIS ========================

2. synthesis.sh recording

- takes the feature posteriors and re-synthesize speech
- re-synthesized speech is in  recording/recording.wav

======================= EVALUATION  ======================

3. cdist.sh recording

- calculates Mel Cepstral Distortion of the original and
  re-synthesized recordings

======================= SPEECH VOCODING  =================

4. run.sh examples/recording.wav

- runs analysis, synthesis and evaluation of the input audio

=========== VERY LOW BIT RATE CODING PROTOTYPE ===========

- follow ./vlbr/README.txt


More technical details are available in:
- Milos Cernak and Philip N. Garner, PhonVoc: A Phonetic and
Phonological Vocoding Toolkit. In: Proceedings of Interspeech,
San Francisco, USA, 2016
- Milos Cernak, Blaise Potard and Philip N. Garner, Phonological
Vocoding Using Artificial Neural Networks. In: Proceedings of the
IEEE Intl. Conference on Acoustics, Speech and Signal Processing
(ICASSP). Brisbane, Australia, 2015


==
Milos Cernak, August 2016
