#! /bin/bash

mkdir -p summaries/tatoeba

scp mathmu@login.s3it.uzh.ch:/net/cephfs/scratch/mathmu/map-volatility/summaries/tatoeba/summary.tsv summaries/tatoeba/summary.tsv

# also download lengths and counts (first tar the folders on S3IT)

scp mathmu@login.s3it.uzh.ch:/net/cephfs/scratch/mathmu/map-volatility/summaries/tatoeba/lengths.tar.gz summaries/tatoeba/lengths.tar.gz

scp mathmu@login.s3it.uzh.ch:/net/cephfs/scratch/mathmu/map-volatility/summaries/tatoeba/counts.tar.gz summaries/tatoeba/counts.tar.gz
