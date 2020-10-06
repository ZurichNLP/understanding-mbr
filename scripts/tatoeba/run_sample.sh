#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# Danish -> Esperanto

src=dan
trg=epo

# baseline

model_name=baseline

train_additional_args=""

. $scripts/tatoeba/run_tatoeba_generic.sh

# without label smoothing

model_name="no_label_smoothing"

train_additional_args="--label-smoothing 0.0"

. $scripts/tatoeba/run_tatoeba_generic.sh

# with copies in the training data

# TODO: add this call

model_name="copy_noise"

train_additional_args="--label-smoothing 0.0"