#! /usr/bin/python3

import argparse
import logging


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input-src", type=str, help="Source input file", required=True)
    parser.add_argument("--input-trg", type=str, help="Target input file", required=True)

    parser.add_argument("--output-src", type=str, help="Source output file", required=True)
    parser.add_argument("--output-trg", type=str, help="Target output file", required=True)

    args = parser.parse_args()

    return args


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    total = 0
    skipped = 0

    with open(args.input_src, "r") as handle_input_src, \
            open(args.input_trg, "r") as handle_input_trg, \
            open(args.output_src, "w") as handle_output_src, \
            open(args.output_trg, "w") as handle_output_trg:

        for src_line, trg_line in zip(handle_input_src, handle_input_trg):

            if src_line.strip() == "" or trg_line.strip() == "":
                skipped += 1
            else:
                handle_output_src.write(src_line)
                handle_output_trg.write(trg_line)

            total += 1

    logging.debug("Skipped %d parallel lines out of %d total." % (skipped, total))


if __name__ == "__main__":
    main()
