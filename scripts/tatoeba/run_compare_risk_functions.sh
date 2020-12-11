#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# run some medium Tatoeba languages from
# https://github.com/Helsinki-NLP/Tatoeba-Challenge/blob/master/subsets/medium.md
# that have at least 1k dev and test data

# in this case, one low medium and high resource each

LANG_PAIRS=(
    "dan epo"
    "aze eng"
    "deu fra"
    "bel rus"
)

utility_functions="sentence-bleu sentence-bleu-symmetric sentence-chrf sentence-chrf-symmetric sentence-chrf-balanced sentence-meteor sentence-meteor-balanced sentence-meteor-symmetric"

# compare risk functions + no label smoothing

# if those models are trained already, do not retrain

model_name="no_label_smoothing"

train_additional_args="--label-smoothing 0.0"

# needs high-memory preprocess instance

preprocess_execute_more_mem="true"

# means that mbr can run for 3 days at most

mbr_execute_longer="true"

corpora="test slice-test"

for PAIR in "${LANG_PAIRS[@]}"; do
    PAIR=($PAIR)
    src=${PAIR[0]}
    trg=${PAIR[1]}

    . $scripts/tatoeba/run_tatoeba_generic.sh

done
