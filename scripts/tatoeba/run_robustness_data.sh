#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# German -> English, data from domain robustness paper / experiments

src=deu
trg=eng

model_name="domain_robustness"

# without label smoothing

train_additional_args="--label-smoothing 0.0"

# needs high-memory preprocess instance

preprocess_execute_more_mem="true"

# means that mbr can run for 4 days at most (this is not enough for this many corpora!)

mbr_execute_longer="true"

download_robustness_data="true"

corpora="test slice-test it law koran subtitles"
preprocess_additional_test_corpora="it law koran subtitles"

# trust this data, no need for langid (that in this case removes ~200k sentence pairs of 1m total)

preprocess_langid="false"

. $scripts/tatoeba/run_tatoeba_generic.sh
