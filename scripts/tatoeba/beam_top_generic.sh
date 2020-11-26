#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name
# $corpora
# $beam_sizes
# $top_batch_size

data=$base/data
data_sub=$data/${src}-${trg}
data_sub_sub=$data_sub/$model_name

models=$base/models
models_sub=$models/${src}-${trg}
models_sub_sub=$models_sub/$model_name

translations=$base/translations
translations_sub=$translations/${src}-${trg}
translations_sub_sub=$translations_sub/$model_name

mkdir -p $translations_sub_sub

# beam translation

for corpus in $corpora; do

    for length_penalty_alpha in 0.0 1.0; do

        for beam_size in $beam_sizes; do

            input=$data_sub_sub/$corpus.pieces.src
            output_pieces=$translations_sub_sub/$corpus.beam.$length_penalty_alpha.top.$beam_size.pieces.trg
            output=$translations_sub_sub/$corpus.beam.$length_penalty_alpha.top.$beam_size.trg

            . $base/scripts/tatoeba/beam_top_more_generic.sh
        done
    done
done
