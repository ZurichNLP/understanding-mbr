#! /bin/bash

# calling script has to set:

# $base
# $src
# $trg

base=$1
src=$2
trg=$3

# measure time

SECONDS=0

source $base/venvs/sockeye3-cpu/bin/activate

data=$base/data
data_sub=$data/${src}-${trg}

prepared=$base/prepared
prepared_sub=$prepared/${src}-${trg}

mkdir -p $prepared_sub

cmd="python -m sockeye.prepare_data -s $data_sub/train.clean.src -t $data_sub/train.clean.trg --shared-vocab -o $prepared_sub"

echo "Executing:"
echo "$cmd"

python -m sockeye.prepare_data \
                        -s $data_sub/train.clean.src \
                        -t $data_sub/train.clean.trg \
			                  --shared-vocab \
                        -o $prepared_sub

echo "time taken:"
echo "$SECONDS seconds"
