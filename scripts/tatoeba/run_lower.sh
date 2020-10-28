#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# run some lower Tatoeba languages from
# https://github.com/Helsinki-NLP/Tatoeba-Challenge/blob/master/subsets/lower.md
# that have at least 1k dev and test data

LANG_PAIRS=(
    "bel rus"
#    "deu lat"
#    "eng ido"
#    "epo fas"
#    "fra lat"
#    "kaz rus"
#    "lat por"
#    "tur uig"
)

model_name="no_label_smoothing"

# without label smoothing

train_additional_args="--label-smoothing 0.0"

for PAIR in "${LANG_PAIRS[@]}"; do
    PAIR=($PAIR)
    src=${PAIR[0]}
    trg=${PAIR[1]}

    . $scripts/tatoeba/run_tatoeba_generic.sh

done
