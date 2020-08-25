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

data=$base/data

mkdir -p $data

data_sub=$data/${src}-${trg}
data_sub_sub=$data_sub/$model_name

if [[ -d $data_sub_sub ]]; then
    echo "data_sub_sub already exists: $data_sub_sub"
    echo "Skipping. Delete files to repeat step."
else

    mkdir -p $data_sub_sub

    wget https://object.pouta.csc.fi/Tatoeba-Challenge/${src}-${trg}.tar

    # untar entire corpus

    tar -xvf ${src}-${trg}.tar -C $data_sub_sub --strip=2

    rm ${src}-${trg}.tar

    # unzip train parts

    gunzip $data_sub_sub/train.id.gz

    gunzip $data_sub_sub/train.src.gz
    gunzip $data_sub_sub/train.trg.gz

    rm -f $data_sub_sub/train.id.gz $data_sub_sub/train.src.gz $data_sub_sub/train.trg.gz

fi

echo "Sizes of files:"

wc -l $data_sub_sub/*
