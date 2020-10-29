#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility

lengths=$base/lengths
counts=$base/counts

summaries=$base/summaries
summaries_sub=$summaries/tatoeba

mkdir -p $summaries_sub

if [[ -d $lengths ]]; then
    tar -czvf $summaries_sub/lengths.tar.gz $lengths
fi

if [[ -d $counts ]]; then
    tar -czvf $summaries_sub/counts.tar.gz $counts
fi
