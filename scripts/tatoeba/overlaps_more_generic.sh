#! /bin/bash

# calling script needs to set

# $base
# $input
# $source
# $reference
# $output_prefix

# overlap with source

for overlap_function in word bleu-2; do

    output=$output_prefix.overlap_with_source_"$overlap_function"

    if [[ -s "$output".npy ]]; then
      continue
    fi

    python $base/scripts/measure_overlaps.py \
        --input $input \
        --compare $source \
        --output $output \
        --overlap-function $overlap_function

done

# overlap with reference

for overlap_function in word bleu-2; do

    output=$output_prefix.overlap_with_reference_"$overlap_function"

    if [[ -s "$output".npy ]]; then
      continue
    fi

    python $base/scripts/measure_overlaps.py \
        --input $input \
        --compare $reference \
        --output $output \
        --overlap-function $overlap_function

done
