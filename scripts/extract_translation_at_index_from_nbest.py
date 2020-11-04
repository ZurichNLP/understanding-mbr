#! /usr/bin/python3

import sys
import json
import argparse
import logging


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--pos", type=int, help="Return the translation at this position, one per line (default: first"
                                                  " for each line of nbest translations).",
                        required=False, default=1)

    args = parser.parse_args()

    return args


def main():
    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    for line in sys.stdin:

        jobj = json.loads(line)
        translation_at_index = jobj["translations"][args.pos - 1]

        print(translation_at_index)


if __name__ == '__main__':
    main()
