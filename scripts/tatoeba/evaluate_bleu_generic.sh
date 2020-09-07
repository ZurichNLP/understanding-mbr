#! /bin/bash

# calling script needs to set

# $base
# $src
# $trg
# $model_name

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

for corpus in dev test; do

    ref=$data_sub_sub/$corpus.trg

    # beam top translations

    hyp=$translations_sub_sub/$corpus.beam.top.trg
    output=$evaluations_sub_sub/$corpus.beam.top.bleu

    . $scripts/tatoeba/evaluate_bleu_more_generic.sh

    # sample top (single sample), different seeds
    # e.g. dev.sample.top.1.trg

    for seed in {1..5}; do

        hyp=$samples_sub_sub/$corpus.sample.top.$seed.trg
        output=$evaluations_sub_sub/$corpus.sample.top.$seed.bleu

        . $scripts/tatoeba/evaluate_bleu_more_generic.sh

    done

    # MBR decoding with samples (5 .. 100), different seeds
    # e.g. dev.mbr.sample.40.1.trg.text

    for num_samples in 5 10; do # 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100; do
        for seed in {1..5}; do

            hyp=$mbr_sub_sub/$corpus.mbr.sample.$num_samples.$seed.trg.text
            output=$evaluations_sub_sub/$corpus.mbr.sample.$num_samples.$seed.bleu

            . $scripts/tatoeba/evaluate_bleu_more_generic.sh
        done
    done

    # MBR decoding with beam nbest list (5 .. 100)

    for num_samples in 5 10; do # 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100; do

        hyp=$mbr_sub_sub/$corpus.mbr.beam.$num_samples.trg.text
        output=$evaluations_sub_sub/$corpus.mbr.beam.$num_samples.bleu

        . $scripts/tatoeba/evaluate_bleu_more_generic.sh
    done

done
