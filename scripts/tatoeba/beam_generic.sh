#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name

data=$base/data
data_sub=$data/${src}-${trg}

models=$base/models
models_sub=$models/${src}-${trg}

translations=$base/translations
translations_sub=$translations/${src}-${trg}
translations_sub_sub=$translations_sub/$model_name

mkdir -p $translations
mkdir -p $translations_sub
mkdir -p $translations_sub_sub

source $base/venvs/sockeye3/bin/activate

model_path=$models_sub/$model_name

# beam translation

for corpus in dev test variations; do

    if [[ -s $translations_sub_sub/$corpus.pieces.trg ]]; then
      echo "File exists: $translations_sub_sub/$corpus.pieces.trg"
      echo "Skipping"
      continue
    fi

    # produce nbest list, desired beam size, desired batch size

    # 1-best, fixed beam size, fixed batch size

    OMP_NUM_THREADS=1 python -m sockeye.translate \
            -i $data_sub/$corpus.pieces.src \
            -o $translations_sub_sub/$corpus.pieces.trg \
            -m $model_path \
            --beam-size 10 \
            --length-penalty-alpha 1.0 \
            --device-ids 0 \
            --batch-size 64 \
            --disable-device-locking

    # undo pieces

    cat $translations_sub_sub/$corpus.pieces.trg | sed 's/ //g;s/▁/ /g' > $translations_sub_sub/$corpus.trg

done
