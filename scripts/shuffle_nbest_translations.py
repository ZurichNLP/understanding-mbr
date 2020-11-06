#! /usr/bin/python3

import sys
import json
import random

random.seed(1)

for line in sys.stdin:

    jobj = json.loads(line)
    translations = jobj["translations"]

    random.shuffle(translations)

    jobj["translations"] = translations

    print(json.dumps(jobj))
