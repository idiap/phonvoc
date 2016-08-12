PhonNet: Neural Network Based Speech Coder
=======================================================

This is a prototype of a neural network based speech coder, released
under the BSD licence. The software is based on Kaldi and Idiap
SSP. For training of the analysis and synthesis neural network models,
follow please PhonVoc train recipes.

The build system is based on CMake. To build, you should only need to
do the following:
$ sh
$ (edit CMakeLists.txt to suit your environment)
$ cmake .
$ (or for a debug build call:)
$ cmake -D CMAKE_CXX_FLAGS_DEBUG:STRING="-g -Wall -Werror" -D CMAKE_BUILD_TYPE=debug .
$ make

To encode ../examples/recording.wav to recording.nn.wav:
$ run.sh ../examples/recording.wav recording.nn.wav


More technical details are available in:

Milos Cernak, Alexandros Lazaridis, Afsaneh Asaei, Philip N. Garner,
Composition of Deep and Spiking Neural Networks for Very Low Bit Rate
Speech Coding, http://arxiv.org/abs/1604.04383

==
Milos Cernak, August 2016
