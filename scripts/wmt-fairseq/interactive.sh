#! /bin/bash

cat t | CUDA_VISIBLE_DEVICES=0 fairseq-interactive \
    model/wmt19.de-en.joined-dict.ensemble \
    --path model/wmt19.de-en.joined-dict.ensemble/model1.pt \
    --beam 5 \
    --source-lang de \
    --target-lang en
