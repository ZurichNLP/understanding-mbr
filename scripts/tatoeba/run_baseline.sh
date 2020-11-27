#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# Danish -> Esperanto

src=dan
trg=epo

# baseline

model_name="no_label_smoothing"

train_additional_args="--label-smoothing 0.0"

utility_functions="sentence-chrf-balanced"

create_slice_dev="false"

corpora="test"

. $scripts/tatoeba/run_tatoeba_generic.sh
