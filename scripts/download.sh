#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

data=$base/data
models=$base/models

mkdir -p $data
mkdir -p $models

models_sub=$models/fairseq-wmt19-de-en

mkdir -p $models_sub

curl https://dl.fbaipublicfiles.com/fairseq/models/wmt19.de-en.joined-dict.ensemble.tar.gz | tar xzvf - -C $models_sub

wget https://raw.githubusercontent.com/google/wmt19-paraphrased-references/master/wmt19/ende/wmt19-ende-wmtp.ref
mv wmt19-ende-wmtp.ref $data/

sacrebleu -t wmt19 -l de-en --echo ref > $data/wmt19-en-de.trg

echo "Bei einem Unfall eines Reisebusses mit 2 Senioren als Fahrgästen sind am Donnerstag in Krummhörn (Landkreis Aurich) acht Menschen verletzt worden." > $data/toy_input