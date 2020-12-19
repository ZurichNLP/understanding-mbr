#! /usr/bin/python3

import numpy as np
import argparse
import logging

from typing import List


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--source", type=str, help="Path to tokenized source sentences.", required=True)
    parser.add_argument("--target", type=str, help="Path to tokenized target sentences.", required=True)

    args = parser.parse_args()

    return args


def measure_overlap(source_tokens: List[str], target_tokens: List[str]) -> float:
    """

    :param source_tokens:
    :param target_tokens:
    :return:
    """

    target_length = len(target_tokens)

    intersection = set(source_tokens) & set(target_tokens)

    return len(intersection) / target_length


def main():
    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    overlaps = []

    with open(args.source, "r") as source_handle, open(args.target) as target_handle:

        for line_source, line_target in zip(source_handle, target_handle):

            source_tokens = line_source.strip().split(" ")
            target_tokens = line_target.strip().split(" ")

            overlap = measure_overlap(source_tokens, target_tokens)
            overlaps.append(overlap)

    average_overlap = np.mean(overlaps)

    print(average_overlap)


if __name__ == '__main__':
    main()
