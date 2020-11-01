#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility

scripts=$base/scripts
evaluations=$base/evaluations

summaries=$base/summaries
summaries_sub=$summaries/tatoeba

mkdir -p $summaries_sub

source $base/venvs/sockeye3-cpu/bin/activate

python $scripts/tatoeba/summarize.py --eval-folder $evaluations > $summaries_sub/summary.tsv

# upload to home.ifi.uzh.ch

scp $summaries_sub/summary.tsv mmueller@home.ifi.uzh.ch:/home/files/cl/archiv/2020/clcontra/summary.tsv
