#! /bin/bash

# calling script needs to set

# $base
# $src
# $trg
# $model_name
# $utility_functions
# $corpora

base=$1
src=$2
trg=$3
model_name=$4
utility_functions=$5
corpora=$6

scripts=$base/scripts

seeds="1 2"

source $base/venvs/sockeye3-cpu/bin/activate

data=$base/data
data_sub=$data/${src}-${trg}
data_sub_sub=$data_sub/$model_name

translations=$base/translations
translations_sub=$translations/${src}-${trg}
translations_sub_sub=$translations_sub/$model_name

samples=$base/samples
samples_sub=$samples/${src}-${trg}
samples_sub_sub=$samples_sub/$model_name

mbr=$base/mbr
mbr_sub=$mbr/${src}-${trg}
mbr_sub_sub=$mbr_sub/$model_name

lengths=$base/lengths
lengths_sub=$lengths/${src}-${trg}
lengths_sub_sub=$lengths_sub/$model_name

mkdir -p $lengths_sub_sub

# compute lengths of training data

# first tokenize final training data

input_untokenized=$data_sub_sub/train.clean.trg
input=$data_sub_sub/train.clean.trg.tok

cat $input_untokenized | python $scripts/tokenize_v13a.py > $input

output=$lengths_sub_sub/train.length

. $scripts/tatoeba/lengths_more_generic.sh

# compute lengths of beam translations, samples and mbr

for corpus in $corpora; do

    # compute lengths of reference translations

    input=$data_sub_sub/$corpus.trg.tok
    output=$lengths_sub_sub/$corpus.length

    . $scripts/tatoeba/lengths_more_generic.sh

    # beam top translations

    for length_penalty_alpha in 0.0 1.0; do

        input=$translations_sub_sub/$corpus.beam.$length_penalty_alpha.top.trg.tok
        output=$lengths_sub_sub/$corpus.beam.$length_penalty_alpha.top.length

        . $scripts/tatoeba/lengths_more_generic.sh

    done

    # sample top (single sample), different seeds
    # e.g. dev.sample.top.1.trg

    for seed in $seeds; do

        input=$samples_sub_sub/$corpus.sample.top.$seed.trg.tok
        output=$lengths_sub_sub/$corpus.sample.top.$seed.length

        . $scripts/tatoeba/lengths_more_generic.sh

    done

    # MBR decoding with samples (5 .. 100), different seeds, different utility functions
    # e.g. dev.mbr.sample.40.1.trg.text

    for num_samples in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100; do
        for seed in $seeds; do

            for utility_function in $utility_functions; do

                input=$mbr_sub_sub/$corpus.mbr.$utility_function.sample.$num_samples.$seed.trg.text.tok
                output=$lengths_sub_sub/$corpus.mbr.$utility_function.sample.$num_samples.$seed.length

                . $scripts/tatoeba/lengths_more_generic.sh

            done
        done
    done

    # MBR decoding with beam nbest list (5 .. 100), different utility functions,
    # different length penalties to produce nbest list

    for length_penalty_alpha in 0.0 1.0; do

        for num_samples in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100; do

            for utility_function in $utility_functions; do

                input=$mbr_sub_sub/$corpus.mbr.$utility_function.beam.$length_penalty_alpha.$num_samples.trg.text.tok
                output=$lengths_sub_sub/$corpus.mbr.$utility_function.beam.$length_penalty_alpha.$num_samples.length

                . $scripts/tatoeba/lengths_more_generic.sh

            done
        done
    done

done
