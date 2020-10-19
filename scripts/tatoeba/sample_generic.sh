#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name
# $corpora
# $seeds

scripts=$base/scripts

data=$base/data
data_sub=$data/${src}-${trg}
data_sub_sub=$data_sub/$model_name

models=$base/models
models_sub=$models/${src}-${trg}
models_sub_sub=$models_sub/$model_name

samples=$base/samples
samples_sub=$samples/${src}-${trg}
samples_sub_sub=$samples_sub/$model_name

mkdir -p $samples_sub_sub

# sampling translation

for corpus in $corpora; do

    deactivate
    source $base/venvs/sockeye3/bin/activate

    for seed in $seeds; do

        if [[ -s $samples_sub_sub/$corpus.sample.top.$seed.trg ]]; then
            echo "Samples exist: $samples_sub_sub/$corpus.sample.top.$seed.trg"

            num_lines_input=$(cat $data_sub_sub/$corpus.pieces.src | wc -l)
            num_lines_output=$(cat $samples_sub_sub/$corpus.sample.top.$seed.trg | wc -l)

            if [[ $num_lines_input == $num_lines_output ]]; then
                echo "output exists and number of lines are equal to input:"
                echo "$data_sub_sub/$corpus.pieces.src == $samples_sub_sub/$corpus.sample.top.$seed.trg"
                echo "$num_lines_input == $num_lines_output"
                echo "Skipping."
                continue
            else
                echo "$data_sub_sub/$corpus.pieces.src != $samples_sub_sub/$corpus.sample.top.$seed.trg"
                echo "$num_lines_input != $num_lines_output"
                echo "Repeating step."
            fi

        fi

        # 100 samples, nbest size 100, beam size 100

        OMP_NUM_THREADS=1 python -m sockeye.translate \
                -i $data_sub_sub/$corpus.pieces.src \
                -o $samples_sub_sub/$corpus.sample.nbest.$seed.pieces.trg \
                -m $models_sub_sub \
                --sample \
                --beam-size 100 \
                --nbest-size 100 \
                --seed $seed \
                --length-penalty-alpha 1.0 \
                --device-ids 0 \
                --batch-size 14 \
                --disable-device-locking

         # undo pieces in nbest JSON structures

        python $base/scripts/remove_pieces_from_nbest.py \
            --input $samples_sub_sub/$corpus.sample.nbest.$seed.pieces.trg > \
            $samples_sub_sub/$corpus.sample.nbest.$seed.trg

        # extract first sample of each translation JSON line as single_sample

        cat $samples_sub_sub/$corpus.sample.nbest.$seed.trg | \
            python $scripts/extract_top_translations_from_nbest.py > \
            $samples_sub_sub/$corpus.sample.top.$seed.trg

    done
done
