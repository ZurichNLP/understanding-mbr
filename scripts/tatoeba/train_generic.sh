#!/bin/bash

# calling script needs to set:

# $base
# $src
# $trg
# $model_name
# $additional_args

base=$1
src=$2
trg=$3
model_name=$4
additional_args=$5

data=$base/data
data_sub=$data/${src}-${trg}

prepared=$base/prepared
prepared_sub=$prepared/${src}-${trg}

models=$base/models
models_sub=$models/${src}-${trg}

mkdir -p $models
mkdir -p $models_sub

model_sub_sub=$models_sub/$model_name

mkdir -p $model_sub_sub

echo "additional args: "
echo "$additional_args"

echo $CUDA_VISIBLE_DEVICES
echo "Done reading visible devices."

export MXNET_ENABLE_GPU_P2P=0
echo "MXNET_ENABLE_GPU_P2P: $MXNET_ENABLE_GPU_P2P"

source $base/venvs/sockeye3/bin/activate

# parameters are the same for all Transformer models

num_embed="512:512"
num_layers="6:6"
transformer_model_size="512"
transformer_attention_heads="8"
transformer_feed_forward_num_hidden="2048"

# parameters vary depending on training data size

SMALLEST_TRAINSIZE=10000
SMALL_TRAINSIZE=100000
MEDIUM_TRAINSIZE=500000
LARGE_TRAINSIZE=1000000
LARGEST_TRAINSIZE=10000000

num_lines=$(cat $data_sub/train.clean.src | wc -l)

if [[ $num_lines -gt ${LARGEST_TRAINSIZE} ]]; then
    embed_dropout=0.1
    transformer_dropout=0.1
    batch_size=4096
    decode_and_evaluate=2500
    checkpoint_interval=5000
elif [[ $num_lines -gt ${LARGE_TRAINSIZE} ]]; then
    embed_dropout=0.1
    transformer_dropout=0.1
    batch_size=4096
    decode_and_evaluate=2500
    checkpoint_interval=5000
elif [[ $num_lines -gt ${MEDIUM_TRAINSIZE} ]]; then
    embed_dropout=0.1
    transformer_dropout=0.1
    batch_size=4096
    decode_and_evaluate=2500
    checkpoint_interval=5000
elif [[ $num_lines -gt ${SMALL_TRAINSIZE} ]]; then
    embed_dropout=0.2
    transformer_dropout=0.2
    batch_size=2048
    decode_and_evaluate=1000
    checkpoint_interval=1000
elif [[ $num_lines -gt ${SMALLEST_TRAINSIZE} ]]; then
    embed_dropout=0.5
    transformer_dropout=0.5
    batch_size=1024
    decode_and_evaluate=500
    checkpoint_interval=1000
else
    echo "Warning: training data size too small"
    exit 0
fi

##################################################

python -m sockeye.train \
-d $prepared_sub \
-vs $data_sub/dev.pieces.src \
-vt $data_sub/dev.pieces.trg \
--output $model_sub_sub \
--seed 1 \
--batch-type word \
--batch-size $batch_size \
--device-ids 0 \
--decode-and-evaluate-device-id 0 \
--encoder transformer \
--decoder transformer \
--num-layers $num_layers \
--transformer-model-size $transformer_model_size \
--transformer-attention-heads $transformer_attention_heads \
--transformer-feed-forward-num-hidden $transformer_feed_forward_num_hidden \
--transformer-preprocess n \
--transformer-postprocess dr \
--transformer-dropout-attention $transformer_dropout \
--transformer-dropout-act $transformer_dropout \
--transformer-dropout-prepost $transformer_dropout \
--transformer-positional-embedding-type fixed \
--embed-dropout $embed_dropout:$embed_dropout \
--weight-tying \
--weight-tying-type src_trg_softmax \
--num-embed $num_embed \
--num-words 64000:64000 \
--optimizer adam \
--initial-learning-rate 0.0001 \
--learning-rate-reduce-num-not-improved 4 \
--checkpoint-interval $checkpoint_interval \
--keep-last-params 30 \
--max-seq-len 250:250 \
--learning-rate-reduce-factor 0.7 \
--decode-and-evaluate $decode_and_evaluate \
--max-num-checkpoint-not-improved 10 \
--min-num-epochs 0 \
--gradient-clipping-type abs \
--gradient-clipping-threshold 1 \
--disable-device-locking $additional_args
