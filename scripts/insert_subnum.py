import sys
import re
import random

from sacremoses import MosesTokenizer, MosesDetokenizer


mtok = MosesTokenizer(lang='de')
mdetok = MosesDetokenizer(lang='de')

def is_num(token):
    return re.match("^\d+$", token)

for line in sys.stdin:
    line = line.strip()

    tokens = mtok.tokenize(line)

    num_indexes = [index for index, token in enumerate(tokens) if is_num(token)]

    if len(num_indexes) == 0:
        continue

    index = random.choice(num_indexes)

    for num in range(2, 50):
        new_tokens = tokens[:]
        new_tokens[index] = str(num)

        detokenized = mdetok.detokenize(new_tokens)

        sys.stdout.write(detokenized + "\n")
