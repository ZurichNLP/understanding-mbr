#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# run some medium Tatoeba languages from
# https://github.com/Helsinki-NLP/Tatoeba-Challenge/blob/master/subsets/medium.md
# that have at least 1k dev and test data

# in this case, one low medium and high resource each
# this results in *24* models already

#LANG_PAIRS=(
#    "dan epo"
#    "bel rus"
#    "deu fra"
#)

LANG_PAIRS=(
    "eng mar"
    "ara deu"
)

noise_probabilities="0.001 0.005 0.01 0.05 0.075 0.1 0.25 0.5"

train_additional_args="--label-smoothing 0.0"

# needs high-memory preprocess instance

preprocess_execute_more_mem="true"

corpora="test slice-test"

for PAIR in "${LANG_PAIRS[@]}"; do
    PAIR=($PAIR)
    src=${PAIR[0]}
    trg=${PAIR[1]}

    # with copies in the training data + no label smoothing

    for noise_probability in $noise_probabilities; do

        model_name="copy_noise.$noise_probability"

        preprocess_copy_noise_probability=$noise_probability

        . $scripts/tatoeba/run_tatoeba_generic.sh

    done

done
