#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# run some highest Tatoeba languages from
# https://github.com/Helsinki-NLP/Tatoeba-Challenge/blob/master/subsets/highest.md
# that have at least 2k dev and test data
# AND that have a WMT testset

LANG_PAIRS=(
#    "ara eng"
#    "bul ita"
    "ces eng"
    "eng deu"
    "deu fra"
#    "dan spa"
#    "deu fin"
#    "ell rus"
#    "eng heb"
#    "fin swe"
#    "fra zho"
#    "hbs nor"
)

model_name="no_label_smoothing"

# without label smoothing

train_additional_args="--label-smoothing 0.0"

# needs high-memory preprocess instance

preprocess_execute_more_mem="true"

corpora="test slice-test wmt"

for PAIR in "${LANG_PAIRS[@]}"; do
    PAIR=($PAIR)
    src=${PAIR[0]}
    trg=${PAIR[1]}

    . $scripts/tatoeba/run_tatoeba_generic.sh

done
