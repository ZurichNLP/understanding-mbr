#! /usr/bin/python3

import sacrebleu
import argparse
import logging
import json

import numpy as np

from typing import Callable, Tuple, List
from eval_meteor import MeteorScorer


meteor_scorer = MeteorScorer()


UTILITY_SENTENCE_BLEU = "sentence-bleu"
UTILITY_SENTENCE_METEOR = "sentence-meteor"
UTILITY_SENTENCE_TER = "sentence-ter"

UTILITY_FUNCTIONS = [UTILITY_SENTENCE_BLEU,
                     UTILITY_SENTENCE_METEOR,
                     UTILITY_SENTENCE_TER]


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input", type=str, help="Samples of translations. Expect one JSON per line with nbest list.")
    parser.add_argument("--output", type=str, help="File to write best samples.", required=True)
    parser.add_argument("--utility-function", type=str, help="Utility function to compare average risk of samples",
                        required=True, choices=UTILITY_FUNCTIONS)
    parser.add_argument("--num-samples", type=int, help="How many samples to use for MBR (default: all translations found in --input).",
                        required=False, default=-1)
    parser.add_argument("--sample-start-index", type=int,
                        help="From each nbest list take a slice of --num-samples samples, but start at this index (default: 0).",
                        required=False, default=0)

    args = parser.parse_args()

    return args


def compute_meteor(hyp: str, ref: str) -> float:
    """

    :param hyp:
    :param ref:
    :return:
    """
    return meteor_scorer.score(ref, hyp)


def compute_ter(hyp: str, ref: str) -> float:
    """

    :param hyp:
    :param ref:
    :return:
    """

    return sacrebleu.sentence_ter(hyp, ref).score


def compute_bleu(hyp: str, ref: str) -> float:
    """

    :param hyp:
    :param ref:
    :return:
    """

    return sacrebleu.sentence_bleu(hyp, ref).score


UTILITY_LOOKUP = {UTILITY_SENTENCE_BLEU: compute_bleu,
                  UTILITY_SENTENCE_METEOR: compute_meteor,
                  UTILITY_SENTENCE_TER: compute_ter}


def get_maximum_utility_sample(samples: List[str], utility_function: Callable) -> Tuple[str, float]:
    """

    :param samples: Sampled target translations for one single source input sentence
    :param utility_function: Function to compare one sample to all other samples
    :return:
    """

    average_utilities = []

    for sample in samples:

        utilities = []

        for pseudo_reference in samples:
            utilities.append(utility_function(sample, pseudo_reference))

        if len(utilities) == 0:
            average_utility = 0.0
        else:
            average_utility = np.mean(utilities)

        average_utilities.append(average_utility)

    maximum_utility_index = int(np.argmax(average_utilities))

    return samples[maximum_utility_index], np.max(average_utilities)


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    input_handle = open(args.input, "r")
    output_handle = open(args.output, "w")

    utility_function = UTILITY_LOOKUP[args.utility_function]

    for line in input_handle:
        jobj = json.loads(line)
        samples = jobj["translations"]

        if args.num_samples > -1:
            samples = samples[args.sample_start_index:args.num_samples]
            assert len(samples) >= args.num_samples, "Slicing with --sample-start-index selected fewer translations than --num-samples!"

        # remove samples if they are the empty string or whitespace-only
        samples = [sample for sample in samples if sample.strip() != ""]

        output, utility = get_maximum_utility_sample(samples=samples, utility_function=utility_function)

        output = output.strip()
        output_handle.write("%f\t%s\n" % (utility, output))


if __name__ == "__main__":
    main()
