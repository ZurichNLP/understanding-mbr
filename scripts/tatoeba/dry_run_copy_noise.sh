#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# Danish -> Esperanto

src=dan
trg=epo

# with copies in the training data + no label smoothing

train_additional_args="--label-smoothing 0.0"

noise_probabilities="0.1 0.3"

dry_run="true"

for preprocess_copy_noise_probability in $noise_probabilities; do

    model_name="dry_run_copy_noise.$preprocess_copy_noise_probability"

    # delete files for this model to rerun everything

    sub_folders="data shared_models prepared models translations samples mbr lengths evaluations counts"

    echo "Could delete the following folders related to $src-$trg/$model_name:"

    for sub_folder in $sub_folders; do
      echo "$base/$sub_folder/$src-$trg/$model_name"
    done

    read -p "Delete? (y/n) " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for sub_folder in $sub_folders; do
          rm -rf $base/$sub_folder/$src-$trg/$model_name
        done
    fi

    . $scripts/tatoeba/run_tatoeba_generic.sh

done
