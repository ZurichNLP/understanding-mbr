#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/../..

data=$base/data

samples=$base/samples
translations=$base/translations
variations=$base/variations

mkdir -p $translations
mkdir -p $samples

translations_sub=$translations/wmt
samples_sub=$samples/wmt

variations_sub=$variations/wmt

mkdir -p $translations_sub
mkdir -p $samples_sub

src=de
trg=en

data_sub=$data/wmt

nbest_size=3
beam_size=5

# sample and translate original texts (WMT sets separately)

for year in {13..20}; do

    input=$data_sub/wmt$year.$src-$trg.$src

    # sampling

    output_prefix=$samples_sub/wmt$year.$src-$trg.$trg

    . $scripts/sample_fairseq_generic.sh

    # beam translations

    output=$translations_sub/wmt$year.$src-$trg.$trg

    . $scripts/translate_fairseq_generic.sh

done

# sample and translate SUBNUM variations (all WMT concatenated)

input=$variations_sub/wmt.all.$src

# sampling

output_prefix=$samples_sub/variations

. $scripts/sample_fairseq_generic.sh

# beam translations

output=$translations_sub/variations.$trg

. $scripts/translate_fairseq_generic.sh
