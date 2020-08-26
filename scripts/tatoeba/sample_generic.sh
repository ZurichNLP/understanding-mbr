#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name

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

source $base/venvs/sockeye3/bin/activate

# sampling translation

for corpus in dev test variations; do

    deactivate
    source $base/venvs/sockeye3/bin/activate

    for seed in {1..30}; do

        if [[ -s $samples_sub_sub/$corpus.$seed.trg ]]; then
            echo "Samples exist: $samples_sub_sub/$corpus.$seed.trg"

            num_lines_input=$(cat $data_sub_sub/$corpus.pieces.src | wc -l)
            num_lines_output=$(cat $samples_sub_sub/$corpus.$seed.trg | wc -l)

            if [[ $num_lines_input == $num_lines_output ]]; then
                echo "output exists and number of lines are equal to input:"
                echo "$data_sub_sub/$corpus.pieces.src == $samples_sub_sub/$corpus.$seed.trg"
                echo "$num_lines_input == $num_lines_output"
                echo "Skipping."
                continue
            else
                echo "$data_sub_sub/$corpus.pieces.src != $samples_sub_sub/$corpus.$seed.trg"
                echo "$num_lines_input != $num_lines_output"
                echo "Repeating step."
            fi

        fi

        # 1-best, fixed beam size, fixed batch size

        OMP_NUM_THREADS=1 python -m sockeye.translate \
                -i $data_sub_sub/$corpus.pieces.src \
                -o $samples_sub_sub/$corpus.pieces.$seed.trg \
                -m $models_sub_sub \
                --sample \
                --seed $seed \
                --length-penalty-alpha 1.0 \
                --device-ids 0 \
                --batch-size 64 \
                --disable-device-locking

        # undo pieces

        cat $samples_sub_sub/$corpus.pieces.$seed.trg | sed 's/ //g;s/▁/ /g' > $samples_sub_sub/$corpus.$seed.trg

    done
done
