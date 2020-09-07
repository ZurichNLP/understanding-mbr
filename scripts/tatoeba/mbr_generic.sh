#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name

base=$1
src=$2
trg=$3
model_name=$4

scripts=$base/scripts

samples=$base/samples
samples_sub=$samples/${src}-${trg}
samples_sub_sub=$samples_sub/$model_name

translations=$base/translations
translations_sub=$translations/${src}-${trg}
translations_sub_sub=$translations_sub/$model_name

mbr=$base/mbr
mbr_sub=$mbr/${src}-${trg}
mbr_sub_sub=$mbr_sub/$model_name

mkdir -p $mbr_sub_sub

source $base/venvs/sockeye3/bin/activate

for corpus in dev test variations; do

    deactivate
    source $base/venvs/sockeye3-cpu/bin/activate

    # MBR with sampled translations

    for seed in {1..5}; do

        # divide inputs into up to 8 parts

        mkdir -p $mbr_sub_sub/sample_parts.$seed

        cp $samples_sub_sub/$corpus.sample.nbest.$seed.trg $mbr_sub_sub/sample_parts.$seed/$corpus.sample.nbest.$seed.trg

        python $scripts/split.py --parts 8 --input $mbr_sub_sub/sample_parts.$seed/$corpus.sample.nbest.$seed.trg

        input=$mbr_sub_sub/sample_parts.$seed/$corpus.sample.nbest.$seed.trg

        for num_samples in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100; do

            parts_prefix=$mbr_sub_sub/sample_parts.$seed/$corpus.mbr.sample.$num_samples.$seed.trg

            # $scripts/tatoeba/mbr_more_generic.sh will add ".text" to this path as the final result file

            output=$mbr_sub_sub/$corpus.mbr.sample.$num_samples.$seed.trg

            . $scripts/tatoeba/mbr_more_generic.sh
        done
    done

    # MBR with beam translations

    # divide inputs into up to 8 parts

    mkdir -p $mbr_sub_sub/beam_parts

    cp $translations_sub_sub/$corpus.beam.nbest.trg $mbr_sub_sub/beam_parts/$corpus.beam.nbest.trg

    python $scripts/split.py --parts 8 --input $mbr_sub_sub/beam_parts/$corpus.beam.nbest.trg

    input=$mbr_sub_sub/beam_parts/$corpus.beam.nbest.trg

    for num_samples in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100; do

        parts_prefix=$mbr_sub_sub/beam_parts/$corpus.mbr.beam.$num_samples.trg
        output=$mbr_sub_sub/$corpus.mbr.beam.$num_samples.trg

        . $scripts/tatoeba/mbr_more_generic.sh
    done

done
