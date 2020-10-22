#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# French -> Latin

src=fra
trg=lat

# dry runs of all steps

dry_run="true"

# baseline

model_name="dry_run"

train_additional_args=""
preprocess_copy_noise_probability="0.0"

. $scripts/tatoeba/run_tatoeba_generic.sh
