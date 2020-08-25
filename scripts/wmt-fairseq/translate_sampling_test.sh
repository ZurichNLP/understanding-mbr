#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

data=$base/data

samples=$base/samples
translations=$base/translations

mkdir -p $translations
mkdir -p $samples

translations_sub=$translations/toy
samples_sub=$samples/toy

mkdir -p $translations_sub
mkdir -p $samples_sub

data_sub=$data/toy

# sampling

input=$data_sub/toy_input
output_prefix=$samples_sub/toy_samples

. $scripts/sample_fairseq_generic.sh

# beam translations

input=$data_sub/toy_input
output=$translations_sub/toy_translation
nbest_size=3
beam_size=5

. $scripts/translate_fairseq_generic.sh
