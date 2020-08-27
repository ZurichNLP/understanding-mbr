#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility

scripts=$base/scripts
evaluations=$base/evaluations

source $base/venvs/sockeye3-cpu/bin/activate

python $scripts/tatoeba/summarize.py --eval-folder $evaluations
