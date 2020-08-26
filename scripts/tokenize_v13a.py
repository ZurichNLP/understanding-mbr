#! /usr/bin/python3

import sys

from sacrebleu.tokenizers.tokenizer_13a import Tokenizer13a


t = Tokenizer13a()

for line in sys.stdin:
    line = line.strip()
    tokenized = t(line)
    print(line)
