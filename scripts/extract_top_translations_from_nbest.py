#! /usr/bin/python3

import sys
import json
import argparse
import logging


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--top", type=int, help="Return top N translations, one per line (default: top 1)", required=False, default=1)

    args = parser.parse_args()

    return args


def main():
    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    for line in sys.stdin:

        jobj = json.loads(line)
        best_translations = jobj["translations"][:args.top]

        assert len(best_translations) == args.top, "Nbest list did not contain as many translations as requested with --args.top"

        for best_translation in best_translations:
            print(best_translation)


if __name__ == '__main__':
    main()
