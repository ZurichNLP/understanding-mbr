#! /usr/bin/python3

import sys
import json


for line in sys.stdin:

        jobj = json.loads(line)
        best_sample = jobj["best_sample"]
        print(best_sample)
