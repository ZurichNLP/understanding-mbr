#! /usr/bin/python3

import argparse
import logging

import sentencepiece as spm

# assuming standard Sockeye vocab files
PAD_ID = 0
UNK_ID = 1
BOS_ID = 2
EOS_ID = 3


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--model-prefix", type=str, help="Path where model file should be stored.", required=True)
    parser.add_argument("--input", type=str, help="Path to input text (for instance, truecased).", required=True)
    parser.add_argument("--vocab-size", type=int, help="Desired vocabulary size.", required=True)
    parser.add_argument("--character-coverage", type=float, help="Coverage of all unique characters.", required=True)

    args = parser.parse_args()

    return args


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    spm.SentencePieceTrainer.train(model_prefix=args.model_prefix,
                                   input=args.input,
                                   vocab_size=args.vocab_size,
                                   character_coverage=args.character_coverage,
                                   model_type="unigram",
                                   pad_id=PAD_ID,
                                   unk_id=UNK_ID,
                                   bos_id=BOS_ID,
                                   eos_id=EOS_ID,
                                   hard_vocab_limit=False)


if __name__ == '__main__':
    main()
