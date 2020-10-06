#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# run some medium Tatoeba languages from
# https://github.com/Helsinki-NLP/Tatoeba-Challenge/blob/master/subsets/medium.md
# that have at least 1k dev and test data

LANG_PAIRS=(
    "aze eng"
    "bel eng"
    "bre fra"
    "dan epo"
    "deu epo"
    "deu nds"
    "deu tat"
    "eng epo"
    "eng mar"
    "eng tuk"
)

for PAIR in "${LANG_PAIRS[@]}"; do
    PAIR=($PAIR)
    src=${PAIR[0]}
    trg=${PAIR[1]}

    # baseline

    model_name=baseline

    train_additional_args=""
    preprocess_copy_noise_probability="0.0"

    . $scripts/tatoeba/run_tatoeba_generic.sh

    # without label smoothing

    model_name="no_label_smoothing"

    train_additional_args="--label-smoothing 0.0"
    preprocess_copy_noise_probability="0.0"

    . $scripts/tatoeba/run_tatoeba_generic.sh

    # with copies in the training data + label smoothing

    for noise_probability in 0.1; do

        model_name="copy_noise.$noise_probability"

        train_additional_args="--label-smoothing 0.0"
        preprocess_copy_noise_probability=$noise_probability

        . $scripts/tatoeba/run_tatoeba_generic.sh

    done

done
