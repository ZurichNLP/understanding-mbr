#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# German -> English, data from domain robustness paper / experiments

src=deu
trg=eng

model_name="no_label_smoothing"

# without label smoothing

train_additional_args="--label-smoothing 0.0"

# needs high-memory preprocess instance

preprocess_execute_more_mem="true"

# means that mbr can run for 3 days at most

mbr_execute_longer="true"

download_robustness_data="true"

corpora="test slice-test it law koran subtitles"
preprocess_additional_test_corpora="it law koran subtitles"

. $scripts/tatoeba/run_tatoeba_generic.sh
