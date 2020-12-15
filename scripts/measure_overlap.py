#! /usr/bin/python3

import numpy as np
import argparse
import logging

from typing import List


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--source", type=str, help="Path to tokenized source sentences.", required=True)
    parser.add_argument("--hypothesis", type=str, help="Path to translations by system, tokenized.", required=True)

    args = parser.parse_args()

    return args


def measure_overlap(source_tokens: List[str], hyp_tokens: List[str]) -> float:
    """

    :param source_tokens:
    :param hyp_tokens:
    :return:
    """

    hyp_length = len(hyp_tokens)

    intersection = set(source_tokens) & set(hyp_tokens)

    return len(intersection) / hyp_length


def main():
    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    overlaps = []

    with open(args.source, "r") as source_handle, open(args.hypothesis) as hyp_handle:

        for line_source, line_hyp in zip(source_handle, hyp_handle):

            source_tokens = line_source.strip().split(" ")
            hyp_tokens = line_hyp.strip().split(" ")

            overlap = measure_overlap(source_tokens, hyp_tokens)
            overlaps.append(overlap)

    average_overlap = np.mean(overlaps)

    print(average_overlap)


if __name__ == '__main__':
    main()
