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
    utility_functions="sentence-chrf-1"
fi

if [ -z "$preprocess_copy_noise_probability" ]; then
    preprocess_copy_noise_probability="0.0"
fi

if [ -z "$mbr_execute_longer" ]; then
    mbr_execute_longer="false"
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

id_download=$(python  -c 'import uuid; print(uuid.uuid4().hex)')

$scripts/tatoeba/download_corpus_generic.sh \
    $base $src $trg $model_name $wmt_testset_available $download_robustness_data \
    > $logs_sub_sub/slurm-$id_download.out 2> $logs_sub_sub/slurm-$id_download.out

echo "  id_download: $id_download | $logs_sub_sub/slurm-$id_download.out" | tee -a $logs_sub_sub/MAIN

# preprocess: Hold out data, normalize, SPM, maybe insert copy noise (depends on download)

id_preprocess=$(python  -c 'import uuid; print(uuid.uuid4().hex)')

$scripts/tatoeba/preprocess_generic.sh \
    $base $src $trg $model_name $preprocess_copy_noise_probability \
    $dry_run $wmt_testset_available $preprocess_create_slice_dev \
    "$preprocess_additional_test_corpora" $preprocess_langid \
    > $logs_sub_sub/slurm-$id_preprocess.out 2> $logs_sub_sub/slurm-$id_preprocess.out

echo "  id_preprocess: $id_preprocess | $logs_sub_sub/slurm-$id_preprocess.out" | tee -a $logs_sub_sub/MAIN

# Sockeye prepare (depends on preprocess)

id_prepare=$(python  -c 'import uuid; print(uuid.uuid4().hex)')

$scripts/tatoeba/prepare_generic.sh \
    $base $src $trg $model_name \
    > $logs_sub_sub/slurm-$id_prepare.out 2> $logs_sub_sub/slurm-$id_prepare.out

echo "  id_prepare: $id_prepare | $logs_sub_sub/slurm-$id_prepare.out"  | tee -a $logs_sub_sub/MAIN

# Sockeye train (depends on prepare)

id_train=$(python  -c 'import uuid; print(uuid.uuid4().hex)')

$scripts/tatoeba/train_generic.sh \
    $base $src $trg $model_name "$train_additional_args" $dry_run $train_dev_corpus \
    > $logs_sub_sub/slurm-$id_train.out 2> $logs_sub_sub/slurm-$id_train.out

echo "  id_train: $id_train | $logs_sub_sub/slurm-$id_train.out"  | tee -a $logs_sub_sub/MAIN

# translate + sample test set (depends on train)

id_translate=$(python  -c 'import uuid; print(uuid.uuid4().hex)')

$scripts/tatoeba/translate_generic.sh \
    $base $src $trg $model_name $dry_run "$corpora" \
    > $logs_sub_sub/slurm-$id_translate.out 2> $logs_sub_sub/slurm-$id_translate.out

echo "  id_translate: $id_translate | $logs_sub_sub/slurm-$id_translate.out"  | tee -a $logs_sub_sub/MAIN

# MBR decode (depends on sampling)

id_mbr=$(python  -c 'import uuid; print(uuid.uuid4().hex)')

$scripts/tatoeba/mbr_generic.sh \
    $base $src $trg $model_name $dry_run "$utility_functions" "$corpora" \
    > $logs_sub_sub/slurm-$id_mbr.out 2> $logs_sub_sub/slurm-$id_mbr.out

echo "  id_mbr: $id_mbr | $logs_sub_sub/slurm-$id_mbr.out"  | tee -a $logs_sub_sub/MAIN

# evaluate BLEU and other metrics (depends on mbr)

id_evaluate=$(python  -c 'import uuid; print(uuid.uuid4().hex)')

$scripts/tatoeba/evaluate_generic.sh \
    $base $src $trg $model_name "$utility_functions" "$corpora" \
    > $logs_sub_sub/slurm-$id_evaluate.out 2> $logs_sub_sub/slurm-$id_evaluate.out

echo "  id_evaluate: $id_evaluate | $logs_sub_sub/slurm-$id_evaluate.out"  | tee -a $logs_sub_sub/MAIN

# compute lengths (depends on evaluate)

id_lengths=$(python  -c 'import uuid; print(uuid.uuid4().hex)')

$scripts/tatoeba/lengths_generic.sh \
    $base $src $trg $model_name "$utility_functions" "$corpora" \
    > $logs_sub_sub/slurm-$id_lengths.out 2> $logs_sub_sub/slurm-$id_lengths.out

echo "  id_lengths: $id_lengths | $logs_sub_sub/slurm-$id_lengths.out"  | tee -a $logs_sub_sub/MAIN

# compute counts (depends on lengths)

id_counts=$(python  -c 'import uuid; print(uuid.uuid4().hex)')

$scripts/tatoeba/counts_generic.sh \
    $base $src $trg $model_name "$utility_functions" "$corpora" \
    > $logs_sub_sub/slurm-$id_counts.out 2> $logs_sub_sub/slurm-$id_counts.out

echo "  id_counts: $id_counts | $logs_sub_sub/slurm-$id_counts.out"  | tee -a $logs_sub_sub/MAIN

# compute overlaps (depends on lengths, no interaction with counts)

id_overlaps=$(python  -c 'import uuid; print(uuid.uuid4().hex)')

$scripts/tatoeba/overlaps_generic.sh \
    $base $src $trg $model_name "$utility_functions" "$corpora" \
    > $logs_sub_sub/slurm-$id_overlaps.out 2> $logs_sub_sub/slurm-$id_overlaps.out

echo "  id_overlaps: $id_overlaps | $logs_sub_sub/slurm-$id_overlaps.out"  | tee -a $logs_sub_sub/MAIN

# extract from overlaps (depends on overlaps)

id_extract=$(python  -c 'import uuid; print(uuid.uuid4().hex)')

$scripts/tatoeba/extract_generic.sh \
    $base $src $trg $model_name "$utility_functions" "$corpora" \
    > $logs_sub_sub/slurm-$id_extract.out 2> $logs_sub_sub/slurm-$id_extract.out

echo "  id_extract: $id_extract | $logs_sub_sub/slurm-$id_extract.out"  | tee -a $logs_sub_sub/MAIN
