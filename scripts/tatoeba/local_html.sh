#! /bin/bash

mkdir -p html

for corpus in test it law koran subtitles; do
    scp mathmu@login.s3it.uzh.ch:/net/cephfs/scratch/mathmu/map-volatility/overlaps/deu-eng/domain_robustness/$corpus.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap html/$corpus.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap

    for lang in src trg; do
        scp mathmu@login.s3it.uzh.ch:/net/cephfs/scratch/mathmu/map-volatility/data/deu-eng/domain_robustness/$corpus.depieced.$lang html/$corpus.depieced.$lang
    done
done

mv html/test.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap html/medical.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap

mv html/test.depieced.src html/medical.depieced.src
mv html/test.depieced.trg html/medical.depieced.trg


# shorten to 50 first lines each

top=50

for corpus in medical it law koran subtitles; do
    mv html/$corpus.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap temp
    head -n $top temp > html/$corpus.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap

    for lang in src trg; do
        mv html/$corpus.depieced.$lang temp
        head -n $top temp > html/$corpus.depieced.$lang
    done
done

rm temp

# generate html

for corpus in medical it law koran subtitles; do
    python3 scripts/visualize.py \
       --source html/$corpus.depieced.src \
       --reference html/$corpus.depieced.trg \
       --nbest html/$corpus.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap \
       > html/$corpus.html
done

# upload to IFI home

for corpus in medical it law koran subtitles; do
    scp html/$corpus.html mmueller@home.ifi.uzh.ch:/home/files/cl/archiv/2020/clcontra/$corpus.html
done
