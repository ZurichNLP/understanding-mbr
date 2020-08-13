#! /usr/bin/python3

import nltk
import sacrebleu
import argparse
import logging

import random
import numpy as np

from typing import Callable, Tuple


UTILITY_SENTENCE_BLEU = "sentence-bleu"
UTILITY_SENTENCE_METEOR = "sentence-meteor"
UTILITY_SENTENCE_TER = "sentence-ter"

UTILITY_FUNCTIONS = [UTILITY_SENTENCE_BLEU,
                     UTILITY_SENTENCE_METEOR,
                     UTILITY_SENTENCE_TER]


def compute_meteor(hyp: str, ref: str) -> float:
    """

    :param hyp:
    :param ref:
    :return:
    """
    return nltk.translate.meteor_score.single_meteor_score(ref, hyp)


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


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--inputs", nargs="+", type=str, help="Samples of translations. For N samples per input "
                                                              "sentence, expects N files, sentence-parallel.")
    parser.add_argument("--output", type=str, help="File to write best samples.", required=True)
    parser.add_argument("--utility-function", type=str, help="Utility function to compare average risk of samples",
                        required=True, choices=UTILITY_FUNCTIONS)

    args = parser.parse_args()

    return args


def get_maximum_utility_sample(samples: Tuple[str], utility_function: Callable) -> Tuple[str, float]:
    """

    :param samples: Sampled target translations for one single source input sentence
    :param utility_function: Function to compare one sample to all other samples
    :return:
    """

    average_utilities = []

    for sample in samples:

        utilities = []

        for pseudo_reference in samples:
            if sample != pseudo_reference:
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

    input_handles = [open(path, "r") for path in args.inputs]
    output_handle = open(args.output, "w")

    utility_function = UTILITY_LOOKUP[args.utility_function]

    for samples in zip(*input_handles):  # type: Tuple[str]
        output, utility = get_maximum_utility_sample(samples=samples, utility_function=utility_function)

        output = output.strip()

        output_handle.write("%f\t%s\n" % (utility, output))


if __name__ == "__main__":
    main()
