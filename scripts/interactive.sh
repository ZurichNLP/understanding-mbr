#! /bin/bash

CUDA_VISIBLE_DEVICES=0 cat t | fairseq-interactive \
    model/wmt19.de-en.joined-dict.ensemble \
    --path model/wmt19.de-en.joined-dict.ensemble/model1.pt \
    --beam 5 \
    --source-lang de \
    --target-lang en \
    --distributed-no-spawn \
    --ddp-backend no_c10d \
    --distributed-world-size 1
