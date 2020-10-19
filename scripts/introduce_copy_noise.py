#! /usr/bin/python3

import argparse
import logging
import random

from typing import Tuple


random.seed(42)


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input-src", type=str, help="Source input file", required=True)
    parser.add_argument("--input-trg", type=str, help="Target input file", required=True)

    parser.add_argument("--output-src", type=str, help="Source output file", required=True)
    parser.add_argument("--output-trg", type=str, help="Target output file", required=True)

    parser.add_argument("--copy-noise-probability", type=float, help="Probability of introducing copies.",
                        required=True)

    args = parser.parse_args()

    return args


def maybe_copy_source(src_line: str,
                      trg_line: str,
                      prob: float) -> Tuple[str, str]:

    if random.random() <= prob:
        return src_line, src_line
    else:
        return src_line, trg_line


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    with open(args.input_src, "r") as handle_input_src, \
            open(args.input_trg, "r") as handle_input_trg, \
            open(args.output_src, "w") as handle_output_src, \
            open(args.output_trg, "w") as handle_output_trg:

        for src_line, trg_line in zip(handle_input_src, handle_input_trg):
            new_src, new_trg = maybe_copy_source(src_line, trg_line, args.copy_noise_probability)

            handle_output_src.write(new_src)
            handle_output_trg.write(new_trg)


if __name__ == "__main__":
    main()
