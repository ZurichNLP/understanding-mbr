#! /bin/bash

# calling script needs to set

# $base
# $src
# $trg
# $model_name
# $seeds
# $corpora

scripts=$base/scripts

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

evaluations=$base/evaluations
evaluations_sub=$evaluations/${src}-${trg}
evaluations_sub_sub=$evaluations_sub/$model_name

mkdir -p $evaluations_sub_sub

# compute case-sensitive BLEU on detokenized data

for corpus in $corpora; do

    ref=$data_sub_sub/$corpus.trg

    # beam top translations

    for length_penalty_alpha in 0.0 1.0; do

        hyp=$translations_sub_sub/$corpus.beam.$length_penalty_alpha.top.trg
        output=$evaluations_sub_sub/$corpus.beam.$length_penalty_alpha.top.bleu

        . $scripts/tatoeba/evaluate_bleu_more_generic.sh

    done

    # sample top (single sample), different seeds
    # e.g. dev.sample.top.1.trg

    for seed in $seeds; do

        hyp=$samples_sub_sub/$corpus.sample.top.$seed.trg
        output=$evaluations_sub_sub/$corpus.sample.top.$seed.bleu

        . $scripts/tatoeba/evaluate_bleu_more_generic.sh

    done

    # MBR decoding with samples (5 .. 100), different seeds, different utility functions
    # e.g. dev.mbr.sample.40.1.trg.text

    for num_samples in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100; do
        for seed in $seeds; do

            for utility_function in sentence-meteor sentence-meteor-symmetric; do

                hyp=$mbr_sub_sub/$corpus.mbr.$utility_function.sample.$num_samples.$seed.trg.text
                output=$evaluations_sub_sub/$corpus.mbr.$utility_function.sample.$num_samples.$seed.bleu

                . $scripts/tatoeba/evaluate_bleu_more_generic.sh

            done
        done
    done

    # MBR decoding with beam nbest list (5 .. 100), different utility functions,
    # different length penalties to produce nbest list

    for length_penalty_alpha in 0.0 1.0; do

        for num_samples in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100; do

            for utility_function in sentence-meteor sentence-meteor-symmetric; do

                hyp=$mbr_sub_sub/$corpus.mbr.$utility_function.beam.$length_penalty_alpha.$num_samples.trg.text
                output=$evaluations_sub_sub/$corpus.mbr.$utility_function.beam.$length_penalty_alpha.$num_samples.bleu

                . $scripts/tatoeba/evaluate_bleu_more_generic.sh
            done
        done
    done

done
