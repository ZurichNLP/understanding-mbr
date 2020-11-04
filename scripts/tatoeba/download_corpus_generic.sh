#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name
# $wmt_testset_available

base=$1
src=$2
trg=$3
model_name=$4
wmt_testset_available=$5

data=$base/data

mkdir -p $data

data_sub=$data/${src}-${trg}
data_sub_sub=$data_sub/$model_name

if [[ -d $data_sub_sub ]]; then
    echo "data_sub_sub already exists: $data_sub_sub"
    echo "Skipping. Delete files to repeat step."
    exit 0
fi

mkdir -p $data_sub_sub

wget https://object.pouta.csc.fi/Tatoeba-Challenge/${src}-${trg}.tar -P $data_sub_sub

# untar entire corpus

tar -xvf $data_sub_sub/${src}-${trg}.tar -C $data_sub_sub --strip=2

rm $data_sub_sub/${src}-${trg}.tar

# unzip train parts

gunzip $data_sub_sub/train.id.gz

gunzip $data_sub_sub/train.src.gz
gunzip $data_sub_sub/train.trg.gz

rm -f $data_sub_sub/train.id.gz $data_sub_sub/train.src.gz $data_sub_sub/train.trg.gz

if [[ $wmt_testset_available == "true" ]]; then

    # find out if for this langpair there is a WMT testset, prints the src and ref to STDOUT if yes

    python $base/scripts/most_recent_wmt_testset.py --src-lang $src --trg-lang $trg --echo > $data_sub_sub/wmt.both

    cut -f1 $data_sub_sub/wmt.both > $data_sub_sub/wmt.src
    cut -f2 $data_sub_sub/wmt.both > $data_sub_sub/wmt.trg
fi

echo "Sizes of files:"

wc -l $data_sub_sub/*
