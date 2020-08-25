#! /usr/bin/python3

# taken from:
# https://github.com/Helsinki-NLP/OPUS-MT-train/blob/master/lib/sentencepiece.mk

import collections
import pprint
import sys

pprint.pprint(dict(collections.Counter(sys.stdin.read())), width=1)
