#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# Danish -> Esperanto

src=dan
trg=epo

# baseline

train_additional_args="--label-smoothing 0.0"

utility_functions="sentence-chrf-balanced"

corpora="test slice-test"

# model 1: create a dev slice, but do not optimize training on it

preprocess_create_slice_dev="true"

train_dev_corpus="dev"

model_name="slice_dev"

. $scripts/tatoeba/run_tatoeba_generic.sh

# model 2: create a dev slice, and optimize training on it

preprocess_create_slice_dev="true"

train_dev_corpus="slice-dev"

model_name="slice_dev+optimize"

. $scripts/tatoeba/run_tatoeba_generic.sh
