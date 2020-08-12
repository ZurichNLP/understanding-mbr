#! /usr/bin/python3

import nltk
import sacrebleu
import argparse
import logging

import numpy as np

from typing import List, Callable, Iterable, Tuple


RISK_SENTENCE_BLEU = "sentence-bleu"
RISK_SENTENCE_METEOR = "sentence-meteor"
RISK_SENTENCE_TER = "sentence-ter"

RISK_FUNCTIONS = [RISK_SENTENCE_BLEU,
                  RISK_SENTENCE_METEOR,
                  RISK_SENTENCE_TER]


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


RISK_LOOKUP = {RISK_SENTENCE_BLEU: compute_bleu,
               RISK_SENTENCE_METEOR: compute_meteor,
               RISK_SENTENCE_TER: compute_ter}


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--inputs", nargs="+", type=str, help="Samples of translations. For N samples per input "
                                                              "sentence, expects N files, sentence-parallel.")
    parser.add_argument("--output", type=str, help="File to write best samples.", required=True)
    parser.add_argument("--risk-function", type=str, help="Risk function to compare average risk of samples",
                        required=True, choices=RISK_FUNCTIONS)

    args = parser.parse_args()

    return args


def get_minimum_risk_sample(samples: Tuple[str], risk_function: Callable) -> Tuple[str, float]:
    """

    :param samples:
    :param risk_function:
    :return:
    """

    average_risks = []

    for sample in samples:

        risks = []

        for pseudo_reference in samples:
            if sample != pseudo_reference:
                risks.append(risk_function(sample, pseudo_reference))

        average_risks.append(np.mean(risks))

        print("risks:")
        print(risks)

    print("average risks:")
    print(average_risks)

    minimum_risk_index = int(np.argmin(average_risks))

    return samples[minimum_risk_index], np.min(average_risks)


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    input_handles = [open(path, "r") for path in args.inputs]
    output_handle = open(args.output, "w")

    risk_function = RISK_LOOKUP[args.risk_function]

    for samples in zip(*input_handles):  # type: Tuple[str]
        output, risk = get_minimum_risk_sample(samples=samples, risk_function=risk_function)

        output = output.strip()

        output_handle.write(str(risk) + " " + output)


if __name__ == "__main__":
    main()
