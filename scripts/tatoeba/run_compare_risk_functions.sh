#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# run some medium Tatoeba languages from
# https://github.com/Helsinki-NLP/Tatoeba-Challenge/blob/master/subsets/medium.md
# that have at least 1k dev and test data

# in this case, one low medium and high resource each

LANG_PAIRS=(
    "dan epo"
    "tur uig"
    "deu fin"
)

utility_functions="sentence-bleu sentence-bleu-symmetric sentence-ter sentence-ter-symmetric sentence-chrf sentence-chrf-symmetric sentence-meteor sentence-meteor-symmetric"

# compare risk functions + no label smoothing

# if those models are trained already, do not retrain

model_name="no_label_smoothing"

train_additional_args="--label-smoothing 0.0"

for PAIR in "${LANG_PAIRS[@]}"; do
    PAIR=($PAIR)
    src=${PAIR[0]}
    trg=${PAIR[1]}

    . $scripts/tatoeba/run_tatoeba_generic.sh

done
