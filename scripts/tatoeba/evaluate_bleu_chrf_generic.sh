#! /bin/bash

# calling script needs to set

# $base
# $src
# $trg
# $model_name
# $seeds
# $corpora
# $utility_functions
# $sample_positions
# $beam_sizes

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

        for beam_size in $beam_sizes; do

            hyp=$translations_sub_sub/$corpus.beam.$length_penalty_alpha.top.$beam_size.trg
            output_prefix=$evaluations_sub_sub/$corpus.beam.$length_penalty_alpha.top.$beam_size

            output=$output_prefix.bleu

            . $scripts/tatoeba/evaluate_bleu_more_generic.sh

            output=$output_prefix.chrf_1
            chrf_beta=1

            . $scripts/tatoeba/evaluate_chrf_more_generic.sh

            output=$output_prefix.chrf_2
            chrf_beta=2

            . $scripts/tatoeba/evaluate_chrf_more_generic.sh

            output=$output_prefix.chrf_3
            chrf_beta=3

            . $scripts/tatoeba/evaluate_chrf_more_generic.sh

        done
    done

    # sample top (single sample), different absolute positions from 1 to 100 * num_seeds
    # e.g. dev.sample.top.1.trg

    for seed in $seeds; do
        for pos in {1..100}; do

            let "absolute_pos=(pos + (($seed - 1) * 100))"

            hyp=$samples_sub_sub/$corpus.sample.top.$absolute_pos.trg
            output_prefix=$evaluations_sub_sub/$corpus.sample.top.$absolute_pos

            output=$output_prefix.bleu

            . $scripts/tatoeba/evaluate_bleu_more_generic.sh

            output=$output_prefix.chrf_1
            chrf_beta=1

            . $scripts/tatoeba/evaluate_chrf_more_generic.sh

            output=$output_prefix.chrf_2
            chrf_beta=2

            . $scripts/tatoeba/evaluate_chrf_more_generic.sh

            output=$output_prefix.chrf_3
            chrf_beta=3

            . $scripts/tatoeba/evaluate_chrf_more_generic.sh
        done
    done

    # MBR decoding with samples (5 .. 100), different seeds, different utility functions
    # e.g. dev.mbr.sample.40.1.trg.text

    for num_samples in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100; do
        for seed in $seeds; do

            for utility_function in $utility_functions; do

                hyp=$mbr_sub_sub/$corpus.mbr.$utility_function.sample.$num_samples.$seed.trg.text
                output_prefix=$evaluations_sub_sub/$corpus.mbr.$utility_function.sample.$num_samples.$seed

                output=$output_prefix.bleu

                . $scripts/tatoeba/evaluate_bleu_more_generic.sh

                output=$output_prefix.chrf_1
                chrf_beta=1

                . $scripts/tatoeba/evaluate_chrf_more_generic.sh

                output=$output_prefix.chrf_2
                chrf_beta=2

                . $scripts/tatoeba/evaluate_chrf_more_generic.sh

                output=$output_prefix.chrf_3
                chrf_beta=3

                . $scripts/tatoeba/evaluate_chrf_more_generic.sh

            done
        done
    done

    # MBR decoding with beam nbest list (5 .. 100), different utility functions,
    # different length penalties to produce nbest list

    for length_penalty_alpha in 0.0 1.0; do

        for num_samples in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100; do

            for utility_function in $utility_functions; do

                hyp=$mbr_sub_sub/$corpus.mbr.$utility_function.beam.$length_penalty_alpha.$num_samples.trg.text
                output_prefix=$evaluations_sub_sub/$corpus.mbr.$utility_function.beam.$length_penalty_alpha.$num_samples

                output=$output_prefix.bleu

                . $scripts/tatoeba/evaluate_bleu_more_generic.sh

                output=$output_prefix.chrf_1
                chrf_beta=1

                . $scripts/tatoeba/evaluate_chrf_more_generic.sh

                output=$output_prefix.chrf_2
                chrf_beta=2

                . $scripts/tatoeba/evaluate_chrf_more_generic.sh

                output=$output_prefix.chrf_3
                chrf_beta=3

                . $scripts/tatoeba/evaluate_chrf_more_generic.sh
            done
        done
    done

done
