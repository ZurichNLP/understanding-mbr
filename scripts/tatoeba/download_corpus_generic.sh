#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name
# $wmt_testset_available
# $download_robustness_data

base=$1
src=$2
trg=$3
model_name=$4
wmt_testset_available=$5
download_robustness_data=$6

data=$base/data

mkdir -p $data

source $base/venvs/sockeye3-cpu/bin/activate

data_sub=$data/${src}-${trg}
data_sub_sub=$data_sub/$model_name

if [[ -d $data_sub_sub ]]; then
    echo "data_sub_sub already exists: $data_sub_sub"
    echo "Skipping. Delete files to repeat step."
    exit 0
fi

mkdir -p $data_sub_sub

if [[ $download_robustness_data == "true" ]]; then

    # download data from domain robustness paper, for another OOD experiment

    wget -N https://files.ifi.uzh.ch/cl/archiv/2019/clcontra/opus_robustness_data_v2.tar.xz -P $data_sub_sub

    tar -xvf $data_sub_sub/opus_robustness_data_v2.tar.xz -C $data_sub_sub

    mv $data_sub_sub/opus_robustness_data/* $data_sub_sub/

    rm -r $data_sub_sub/opus_robustness_data

    # copy medical as main train, dev and test

    for corpus in train dev test; do
        cp $data_sub_sub/medical/$corpus.de $data_sub_sub/$corpus.src
        cp $data_sub_sub/medical/$corpus.en $data_sub_sub/$corpus.trg
    done

    # copy remaining domains as additional test corpora

    for domain in it koran law subtitles; do
        cp $data_sub_sub/$domain/test.de $data_sub_sub/$domain.src
        cp $data_sub_sub/$domain/test.en $data_sub_sub/$domain.trg
    done

    # remove unnecessary files

    rm $data_sub_sub/deduplicate.py $data_sub_sub/opus_robustness_data_v2.tar.xz

    for domain in all it medical law koran subtitles; do
        rm -r $data_sub_sub/$domain
    done

else

    # download data from Tatoeba

    wget https://object.pouta.csc.fi/Tatoeba-Challenge/${src}-${trg}.tar -P $data_sub_sub

    # untar entire corpus

    tar -xvf $data_sub_sub/${src}-${trg}.tar -C $data_sub_sub --strip=2

    rm $data_sub_sub/${src}-${trg}.tar

    # unzip train parts

    gunzip $data_sub_sub/train.id.gz

    gunzip $data_sub_sub/train.src.gz
    gunzip $data_sub_sub/train.trg.gz

    rm -f $data_sub_sub/train.id.gz $data_sub_sub/train.src.gz $data_sub_sub/train.trg.gz

fi

if [[ $wmt_testset_available == "true" ]]; then

    # find out if for this langpair there is a WMT testset, prints the src and ref to STDOUT if yes

    python $base/scripts/most_recent_wmt_testset.py --src-lang $src --trg-lang $trg --echo > $data_sub_sub/wmt.both

    cut -f1 $data_sub_sub/wmt.both > $data_sub_sub/wmt.src
    cut -f2 $data_sub_sub/wmt.both > $data_sub_sub/wmt.trg
fi

echo "Sizes of files:"

wc -l $data_sub_sub/*
