#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# Danish -> Esperanto

src=dan
trg=epo

# baseline

model_name="no_label_smoothing"

train_additional_args="--label-smoothing 0.0"

mbr_execute_on_generic="true"

utility_functions="sentence-meteor-symmetric"


. $scripts/tatoeba/run_tatoeba_generic.sh
