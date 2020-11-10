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

#wget https://raw.githubusercontent.com/awslabs/sockeye/master/requirements/requirements.gpu-cu${CUDA_VERSION}.txt
#pip install sockeye --no-deps -r requirements.gpu-cu${CUDA_VERSION}.txt
#rm requirements.gpu-cu${CUDA_VERSION}.txt

# Method B: install from local source, custom repo

git clone https://github.com/bricksdont/sockeye $tools/sockeye

(cd $tools/sockeye && git checkout mbr_experiments )
(cd $tools/sockeye && pip install . --no-deps -r requirements/requirements.gpu-cu${CUDA_VERSION}.txt )

pip install matplotlib mxboard seaborn nltk

# install Moses scripts for preprocessing

git clone https://github.com/bricksdont/moses-scripts $tools/moses-scripts

# install sentencepiece for subword regularization

pip install sentencepiece

################################################

deactivate

source $venvs/sockeye3-cpu/bin/activate

# Method A

#wget https://raw.githubusercontent.com/awslabs/sockeye/master/requirements/requirements.txt
#pip install sockeye --no-deps -r requirements.txt
#rm requirements.txt

# Method B

(cd $tools/sockeye && pip install . --no-deps -r requirements/requirements.txt )

pip install matplotlib mxboard seaborn nltk scipy methodtools requests

# install BPE library and sentencepiece for subword regularization

pip install subword-nmt sentencepiece

# meteor dependencies

python -c "import nltk;nltk.download('wordnet')"

# lang id packages

pip install pycld2 iso-639 pycountry
