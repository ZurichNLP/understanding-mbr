#! /usr/bin/python3

import sys
import argparse
import logging

import sentencepiece as spm


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--model", type=str, help="Path where model file is stored.", required=True)
    parser.add_argument("--protected-tags", type=str, nargs="+", required=False, default=[],
                        help="Protected tags at the beginning of the sentence which should not be de-pieced.")

    args = parser.parse_args()

    return args


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    sp = spm.SentencePieceProcessor()
    sp.Load(args.model)

    for line in sys.stdin:
        line = line.strip()
        pieces = line.split(" ")

        protected = None

        if pieces[0] in args.protected_tags:
            protected = pieces.pop(0)

        line = sp.DecodePieces(pieces)

        if protected is not None:
            line = protected + " " + line

        print(line)


if __name__ == '__main__':
    main()
