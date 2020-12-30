#! /bin/bash

base=/net/cephfs/scratch/mathmu/map-volatility
scripts=$base/scripts

# German -> English, data from domain robustness paper / experiments

src=deu
trg=eng

# dry runs of all steps

dry_run="true"

# baseline

model_name="dry_run"

download_robustness_data="true"

corpora="test slice-test it law koran subtitles"
preprocess_additional_test_corpora="it law koran subtitles"

# delete files for this model to rerun everything

sub_folders="data shared_models prepared models translations samples mbr lengths evaluations counts overlaps extracts"

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
