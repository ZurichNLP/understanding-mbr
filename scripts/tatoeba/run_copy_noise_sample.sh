#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# Danish -> Esperanto

src=dan
trg=epo

# with copies in the training data + label smoothing

train_additional_args="--label-smoothing 0.0"

# TODO: remove debug setting
noise_probabilities="0.1 0.3"

# final values:
# noise_probabilities="0.001 0.005 0.01 0.05 0.075 0.1 0.25 0.5"

for preprocess_copy_noise_probability in $noise_probabilities; do

    model_name="copy_noise.$preprocess_copy_noise_probability"
    stop_after_preprocess="true"

    . $scripts/tatoeba/run_tatoeba_generic.sh

done
