#! /usr/bin/python3

import json
import argparse
import logging

from sacrebleu.tokenizers.tokenizer_13a import Tokenizer13a


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input", type=str, help="File with nbest translations as JSON", required=True)

    args = parser.parse_args()

    return args


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    t = Tokenizer13a()

    with open(args.input) as input_handle:

        for line in input_handle:
            jobj = json.loads(line)

            translations = jobj["translations"]

            tokenized_translations = []

            for translation in translations:
                tokenized_translation = t(translation.strip())

                tokenized_translations.append(tokenized_translation)

            jobj["translations"] = tokenized_translations

            print(json.dumps(jobj))


if __name__ == '__main__':
    main()
