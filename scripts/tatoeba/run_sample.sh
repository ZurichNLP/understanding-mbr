#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# Danish -> Esperanto

src=dan
trg=epo

# baseline

model_name=baseline

train_additional_args=""
preprocess_copy_noise_probability="0.0"

. $scripts/tatoeba/run_tatoeba_generic.sh

# without label smoothing

model_name="no_label_smoothing"

train_additional_args="--label-smoothing 0.0"
preprocess_copy_noise_probability="0.0"

. $scripts/tatoeba/run_tatoeba_generic.sh

# with copies in the training data + label smoothing

train_additional_args="--label-smoothing 0.0"

# TODO: remove debug setting
noise_probabilities="0.1"

# final values:
# noise_probabilities="0.001 0.005 0.01 0.05 0.075 0.1 0.25 0.5"

for preprocess_copy_noise_probability in $noise_probabilities; do

    model_name="copy_noise.$noise_probability"

    . $scripts/tatoeba/run_tatoeba_generic.sh

done
