#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# French -> Latin

src=fra
trg=lat

# dry runs of all steps

dry_run="true"

# baseline

model_name="dry_run"

# delete files for this model to rerun everything

sub_folders="data shared_models prepared models translations samples mbr lengths evaluations"

echo "Could delete the following folders related to $src-$trg/$model_name:"

for sub_folder in $sub_folders; do
  echo "$base/$sub_folder/$src-$trg/$model_name"
done

read -p "Delete? (y/n) " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    for sub_folder in $sub_folders; do
      rm -r $base/$sub_folder/$src-$trg/$model_name
    done
fi


train_additional_args=""
preprocess_copy_noise_probability="0.0"

. $scripts/tatoeba/run_tatoeba_generic.sh
