#! /bin/bash

mkdir -p html

# shorten to N first lines each

top=50

# domain robustness

langpair="deu-eng"
model_name="domain_robustness"

mkdir -p html/$langpair

for corpus in test it law koran subtitles; do
    scp mathmu@login.s3it.uzh.ch:/net/cephfs/scratch/mathmu/map-volatility/overlaps/deu-eng/$model_name/$corpus.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap \
        html/$langpair/$corpus.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap

    for lang in src trg; do
        scp mathmu@login.s3it.uzh.ch:/net/cephfs/scratch/mathmu/map-volatility/data/deu-eng/$model_name/$corpus.depieced.$lang html/$langpair/$corpus.depieced.$lang
    done
done

mv html/$langpair/test.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap html/$langpair/medical.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap

mv html/$langpair/test.depieced.src html/$langpair/medical.depieced.src
mv html/$langpair/test.depieced.trg html/$langpair/medical.depieced.trg

for corpus in medical it law koran subtitles; do
    mv html/$langpair/$corpus.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap temp
    head -n $top temp > html/$langpair/$corpus.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap

    for lang in src trg; do
        mv html/$langpair/$corpus.depieced.$lang temp
        head -n $top temp > html/$langpair/$corpus.depieced.$lang
    done
done

rm temp

# generate html

for corpus in medical it law koran subtitles; do
    python3 scripts/visualize.py \
       --source html/$langpair/$corpus.depieced.src \
       --reference html/$langpair/$corpus.depieced.trg \
       --nbest html/$langpair/$corpus.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap \
       > html/$langpair/$corpus.html
done

# upload to IFI home

for corpus in medical it law koran subtitles; do
    scp html/$langpair/$corpus.html mmueller@home.ifi.uzh.ch:/home/files/cl/archiv/2020/clcontra/$langpair.$model_name.$corpus.html
done

# copy noise models

# just a single corpus

corpus="slice-test"

for langpair in eng-mar ara-deu; do

    mkdir -p html/$langpair

    # get source and reference once, identical for all of those models

    for lang in src trg; do
        scp mathmu@login.s3it.uzh.ch:/net/cephfs/scratch/mathmu/map-volatility/data/$langpair/copy_noise.0.001/$corpus.depieced.$lang html/$langpair/$corpus.depieced.$lang

        mv html/$langpair/$corpus.depieced.$lang temp
        head -n $top temp > html/$langpair/$corpus.depieced.$lang
    done

    noise_probabilities="0.001 0.005 0.01 0.05 0.075 0.1 0.25 0.5"

    for noise_probability in $noise_probabilities; do

        model_name="copy_noise.$noise_probability"

        mkdir -p html/$langpair/$model_name

        scp mathmu@login.s3it.uzh.ch:/net/cephfs/scratch/mathmu/map-volatility/overlaps/$langpair/$model_name/$corpus.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap \
        html/$langpair/$model_name/$corpus.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap

        mv html/$langpair/$model_name/$corpus.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap temp
        head -n $top temp > html/$langpair/$model_name/$corpus.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap

        python3 scripts/visualize.py \
         --source html/$langpair/$corpus.depieced.src \
         --reference html/$langpair/$corpus.depieced.trg \
         --nbest html/$langpair/$model_name/$corpus.mbr.sentence-chrf-balanced.sample.100.1.nbest_overlap \
         > html/$langpair/$model_name/$corpus.html

         scp html/$langpair/$model_name/$corpus.html mmueller@home.ifi.uzh.ch:/home/files/cl/archiv/2020/clcontra/$langpair.$model_name.$corpus.html

    done

done

rm temp
