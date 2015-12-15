PhonVoc: Phonetic and Phonological vocoding
=======================================================

This is a computational platform for Phonetic and Phonological
vocoding, released under the BSD licence. See file COPYING for
details. The software is based on Kaldi and Idiap SSP. For training of
the analysis and synthesis models, follow please train/README.txt. 

For analysis and synthesis with the pre-trained models, set first
language and phonology systems, a synthesis voice and re-synthesis
vocoder in Config.sh. The following setup is pre-trained:

export lang=English # analysis trained on WSJ corpus
export phon=SPE     # the Sound Patterns of English
export voice=Nancy  # synthesis trained on Blizzard chall. Nancy
export vocod=cepgm  # Idiap LPC vocoder with cepgm

======================= ANALYSIS ========================

1. analysis.sh examples/nancy_11001.wav

- this runs MFCC extraction and DNNs forward pass
- feature posteriors are prepared in nancy_11001/attributes.ark

======================= SYNTHESIS  =======================

2. synthesis.sh nancy_11001

- takes the feature posteriors and re-synthesize speech
- re-synthesized speech is in  nancy_11001/nancy_11001.wav

======================= SPEECH VOCODING  =================

3. run.sh examples/nancy_11001.wav

- runs both analysis and synthesis of the input audio

More technical details are available in:
- Milos Cernak, Blaise Potard and Philip N. Garner, Phonological
Vocoding Using Artificial Neural Networks . In: Proceedings of the
IEEE Intl. Conference on Acoustics, Speech and Signal Processing
(ICASSP). Brisbane, Australia, 2015
The functionality is covered also by
- Afsaneh Asaei, Milos Cernak, Hervé Bourlard, Signal processing
method and apparatus based on structured sparsity of phonological
features. US Patent Application US2015846036 (14/846,036), Sep. 4,
2015.

==
Milos Cernak, December 2015
