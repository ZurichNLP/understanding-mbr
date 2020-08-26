#! /usr/bin/python3

import sacrebleu
import argparse
import logging

import numpy as np

from typing import Callable, Tuple
from eval_meteor import MeteorScorer
from multiprocessing import Pool


UTILITY_SENTENCE_BLEU = "sentence-bleu"
UTILITY_SENTENCE_METEOR = "sentence-meteor"
UTILITY_SENTENCE_TER = "sentence-ter"

UTILITY_FUNCTIONS = [UTILITY_SENTENCE_BLEU,
                     UTILITY_SENTENCE_METEOR,
                     UTILITY_SENTENCE_TER]


class MBRDecoder(object):

    def __init__(self, utility_function: str):
        """

        :param utility_function: Function to compare one sample to all other samples
        """

        if utility_function == UTILITY_SENTENCE_BLEU:
            self.utility_function = MBRDecoder.compute_bleu  # type: Callable
        elif utility_function == UTILITY_SENTENCE_METEOR:
            self.utility_function = self.compute_meteor
            self.meteor_scorer = MeteorScorer()
        else:
            self.utility_function = MBRDecoder.compute_ter

    def compute_meteor(self, hyp: str, ref: str) -> float:
        """

        :param hyp:
        :param ref:
        :return:
        """
        return self.meteor_scorer.score(ref, hyp)

    @staticmethod
    def compute_ter(hyp: str, ref: str) -> float:
        """

        :param hyp:
        :param ref:
        :return:
        """

        return sacrebleu.sentence_ter(hyp, ref).score

    @staticmethod
    def compute_bleu(hyp: str, ref: str) -> float:
        """

        :param hyp:
        :param ref:
        :return:
        """

        return sacrebleu.sentence_bleu(hyp, ref).score

    def get_maximum_utility_sample(self, samples: Tuple[str]) -> Tuple[str, float]:
        """

        :param samples: Sampled target translations for one single source input sentence
        :return:
        """

        average_utilities = []

        for sample in samples:

            utilities = []

            for pseudo_reference in samples:
                if sample != pseudo_reference:
                    utilities.append(self.utility_function(sample, pseudo_reference))

            if len(utilities) == 0:
                average_utility = 0.0
            else:
                average_utility = np.mean(utilities)

            average_utilities.append(average_utility)

        maximum_utility_index = int(np.argmax(average_utilities))

        return samples[maximum_utility_index], np.max(average_utilities)


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--inputs", nargs="+", type=str, help="Samples of translations. For N samples per input "
                                                              "sentence, expects N files, sentence-parallel.")
    parser.add_argument("--output", type=str, help="File to write best samples.", required=True)
    parser.add_argument("--utility-function", type=str, help="Utility function to compare average risk of samples",
                        required=True, choices=UTILITY_FUNCTIONS)
    parser.add_argument("--num-workers", type=int, help="How many processes to start for multiprocessing.",
                        required=False, default=1)

    args = parser.parse_args()

    return args


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    input_handles = [open(path, "r") for path in args.inputs]
    output_handle = open(args.output, "w")

    pool = Pool(processes=args.num_workers)

    for output, utility in pool.imap(MBRDecoder(utility_function=args.utility_function).get_maximum_utility_sample, zip(*input_handles)):

        output = output.strip()
        output_handle.write("%f\t%s\n" % (utility, output))


if __name__ == "__main__":
    main()
