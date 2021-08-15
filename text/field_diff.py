#!/usr/bin/env python3

import sys

def load_file(file_arg):
    fields = file_arg.rsplit(":", 1)
    if len(fields) != 2:
        raise Exception("Invalid file_arg {}".format(file_arg))

    path = fields[0]
    index = int(fields[1])
    content = dict()

    with open(path) as f:
        for num, line in enumerate(f):
            line = line.strip()
            if line == "" or line[0] == "#":
                continue

            fields = line.split()
            key = line
            if index < len(fields):
                key = fields[index]

            content[key] = (num, line)

    return content

def diff(left, right):
    only_left = []
    for key in left.keys():
        if key not in right:
            only_left.append(left[key])

    only_right = []
    for key in right.keys():
        if key not in left:
            only_right.append(right[key])

    return only_left, only_right

def print_diff(diff):
    diff.sort()
    for _, line in diff:
        print(line)

def main(left_file, right_file):
    left = load_file(left_file)
    right = load_file(right_file)
    only_left, only_right = diff(left, right)
    print(">>> only in", left_file)
    print_diff(only_left)
    print(">>> only in", right_file)
    print_diff(only_right)

if __name__ == "__main__":
    left = sys.argv[1]
    right = sys.argv[2]
    main(left, right)
