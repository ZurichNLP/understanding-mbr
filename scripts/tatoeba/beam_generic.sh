#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name

data=$base/data
data_sub=$data/${src}-${trg}
data_sub_sub=$data_sub/$model_name

models=$base/models
models_sub=$models/${src}-${trg}
models_sub_sub=$models_sub/$model_name

translations=$base/translations
translations_sub=$translations/${src}-${trg}
translations_sub_sub=$translations_sub/$model_name

mkdir -p $translations_sub_sub

source $base/venvs/sockeye3/bin/activate

# beam translation

for corpus in dev test variations; do

    if [[ -s $translations_sub_sub/$corpus.trg ]]; then
      echo "Translations exist: $translations_sub_sub/$corpus.trg"

      num_lines_input=$(cat $data_sub_sub/$corpus.pieces.src | wc -l)
      num_lines_output=$(cat $translations_sub_sub/$corpus.trg | wc -l)

      if [[ $num_lines_input == $num_lines_output ]]; then
          echo "output exists and number of lines are equal to input:"
          echo "$data_sub_sub/$corpus.pieces.src == $translations_sub_sub/$corpus.trg"
          echo "$num_lines_input == $num_lines_output"
          echo "Skipping."
          continue
      else
          echo "$data_sub_sub/$corpus.pieces.src != $translations_sub_sub/$corpus.trg"
          echo "$num_lines_input != $num_lines_output"
          echo "Repeating step."
      fi
    fi

    # produce nbest list, desired beam size, desired batch size

    # 1-best, fixed beam size, fixed batch size

    OMP_NUM_THREADS=1 python -m sockeye.translate \
            -i $data_sub_sub/$corpus.pieces.src \
            -o $translations_sub_sub/$corpus.pieces.trg \
            -m $models_sub_sub \
            --beam-size 10 \
            --length-penalty-alpha 1.0 \
            --device-ids 0 \
            --batch-size 64 \
            --disable-device-locking

    # undo pieces

    cat $translations_sub_sub/$corpus.pieces.trg | sed 's/ //g;s/▁/ /g' > $translations_sub_sub/$corpus.trg

done
