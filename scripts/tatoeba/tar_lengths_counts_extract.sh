#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility

lengths=$base/lengths
counts=$base/counts
extracts=$base/extracts

summaries=$base/summaries
summaries_sub=$summaries/tatoeba

mkdir -p $summaries_sub

if [[ -d $lengths ]]; then
    (cd $base && tar -czf $summaries_sub/lengths.tar.gz lengths)

    # upload to home.ifi.uzh.ch

    scp $summaries_sub/lengths.tar.gz mmueller@home.ifi.uzh.ch:/home/files/cl/archiv/2020/clcontra/lengths.tar.gz
fi

if [[ -d $counts ]]; then
    (cd $base && tar -czf $summaries_sub/counts.tar.gz counts)

    # upload to home.ifi.uzh.ch

    scp $summaries_sub/counts.tar.gz mmueller@home.ifi.uzh.ch:/home/files/cl/archiv/2020/clcontra/counts.tar.gz
fi

if [[ -d $extracts ]]; then
    (cd $base && tar -czf $summaries_sub/extracts.tar.gz extracts)

    # upload to home.ifi.uzh.ch

    scp $summaries_sub/extracts.tar.gz mmueller@home.ifi.uzh.ch:/home/files/cl/archiv/2020/clcontra/extracts.tar.gz
fi
