#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# Danish -> Esperanto

src=dan
trg=epo

model_name=baseline

train_additional_args=""

. $scripts/tatoeba/run_tatoeba_generic.sh
