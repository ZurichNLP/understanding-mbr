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

sample_positions="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100"
seeds="1 2"
beam_sizes="5 10"

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

counts=$base/counts
counts_sub=$counts/${src}-${trg}
counts_sub_sub=$counts_sub/$model_name

mkdir -p $counts_sub_sub

# compute counts for training data

# work off of depieced + tokenized final training data

input=$data_sub_sub/train.clean.trg.tok
output=$counts_sub_sub/train.count

. $scripts/tatoeba/counts_more_generic.sh

# compute counts of beam translations, samples and mbr

for corpus in $corpora; do

    # compute counts of reference translations

    input=$data_sub_sub/$corpus.trg.tok
    output=$counts_sub_sub/$corpus.count

    . $scripts/tatoeba/counts_more_generic.sh

    # beam top translations

    for length_penalty_alpha in 0.0 1.0; do

        for beam_size in $beam_sizes; do

            input=$translations_sub_sub/$corpus.beam.$length_penalty_alpha.top.$beam_size.trg.tok
            output=$counts_sub_sub/$corpus.beam.$length_penalty_alpha.top.$beam_size.count

            . $scripts/tatoeba/counts_more_generic.sh
        done
    done

     # sample top (single sample), different absolute positions from 1 to 100 * num_seeds
    # e.g. dev.sample.top.1.trg

    for seed in $seeds; do
        for pos in {1..100}; do

            let "absolute_pos=(pos + (($seed - 1) * 100))"

            input=$samples_sub_sub/$corpus.sample.top.$absolute_pos.trg.tok
            output=$counts_sub_sub/$corpus.sample.top.$absolute_pos.count

            . $scripts/tatoeba/counts_more_generic.sh
        done
    done

    # MBR decoding with samples (5 .. 100), different seeds, different utility functions
    # e.g. dev.mbr.sample.40.1.trg.text

    for num_samples in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100; do
        for seed in $seeds; do

            for utility_function in $utility_functions; do

                input=$mbr_sub_sub/$corpus.mbr.$utility_function.sample.$num_samples.$seed.trg.text.tok
                output=$counts_sub_sub/$corpus.mbr.$utility_function.sample.$num_samples.$seed.count

                . $scripts/tatoeba/counts_more_generic.sh

            done
        done
    done

    # MBR decoding with beam nbest list (5 .. 100), different utility functions,
    # different length penalties to produce nbest list

    for length_penalty_alpha in 0.0 1.0; do

        for num_samples in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100; do

            for utility_function in $utility_functions; do

                input=$mbr_sub_sub/$corpus.mbr.$utility_function.beam.$length_penalty_alpha.$num_samples.trg.text.tok
                output=$counts_sub_sub/$corpus.mbr.$utility_function.beam.$length_penalty_alpha.$num_samples.count

                . $scripts/tatoeba/counts_more_generic.sh

            done
        done
    done

done
