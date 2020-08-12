import sys

for line in sys.stdin:
    if line.startswith("0"):
        sys.stdout.write(line)
