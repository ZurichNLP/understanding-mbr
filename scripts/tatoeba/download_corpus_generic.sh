#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg

base=$1
src=$2
trg=$3

data=$base/data

mkdir -p $data

data_sub=$data/${src}-${trg}

mkdir -p $data_sub

wget https://object.pouta.csc.fi/Tatoeba-Challenge/${src}-${trg}.tar

# untar entire corpus

tar -xvf ${src}-${trg}.tar -C $data_sub --strip=2

rm ${src}-${trg}.tar

# unzip train parts

gunzip $data_sub/train.id.gz

gunzip $data_sub/train.src.gz
gunzip $data_sub/train.trg.gz

rm -f $data_sub/train.id.gz $data_sub/train.src.gz $data_sub/train.trg.gz

echo "Sizes of files:"

wc -l $data_sub/*
