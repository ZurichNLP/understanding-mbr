#! /usr/bin/python3

import sys
import pickle
import argparse
import logging

from collections import Counter


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--output", type=str, help="Where to save pickle of token counter.", required=True)

    args = parser.parse_args()

    return args


def main():
    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    counter = Counter()

    for line in sys.stdin:
        tokens = line.strip().split(" ")
        counter.update(tokens)

    with open(args.output, "wb") as outfile:
        pickle.dump(counter, outfile)

if __name__ == '__main__':
    main()
