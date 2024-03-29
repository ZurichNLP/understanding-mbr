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

source $base/venvs/sockeye3-cpu/bin/activate

scripts=$base/scripts

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

METEOR="java -Xmx2G -jar $base/tools/meteor/meteor-*.jar "
METEOR_PARAMS=" -l other -q"

# compute METEOR with internal tokenization

for corpus in $corpora; do

    # tokenize reference once

    tokenized_ref=$data_sub_sub/$corpus.trg.tok

    cat $data_sub_sub/$corpus.trg | \
        python $scripts/tokenize_v13a.py \
        > $tokenized_ref

   # beam top translations

   for length_penalty_alpha in 0.0 1.0; do

       for beam_size in $beam_sizes; do

            untokenized_hyp=$translations_sub_sub/$corpus.beam.$length_penalty_alpha.top.$beam_size.trg
            output=$evaluations_sub_sub/$corpus.beam.$length_penalty_alpha.top.$beam_size.meteor

            . $scripts/tatoeba/evaluate_meteor_more_generic.sh

            output=$evaluations_sub_sub/$corpus.beam.$length_penalty_alpha.top.$beam_size.meteor_balanced

            . $scripts/tatoeba/evaluate_meteor_balanced_more_generic.sh
        done
    done

    # sample top (single sample), different absolute positions from 1 to 100 * num_seeds
    # e.g. dev.sample.top.1.trg

    for seed in $seeds; do
        for pos in {1..100}; do

            let "absolute_pos=(pos + (($seed - 1) * 100))"

            untokenized_hyp=$samples_sub_sub/$corpus.sample.top.$absolute_pos.trg
            output=$evaluations_sub_sub/$corpus.sample.top.$absolute_pos.meteor

            . $scripts/tatoeba/evaluate_meteor_more_generic.sh

            output=$evaluations_sub_sub/$corpus.sample.top.$absolute_pos.meteor_balanced

            . $scripts/tatoeba/evaluate_meteor_balanced_more_generic.sh
        done
    done

    # MBR decoding with samples (5 .. 100), different seeds, different utility functions
    # e.g. dev.mbr.sample.40.1.trg.text

    for num_samples in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100; do
        for seed in $seeds; do

            for utility_function in $utility_functions; do

                untokenized_hyp=$mbr_sub_sub/$corpus.mbr.$utility_function.sample.$num_samples.$seed.trg.text
                output=$evaluations_sub_sub/$corpus.mbr.$utility_function.sample.$num_samples.$seed.meteor

                . $scripts/tatoeba/evaluate_meteor_more_generic.sh

                output=$evaluations_sub_sub/$corpus.mbr.$utility_function.sample.$num_samples.$seed.meteor_balanced

                . $scripts/tatoeba/evaluate_meteor_balanced_more_generic.sh

            done
        done
    done

    # MBR decoding with beam nbest list (5 .. 100), different utility functions,
    # different length penalties to produce nbest lists

    for length_penalty_alpha in 0.0 1.0; do

        for num_samples in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100; do

            for utility_function in $utility_functions; do

                untokenized_hyp=$mbr_sub_sub/$corpus.mbr.$utility_function.beam.$length_penalty_alpha.$num_samples.trg.text
                output=$evaluations_sub_sub/$corpus.mbr.$utility_function.beam.$length_penalty_alpha.$num_samples.meteor

                . $scripts/tatoeba/evaluate_meteor_more_generic.sh

                output=$evaluations_sub_sub/$corpus.mbr.$utility_function.beam.$length_penalty_alpha.$num_samples.meteor_balanced

                . $scripts/tatoeba/evaluate_meteor_balanced_more_generic.sh

            done
        done
    done

done
