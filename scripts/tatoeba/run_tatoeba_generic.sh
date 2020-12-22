#! /bin/bash

# calling process needs to set:
# $base
# $src
# $trg
# $model_name
#
# optional:
# $download_robustness_data
# $train_additional_args
# $preprocess_execute_more_mem
# $preprocess_copy_noise_probability
# $dry_run
# $utility_functions
# $mbr_execute_longer
# $corpora
# $preprocess_create_slice_dev
# $train_dev_corpus
# $preprocess_additional_test_corpora
# $preprocess_langid

module load volta cuda/10.2

scripts=$base/scripts
logs=$base/logs

source $base/venvs/sockeye3-cpu/bin/activate

logs_sub=$logs/${src}-${trg}
logs_sub_sub=$logs_sub/$model_name

SLURM_DEFAULT_FILE_PATTERN="slurm-%j.out"
SLURM_LOG_ARGS="-o $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN -e $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN"

mkdir -p $logs_sub_sub

# if variables are undefined, set to avoid confusion

if [ -z "$dry_run" ]; then
    dry_run="false"
fi

if [ -z "$corpora" ]; then
    corpora="test"
fi

if [ -z "$download_robustness_data" ]; then
    download_robustness_data="false"
fi

if [ -z "$train_additional_args" ]; then
    train_additional_args=""
fi

if [ -z "$train_dev_corpus" ]; then
    train_dev_corpus="dev"
fi

if [ -z "$preprocess_execute_more_mem" ]; then
    preprocess_execute_more_mem="false"
fi

if [ -z "$preprocess_additional_test_corpora" ]; then
    preprocess_additional_test_corpora=""
fi

if [ -z "$preprocess_create_slice_dev" ]; then
    if [[ $train_dev_corpus == "slice-dev" ]]; then
        preprocess_create_slice_dev="true"
    else
        preprocess_create_slice_dev="false"
    fi
fi

if [ -z "$preprocess_langid" ]; then
    preprocess_langid="true"
fi

if [ -z "$utility_functions" ]; then
    utility_functions="sentence-chrf-balanced"
fi

if [ -z "$preprocess_copy_noise_probability" ]; then
    preprocess_copy_noise_probability="0.0"
fi

if [ -z "$mbr_execute_longer" ]; then
    mbr_execute_longer="false"
fi

# SLURM job args

DRY_RUN_SLURM_ARGS="--cpus-per-task=2 --time=02:00:00 --mem=16G --partition=generic"

SLURM_ARGS_GENERIC="--cpus-per-task=2 --time=24:00:00 --mem=16G --partition=generic"
SLURM_ARGS_GENERIC_MEM="--cpus-per-task=2 --time=24:00:00 --mem=32G --partition=generic"
SLURM_ARGS_GENERIC_LARGE="--cpus-per-task=32 --time=24:00:00 --mem=32G --partition=generic"
SLURM_ARGS_GENERIC_LARGE_LONG="--cpus-per-task=32 --time=96:00:00 --mem=32G --partition=generic"
SLURM_ARGS_HPC="--cpus-per-task=32 --time=72:00:00 --mem=32G --partition=hpc"
SLURM_ARGS_VOLTA_TRAIN="--qos=vesta --time=72:00:00 --gres gpu:Tesla-V100-32GB:1 --cpus-per-task 1 --mem 16g"
SLURM_ARGS_VOLTA_TRANSLATE="--qos=vesta --time=12:00:00 --gres gpu:Tesla-V100-32GB:1 --cpus-per-task 1 --mem 16g"

if [[ $preprocess_execute_more_mem == "true" ]]; then
  SLURM_ARGS_PREPROCESS=$SLURM_ARGS_GENERIC_MEM
else
  SLURM_ARGS_PREPROCESS=$SLURM_ARGS_GENERIC
fi

if [[ $mbr_execute_longer == "true" ]]; then
  SLURM_ARGS_MBR=$SLURM_ARGS_GENERIC_LARGE_LONG
else
  SLURM_ARGS_MBR=$SLURM_ARGS_GENERIC_LARGE
fi

# if dry run, then all args use generic instances

if [[ $dry_run == "true" ]]; then
  SLURM_ARGS_GENERIC=$DRY_RUN_SLURM_ARGS
  SLURM_ARGS_HPC=$DRY_RUN_SLURM_ARGS
  SLURM_ARGS_VOLTA_TRAIN=$DRY_RUN_SLURM_ARGS
  SLURM_ARGS_VOLTA_TRANSLATE=$DRY_RUN_SLURM_ARGS
  SLURM_ARGS_MBR=$DRY_RUN_SLURM_ARGS
fi

# find out if a WMT testset would be available (does not mean that it is used). Returns "true" if available, "false" if not)

wmt_testset_available=$(python3 $base/scripts/most_recent_wmt_testset.py --src-lang $src --trg-lang $trg --quiet)

if [[ $wmt_testset_available == "false" ]]; then
    if [[ $corpora == *"wmt"* ]]; then
        echo "Requested corpora include 'wmt', but no WMT testset available for this language pair."
        exit 1
    fi
fi

# log key info

echo "##############################################" | tee -a $logs_sub_sub/MAIN
date | tee -a $logs_sub_sub/MAIN
echo "##############################################" | tee -a $logs_sub_sub/MAIN
echo "LANGPAIR: ${src}-${trg}" | tee -a $logs_sub_sub/MAIN
echo "MODEL NAME: $model_name" | tee -a $logs_sub_sub/MAIN
echo "WMT TESTSET AVAILABLE: $wmt_testset_available" | tee -a $logs_sub_sub/MAIN
echo "TEST CORPORA: $corpora" | tee -a $logs_sub_sub/MAIN
echo "DOWNLOAD ROBUSTNESS DATA: $download_robustness_data" | tee -a $logs_sub_sub/MAIN
echo "PREPROCESS EXECUTE MORE MEM: $preprocess_execute_more_mem" | tee -a $logs_sub_sub/MAIN
echo "PREPROCESS CREATE DEV SLICE: $preprocess_create_slice_dev" | tee -a $logs_sub_sub/MAIN
echo "PREPROCESS LANGID: $preprocess_langid" | tee -a $logs_sub_sub/MAIN
echo "PREPROCESS COPY NOISE PROB: $preprocess_copy_noise_probability" | tee -a $logs_sub_sub/MAIN
echo "TRAIN DEV CORPUS: $train_dev_corpus" | tee -a $logs_sub_sub/MAIN
echo "ADDITIONAL TRAIN ARGS: $train_additional_args" | tee -a $logs_sub_sub/MAIN
echo "MBR EXECUTE LONGER: $mbr_execute_longer" | tee -a $logs_sub_sub/MAIN
echo "UTILITY FUNCTIONS: $utility_functions" | tee -a $logs_sub_sub/MAIN
echo "DRY RUN: $dry_run" | tee -a $logs_sub_sub/MAIN

# download corpus for language pair

id_download=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/download_corpus_generic.sh \
    $base $src $trg $model_name $wmt_testset_available $download_robustness_data
)

echo "  id_download: $id_download | $logs_sub_sub/slurm-$id_download.out" | tee -a $logs_sub_sub/MAIN

# preprocess: Hold out data, normalize, SPM, maybe insert copy noise (depends on download)

id_preprocess=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_PREPROCESS \
    --dependency=afterok:$id_download \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/preprocess_generic.sh \
    $base $src $trg $model_name $preprocess_copy_noise_probability \
    $dry_run $wmt_testset_available $preprocess_create_slice_dev \
    "$preprocess_additional_test_corpora" $preprocess_langid
)

echo "  id_preprocess: $id_preprocess | $logs_sub_sub/slurm-$id_preprocess.out" | tee -a $logs_sub_sub/MAIN

# Sockeye prepare (depends on preprocess)

id_prepare=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    --dependency=afterok:$id_preprocess \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/prepare_generic.sh \
    $base $src $trg $model_name
)

echo "  id_prepare: $id_prepare | $logs_sub_sub/slurm-$id_prepare.out"  | tee -a $logs_sub_sub/MAIN

# Sockeye train (depends on prepare)

id_train=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_VOLTA_TRAIN \
    --dependency=afterok:$id_prepare \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/train_generic.sh \
    $base $src $trg $model_name "$train_additional_args" $dry_run $train_dev_corpus
)

echo "  id_train: $id_train | $logs_sub_sub/slurm-$id_train.out"  | tee -a $logs_sub_sub/MAIN

# translate + sample test set (depends on train)

id_translate=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_VOLTA_TRANSLATE \
    --dependency=afterany:$id_train \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/translate_generic.sh \
    $base $src $trg $model_name $dry_run "$corpora"
)

echo "  id_translate: $id_translate | $logs_sub_sub/slurm-$id_translate.out"  | tee -a $logs_sub_sub/MAIN

# MBR decode (depends on sampling)

id_mbr=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_MBR \
    --dependency=afterok:$id_translate \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/mbr_generic.sh \
    $base $src $trg $model_name $dry_run "$utility_functions" "$corpora"
)

echo "  id_mbr: $id_mbr | $logs_sub_sub/slurm-$id_mbr.out"  | tee -a $logs_sub_sub/MAIN

# evaluate BLEU and other metrics (depends on mbr)

id_evaluate=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    --dependency=afterok:$id_mbr \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/evaluate_generic.sh \
    $base $src $trg $model_name "$utility_functions" "$corpora"
)

echo "  id_evaluate: $id_evaluate | $logs_sub_sub/slurm-$id_evaluate.out"  | tee -a $logs_sub_sub/MAIN

# compute lengths (depends on evaluate)

id_lengths=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    --dependency=afterok:$id_evaluate \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/lengths_generic.sh \
    $base $src $trg $model_name "$utility_functions" "$corpora"
)

echo "  id_lengths: $id_lengths | $logs_sub_sub/slurm-$id_lengths.out"  | tee -a $logs_sub_sub/MAIN

# compute counts (depends on lengths)

id_counts=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    --dependency=afterok:$id_lengths \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/counts_generic.sh \
    $base $src $trg $model_name "$utility_functions" "$corpora"
)

echo "  id_counts: $id_counts | $logs_sub_sub/slurm-$id_counts.out"  | tee -a $logs_sub_sub/MAIN

# compute overlaps (depends on lengths, no interaction with counts)

id_overlaps=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    --dependency=afterok:$id_lengths \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/overlaps_generic.sh \
    $base $src $trg $model_name "$utility_functions" "$corpora"
)

echo "  id_overlaps: $id_overlaps | $logs_sub_sub/slurm-$id_overlaps.out"  | tee -a $logs_sub_sub/MAIN

# extract from overlaps (depends on overlaps)

id_extract=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    --dependency=afterok:$id_overlaps \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/extract_generic.sh \
    $base $src $trg $model_name "$utility_functions" "$corpora"
)

echo "  id_extract: $id_extract | $logs_sub_sub/slurm-$id_extract.out"  | tee -a $logs_sub_sub/MAIN
