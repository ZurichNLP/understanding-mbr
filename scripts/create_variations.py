#! /usr/bin/python3

import re
import argparse
import logging

from typing import Tuple, List, Iterable


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input-src", type=str, help="Source input file", required=True)
    parser.add_argument("--input-trg", type=str, help="Target input file", required=True)

    parser.add_argument("--output-src", type=str, help="Source output file", required=True)
    parser.add_argument("--output-trg", type=str, help="Target output file", required=True)
    parser.add_argument("--output-variation-counts", type=str, help="Output file to record how many variations per "
                                                                    "input", required=True)

    parser.add_argument("--num-range", type=int, help="Range for number variations", required=True)

    args = parser.parse_args()

    return args


def number_perturbations(source_sentences: Iterable[str],
                         target_sentences: Iterable[str],
                         num_range: int = 10) -> Tuple[List[str], List[str], List[int]]:
    """
    This function is adapted from:
    https://github.com/marziehf/variation-generation/blob/master/src/modific.py#L26

    :param source_sentences:
    :param target_sentences:
    :param num_range:
    :return:
    """
    source_variations = []
    target_variations = []

    variation_counts = []

    for source_sentence, target_sentence in zip(source_sentences, target_sentences):

        source_sentence = source_sentence.strip()
        target_sentence = target_sentence.strip()

        variation_count = 0

        source_nums = [int(i) for i in re.findall(r"\d+", source_sentence)]
        target_nums = [int(i) for i in re.findall(r"\d+", target_sentence)]
        if source_nums != target_nums:
            variation_counts.append(variation_count)
            continue
        for num in source_nums:
            for k in range(-num_range, num_range, 1):
                if num + k > 0 and k != 0:
                    source_perturbed = re.sub(str(num), str(num + k), source_sentence)
                    target_perturbed = re.sub(str(num), str(num + k), target_sentence)
                    source_variations.append(source_perturbed)
                    target_variations.append(target_perturbed)

                    variation_count += 1

        variation_counts.append(variation_count)

    return source_variations, target_variations, variation_counts


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    handle_input_src = open(args.input_src, "r")
    handle_input_trg = open(args.input_trg, "r")

    source_variations, target_variations, variation_counts = number_perturbations(handle_input_src,
                                                                                  handle_input_trg,
                                                                                  num_range=args.num_range)

    with open(args.output_src, "w") as handle_output_src, open(args.output_trg, "w") as handle_output_trg:

        for source_variation, target_variation in zip(source_variations, target_variations):
            handle_output_src.write(source_variation + "\n")
            handle_output_trg.write(target_variation + "\n")

    with open(args.output_variation_counts, "w") as handle_output_variation_counts:
        for count in variation_counts:
            handle_output_variation_counts.write(str(count) + "\n")


if __name__ == "__main__":
    main()
