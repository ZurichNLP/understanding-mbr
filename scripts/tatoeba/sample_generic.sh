#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name

scripts=$base/scripts

data=$base/data
data_sub=$data/${src}-${trg}

models=$base/models
models_sub=$models/${src}-${trg}

samples=$base/samples
samples_sub=$samples/${src}-${trg}
samples_sub_sub=$samples_sub/$model_name

mkdir -p $samples
mkdir -p $samples_sub
mkdir -p $samples_sub_sub

source $base/venvs/sockeye3/bin/activate

model_path=$models_sub/$model_name

# sampling translation

for corpus in dev test variations; do

    deactivate
    source $base/venvs/sockeye3/bin/activate

    for seed in {1..30}; do

        if [[ -s $samples_sub_sub/$corpus.pieces.$seed.trg ]]; then
          echo "File exists: $samples_sub_sub/$corpus.pieces.$seed.trg"
          echo "Skipping"
          continue
        fi

        # 1-best, fixed beam size, fixed batch size

        OMP_NUM_THREADS=1 python -m sockeye.translate \
                -i $data_sub/$corpus.pieces.src \
                -o $samples_sub_sub/$corpus.pieces.$seed.trg \
                -m $model_path \
                --sample \
                --seed $seed \
                --length-penalty-alpha 1.0 \
                --device-ids 0 \
                --batch-size 64 \
                --disable-device-locking

        # undo pieces

        cat $samples_sub_sub/$corpus.pieces.$seed.trg | sed 's/ //g;s/▁/ /g' > $samples_sub_sub/$corpus.$seed.trg

    done

    # change venv for correct version of sacrebleu that has TER

    deactivate
    source $base/venvs/sockeye3-cpu/bin/activate

    # MBR

    python $scripts/mbr_decoding.py \
        --inputs $samples_sub_sub/$corpus.{1..30}.trg \
        --output $samples_sub_sub/$corpus.mbr \
        --utility-function sentence-meteor \
        --num-workers 2

    cat $samples_sub_sub/$corpus.mbr | cut -f2 > $samples_sub_sub/$corpus.mbr.text

done
