#! /usr/bin/python3

import sys
import numpy
import argparse
import logging


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--output", type=str, help="Where to save numpy array of lengths.", required=True)

    args = parser.parse_args()

    return args


def main():
    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    lengths = []

    for line in sys.stdin:
        length = len(line.strip().split(" "))
        lengths.append(length)

    lengths_array = numpy.asarray(lengths, dtype="int32")

    numpy.save(args.output, lengths_array)

if __name__ == '__main__':
    main()
