#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

venvs=$base/venvs
tools=$base/tools

export TMPDIR="/var/tmp"

mkdir -p $tools

source $venvs/sockeye3/bin/activate

# install METEOR

mkdir -p $tools/meteor

wget wget http://www.cs.cmu.edu/~alavie/METEOR/download/meteor-1.5.tar.gz -P $tools/meteor

tar -xzvf $tools/meteor/meteor-1.5.tar.gz -C $tools/meteor --strip=1

# install Sockeye 2

# CUDA version on instance
CUDA_VERSION=102

## Method A: install from PyPi

wget https://raw.githubusercontent.com/awslabs/sockeye/master/requirements/requirements.gpu-cu${CUDA_VERSION}.txt
pip install sockeye --no-deps -r requirements.gpu-cu${CUDA_VERSION}.txt
rm requirements.gpu-cu${CUDA_VERSION}.txt

pip install matplotlib mxboard

pip install mxnet-cu102mkl==1.6.0.post0

pip install nltk

# install Moses scripts for preprocessing

git clone https://github.com/bricksdont/moses-scripts $tools/moses-scripts

# install sentencepiece for subword regularization

pip install sentencepiece

################################################

deactivate

source $venvs/sockeye3-cpu/bin/activate

wget https://raw.githubusercontent.com/awslabs/sockeye/master/requirements/requirements.txt
pip install sockeye --no-deps -r requirements.txt
rm requirements.txt

pip install matplotlib mxboard

# install BPE library

pip install subword-nmt

# install sacrebleu for evaluation

git clone https://github.com/ales-t/sacrebleu $tools/sacrebleu

(cd $tools/sacrebleu && git checkout add-ter && git pull)

(cd $tools/sacrebleu && pip install --upgrade .)

pip install nltk

# meteor dependencies

python -c "import nltk;nltk.download('wordnet')"

# install sentencepiece for subword regularization

pip install sentencepiece

# lang id packages

pip install pycld2 iso-639

pip install requests

