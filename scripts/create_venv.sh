#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

tools=$base/tools
venvs=$base/venvs

mkdir -p $tools
mkdir -p $venvs

export TMPDIR="/var/tmp"

mkdir -p $venvs

virtualenv -p python3 $venvs/fairseq3

source $venvs/fairseq3/bin/activate

pip install torch==1.5.1+cu101 torchvision==0.6.1+cu101 -f https://download.pytorch.org/whl/torch_stable.html

git clone https://github.com/pytorch/fairseq $tools/fairseq
(cd $tools/fairseq && pip install .)

pip install fastBPE sacremoses subword_nmt nltk

# different version of sacrebleu that supports TER already

git clone https://github.com/ales-t/sacrebleu $tools/sacrebleu

(cd $tools/sacrebleu && git checkout add-ter)

(cd $tools/sacrebleu && pip install --upgrade .)
