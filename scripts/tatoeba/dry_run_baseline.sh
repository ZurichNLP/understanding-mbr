#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# French -> Latin

src=fra
trg=lat

# dry runs?
dry_run="true"

# baseline

model_name="dry_run"

train_additional_args=""
preprocess_copy_noise_probability="0.0"

. $scripts/tatoeba/run_tatoeba_generic.sh

# TODO:remove
exit

# without label smoothing

model_name="dry_run_no_label_smoothing"

train_additional_args="--label-smoothing 0.0"
preprocess_copy_noise_probability="0.0"

. $scripts/tatoeba/run_tatoeba_generic.sh
