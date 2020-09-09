#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility

scripts=$base/scripts
evaluations=$base/evaluations

summaries=$base/summaries
summaries_sub=$summaries/tatoeba

mkdir -p $summaries_sub

source $base/venvs/sockeye3-cpu/bin/activate

python $scripts/tatoeba/summarize.py --eval-folder $evaluations > $summaries_sub/summary.tsv
