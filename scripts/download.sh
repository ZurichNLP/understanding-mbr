#! /bin/bash

mkdir -p model
curl https://dl.fbaipublicfiles.com/fairseq/models/wmt19.de-en.joined-dict.ensemble.tar.gz | tar xzvf - -C model

mkdir -p data
wget https://raw.githubusercontent.com/google/wmt19-paraphrased-references/master/wmt19/ende/wmt19-ende-wmtp.ref
mv wmt19-ende-wmtp.ref data/

sacrebleu -t wmt19 -l de-en --echo ref > data/wmt19-en-de.trg
