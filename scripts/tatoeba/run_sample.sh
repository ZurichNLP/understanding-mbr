#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# Danish -> Esperanto

src=dan
trg=epo

. $scripts/tatoeba/run_tatoeba_generic.sh
