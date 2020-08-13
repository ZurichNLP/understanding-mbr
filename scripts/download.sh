#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

venvs=$base/venvs
data=$base/data
models=$base/models
tools=$base/tools

export TMPDIR="/var/tmp"

source $venvs/fairseq3/bin/activate

mkdir -p $data
mkdir -p $models
mkdir -p $tools

# fairseq WMT19 model

models_sub=$models/fairseq-wmt19-de-en

mkdir -p $models_sub

curl https://dl.fbaipublicfiles.com/fairseq/models/wmt19.de-en.joined-dict.ensemble.tar.gz | tar xzvf - -C $models_sub

# WMT19 test set + additional paraphrased references

wget https://raw.githubusercontent.com/google/wmt19-paraphrased-references/master/wmt19/ende/wmt19-ende-wmtp.ref
mv wmt19-ende-wmtp.ref $data/

sacrebleu -t wmt19 -l de-en --echo ref > $data/wmt19-en-de.trg

# dummy data to test sampling and MBR

echo "Bei einem Unfall eines Reisebusses mit 2 Senioren als Fahrgästen sind am Donnerstag in Krummhörn (Landkreis Aurich) acht Menschen verletzt worden." > $data/toy_input

echo "On Thursday, an accident involving a coach carrying 43 elderly people in Krummhörn (district of Aurich) led to eight people being injured." > $data/toy_reference

# variation-generation

git clone https://github.com/bricksdont/variation-generation $tools/variation-generation

# fairseq

pip install torch==1.5.1+cu101 torchvision==0.6.1+cu101 -f https://download.pytorch.org/whl/torch_stable.html

git clone https://github.com/pytorch/fairseq $tools/fairseq
(cd $tools/fairseq && pip install .)

pip install fastBPE sacremoses subword_nmt nltk

# TODO: install some nltk module?

# different version of sacrebleu that supports TER already

git clone https://github.com/ales-t/sacrebleu $tools/sacrebleu

(cd $tools/sacrebleu && git checkout add-ter)

(cd $tools/sacrebleu && pip install --upgrade .)

# variation-generation

git clone https://github.com/bricksdont/variation-generation $tools/variation-generation

