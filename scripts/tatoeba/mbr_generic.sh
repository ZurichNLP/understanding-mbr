#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name
# $dry_run
# $utility_functions
# $corpora

base=$1
src=$2
trg=$3
model_name=$4
dry_run=$5
utility_functions=$6
corpora=$7

scripts=$base/scripts

data=$base/data
data_sub=$data/${src}-${trg}
data_sub_sub=$data_sub/$model_name

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

source $base/venvs/sockeye3-cpu/bin/activate

seeds="1 2"

if [[ $dry_run == "true" ]]; then
    num_parts=2
else
    num_parts=32
fi

# measure time

SECONDS=0

#################

# for now, no oracle

oracle="false"

for corpus in $corpora; do

    ref=$data_sub_sub/$corpus.trg

    # MBR with sampled translations

    # (length penalty does not affect samples)

    for seed in $seeds; do

        # divide inputs into up to 32 parts

        mkdir -p $mbr_sub_sub/sample_parts.$seed

        cp $samples_sub_sub/$corpus.sample.nbest.$seed.trg $mbr_sub_sub/sample_parts.$seed/$corpus.sample.nbest.$seed.trg

        python $scripts/split.py --parts $num_parts --input $mbr_sub_sub/sample_parts.$seed/$corpus.sample.nbest.$seed.trg

        input=$mbr_sub_sub/sample_parts.$seed/$corpus.sample.nbest.$seed.trg

        for num_samples in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100; do

            for utility_function in $utility_functions; do

                parts_prefix=$mbr_sub_sub/sample_parts.$seed/$corpus.mbr.$utility_function.sample.$num_samples.$seed.trg

                # $scripts/tatoeba/mbr_more_generic.sh will add ".text" to this path as the final result file

                output=$mbr_sub_sub/$corpus.mbr.$utility_function.sample.$num_samples.$seed.trg

                . $scripts/tatoeba/mbr_more_generic.sh

            done
        done
    done

    # MBR with nbest beam translations

    # (length penalty does affect beam translations, seed does not)

    for length_penalty_alpha in 0.0 1.0; do

        for num_samples in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100; do

             # divide inputs into up to 32 parts

            mkdir -p $mbr_sub_sub/beam_parts.$num_samples

            cp $translations_sub_sub/$corpus.beam.$length_penalty_alpha.nbest.$num_samples.trg \
               $mbr_sub_sub/beam_parts.$num_samples/$corpus.beam.$length_penalty_alpha.nbest.$num_samples.trg

            python $scripts/split.py \
                --parts $num_parts \
                --input $mbr_sub_sub/beam_parts.$num_samples/$corpus.beam.$length_penalty_alpha.nbest.$num_samples.trg

            for utility_function in $utility_functions; do

                input=$mbr_sub_sub/beam_parts.$num_samples/$corpus.beam.$length_penalty_alpha.nbest.$num_samples.trg
                parts_prefix=$mbr_sub_sub/beam_parts.$num_samples/$corpus.mbr.$utility_function.beam.$length_penalty_alpha.$num_samples.trg

                # $scripts/tatoeba/mbr_more_generic.sh will add ".text" to this path as the final result file

                output=$mbr_sub_sub/$corpus.mbr.$utility_function.beam.$length_penalty_alpha.$num_samples.trg

                . $scripts/tatoeba/mbr_more_generic.sh

            done
        done
    done

done

echo "time taken:"
echo "$SECONDS seconds"
