#! /usr/bin/python3

import numpy
import argparse
import logging
import sacrebleu

# local dependency

from bleu_weighted_precision import WeightedBLEU


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--compare", type=str, help="Path to sentences to compare to.", required=True)
    parser.add_argument("--input", type=str, help="Path to sentences to analyze.", required=True)

    parser.add_argument("--output", type=str, help="Where to save numpy array of overlaps.", required=True)
    parser.add_argument("--overlap-function", type=str, help="How to compute overlap.", required=True,
                        choices=["word", "bleu-2"])

    args = parser.parse_args()

    return args


class Measurer(object):

    def __init__(self,
                 overlap_function: str) -> None:
        """

        :param overlap_function:
        """

        if overlap_function == "word":
            self.overlap_function = self.measure_overlap_word
        else:
            self.overlap_function = self.measure_overlap_bleu2

            # set weights for ngram precisions

            precision_weights = [0.55, 0.45, 0.0, 0.0]

            args = argparse.Namespace(smooth_method="none", smooth_value=None, force=False,
                                      short=False, lc=False, tokenize=sacrebleu.DEFAULT_TOKENIZER,
                                      precision_weights=precision_weights)

            self.scorer = WeightedBLEU(args)

        self.tokenize = sacrebleu.tokenizers.tokenizer_13a.Tokenizer13a()

    def measure(self,
                input_string: str,
                compare_string: str) -> float:
        """

        :param input_string:
        :param compare_string:
        :return:
        """

        return self.overlap_function(input_string.strip(), compare_string.strip())

    def measure_overlap_bleu2(self,
                              input_string: str,
                              compare_string: str) -> float:
        """

        This method is taken from Lee et al (2019):
        https://openreview.net/pdf?id=SkxJ-309FQ

        :param input_string:
        :param compare_string:
        :return:
        """

        score = self.scorer.sentence_score(input_string, [compare_string]).score

        # sacrebleu score is 100-based, need a fraction

        return score / 100.

    def measure_overlap_word(self,
                             input_string: str,
                             compare_string: str) -> float:
        """

        :param input_string:
        :param compare_string:
        :return:
        """
        input_tokens = self.tokenize(input_string).split(" ")
        compare_tokens = self.tokenize(compare_string).split(" ")

        input_length = len(input_tokens)

        if input_length == 0:
            return 0.0

        intersection = set(input_tokens) & set(compare_tokens)

        return len(intersection) / input_length


def main():
    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    overlaps = []

    m = Measurer(overlap_function=args.overlap_function)

    with open(args.input, "r") as input_handle, open(args.compare) as compare_handle:

        for line_input, line_compare in zip(input_handle, compare_handle):

            overlap = m.measure(line_input, line_compare)
            overlaps.append(overlap)

    overlaps_array = numpy.asarray(overlaps, dtype="float32")

    numpy.save(args.output, overlaps_array)


if __name__ == '__main__':
    main()
