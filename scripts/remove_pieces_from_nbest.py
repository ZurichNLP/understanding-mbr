#! /usr/bin/python3

import json
import argparse
import logging


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input", type=str, help="File with nbest translations as JSON", required=True)

    args = parser.parse_args()

    return args


def remove_pieces(line: str) -> str:
    """

    :param line:
    :return:
    """

    return line.replace(" ", "").replace("▁", " ").strip()


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    with open(args.input) as input_handle:

        for line in input_handle:
            jobj = json.loads(line)

            translations = jobj["translations"]

            depieced_translations = []

            for translation in translations:
                depieced_translation = remove_pieces(translation)

                depieced_translations.append(depieced_translation)

            jobj["translations"] = depieced_translations

            print(json.dumps(jobj))


if __name__ == '__main__':
    main()
