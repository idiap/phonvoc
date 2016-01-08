Phonetic and Phonological vocoding training
=======================================================

based on Kaldi wsj/s5 training scripts
dependencies: Idiap SSP, Kaldi

0. Set language and phonology system, a synthesis voice db and
re-synthesis vocoder in ../Config.sh

For example:
export lang=English
export phon=SPE
export voice=Nancy
export vocod=LPC

======================= ANALYSIS =======================

1. Data preparation.  Execute the following scripts in order.

$ CreateLinks.sh

This will set up links to KALDI, and also your own temp space (for
features).

$ aExtract.sh

- this will mfcc extract features into ./feats
- prepared Kaldi data is located in ../lang/$lang/data
- and it outputs log file into ./log/make_mfcc

2. Train Phonological Analysis DNNs.

$ aPretrainDNN.sh

- initialise DNN training using ../lang/$lang/data/init
- the output is in dnns/pretrain-dbn-$lang

$ aTrainDNNs.sh

Prepare label data and train all phonological feature detectors:
- Kaldi label data is in ../lang/$lang/labels
- the trained DNNs are in dnns-${lang}-${phon}

======================= SYNTHESIS  =======================

3. Prepare data - synthesis is based on a particluar $voice.

$ sExtract.sh

- this will mfcc extract features into ./feats
- prepared Kaldi data is located in ../lang/$lang/data/$voice

$ sPrepareInFeatures.sh

- this will run phonological analysis of the synthesis training data
- extracted features are prepared in ../feats/in-$lang-$phon-$voice

$ sPrepareOutFeatures.sh

- this will run vocoder analysis of the synthesis training data
- extracted features are prepared in ../feats/out-$lang-$voice-$vocod

$ sSplitData.sh

- this will split training in/out features into train/dev/test
- the split data is in ../lang/$lang/data/$voice

4. Train synthesis DNN

$ sPretrainDNN.sh

- initialise DNN training using ../lang/$lang/data/$voice/itrain
- the output is in ./dbn-$lang-$phon-$voice-paramType$paramType

$ sTrainDNN.sh

- train synthesis DNN
- the output is in
  dnns/$hlayers-$hdim-$lrate-$lang-$phon-$voice-$vocod-paramType$paramType

5. Test the training

$ sGenerateSamples.sh

- do forward pass on ../lang/$lang/data/$voice/itest
- re-synthesize speec with $vocod vocoder
- encoded speech is in enc/${lang}-${phon}-{$voice}-{vocod}

$ sPESQ.sh/sMCD.sh

- run objective comparison of original and generated samples


--
Milos Cernak, Nov. 2015
