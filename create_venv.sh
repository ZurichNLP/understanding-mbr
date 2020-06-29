#! /bin/bash

export TMPDIR="/var/tmp"

mkdir -p venv

# virtualenv -p python3 venv/fairseq3

source venv/fairseq3/bin/activate

#pip install torch==1.5.1+cu101 torchvision==0.6.1+cu101 -f https://download.pytorch.org/whl/torch_stable.html

git clone https://github.com/pytorch/fairseq
(cd fairseq && pip install .)

pip install fastBPE sacremoses subword_nmt sacrebleu
