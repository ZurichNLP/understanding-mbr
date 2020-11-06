#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name
# $corpora
# $seeds
# $dry_run

if [[ $dry_run == "true" ]]; then
    batch_size=2
    dry_run_additional_args="--use-cpu"
else
    batch_size=14
    dry_run_additional_args=""
fi

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
                -o $samples_sub_sub/$corpus.sample_ordered.nbest.$seed.pieces.trg \
                -m $models_sub_sub \
                --sample \
                --beam-size 100 \
                --nbest-size 100 \
                --seed $seed \
                --length-penalty-alpha 0.0 \
                --device-ids 0 \
                --batch-size $batch_size \
                --disable-device-locking $dry_run_additional_args

        # shuffle nbest list of samples before doing anything else

        cat $samples_sub_sub/$corpus.sample_ordered.nbest.$seed.pieces.trg | \
            python $base/scripts/shuffle_nbest_translations.py > \
            $samples_sub_sub/$corpus.sample.nbest.$seed.pieces.trg

        # undo pieces in nbest JSON structures

        python $base/scripts/remove_pieces_from_nbest.py \
            --input $samples_sub_sub/$corpus.sample.nbest.$seed.pieces.trg > \
            $samples_sub_sub/$corpus.sample.nbest.$seed.trg

    done

    for seed in $seeds; do

        # extract samples at specific indexes of each translation JSON line as single_samples

        for pos in {1..100}; do

            let "absolute_pos=(pos + (($seed - 1) * 100))"

            if [[ -s $samples_sub_sub/$corpus.sample.top.$absolute_pos.trg ]]; then
                echo "Samples exist: $samples_sub_sub/$corpus.sample.top.$absolute_pos.trg"

                num_lines_output=$(cat $samples_sub_sub/$corpus.sample.top.$absolute_pos.trg | wc -l)

                if [[ $num_lines_input == $num_lines_output ]]; then
                    echo "output exists and number of lines are equal to input:"
                    echo "$data_sub_sub/$corpus.pieces.src == $samples_sub_sub/$corpus.sample.top.$absolute_pos.trg"
                    echo "$num_lines_input == $num_lines_output"
                    echo "Skipping."
                    continue
                else
                    echo "$data_sub_sub/$corpus.pieces.src != $samples_sub_sub/$corpus.sample.top.$absolute_pos.trg"
                    echo "$num_lines_input != $num_lines_output"
                    echo "Repeating step."
                fi
            fi

            cat $samples_sub_sub/$corpus.sample.nbest.$seed.trg | \
                python $scripts/extract_translation_at_index_from_nbest.py --pos $absolute_pos > \
                $samples_sub_sub/$corpus.sample.top.$absolute_pos.trg

        done
    done
done
