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

        cp $mbr_sub_sub/$corpus.sample.nbest.$seed.trg $mbr_sub_sub/sample_parts/$corpus.sample.nbest.$seed.trg

        python $scripts/split.py --parts 8 --input $mbr_sub_sub/sample_parts/$corpus.sample.nbest.$seed.trg

        for num_samples in {1..100}; do

            if [[ -s $mbr_sub_sub/$corpus.mbr.sample.$num_samples.$seed.trg.text ]]; then
              echo "Mbr decodes exist: $mbr_sub_sub/$corpus.mbr.sample.$num_samples.$seed.trg.text"

              num_lines_input=$(cat $mbr_sub_sub/$corpus.sample.nbest.$seed.trg | wc -l)
              num_lines_output=$(cat $mbr_sub_sub/$corpus.mbr.sample.$num_samples.$seed.trg.text | wc -l)

              if [[ $num_lines_input == $num_lines_output ]]; then
                  echo "output exists and number of lines are equal to input:"
                  echo "$mbr_sub_sub/$corpus.sample.nbest.$seed.trg == $mbr_sub_sub/$corpus.mbr.sample.$num_samples.$seed.trg.text"
                  echo "$num_lines_input == $num_lines_output"
                  echo "Skipping."
                  continue
              else
                  echo "$mbr_sub_sub/$corpus.sample.nbest.$seed.trg != $mbr_sub_sub/$corpus.mbr.sample.$num_samples.$seed.trg.text"
                  echo "$num_lines_input != $num_lines_output"
                  echo "Repeating step."
              fi
            fi

            # parallel decoding, assuming 8 physical cores

            for part in {1..8}; do

                python $scripts/mbr_decoding.py \
                    --input $mbr_sub_sub/sample_parts/$corpus.sample.nbest.$seed.trg.$part \
                    --output $mbr_sub_sub/sample_parts/$corpus.mbr.sample.$num_samples.$seed.trg.$part \
                    --utility-function sentence-meteor \
                    --num-samples $num_samples &
            done

            wait

            # concatenate parts

            cat $mbr_sub_sub/sample_parts/$corpus.mbr.sample.$num_samples.$seed.trg.{1..8} > \
                $mbr_sub_sub/$corpus.mbr.sample.$num_samples.$seed.trg

            # remove MBR scores, leaving only the text

            cat $mbr_sub_sub/$corpus.mbr.sample.$num_samples.$seed.trg | cut -f2 > \
                $mbr_sub_sub/$corpus.mbr.sample.$num_samples.$seed.trg.text

        done
    done
done
