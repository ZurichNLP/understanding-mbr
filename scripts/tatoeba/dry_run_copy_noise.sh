#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# Danish -> Esperanto

src=dan
trg=epo

# with copies in the training data + no label smoothing

train_additional_args="--label-smoothing 0.0"

noise_probabilities="0.1 0.3"

dry_run="true"

for preprocess_copy_noise_probability in $noise_probabilities; do

    model_name="dry_run_copy_noise.$preprocess_copy_noise_probability"

    . $scripts/tatoeba/run_tatoeba_generic.sh

done
