#!/usr/bin/env python

#TODO(jeff): Put in a doc string
"""Generic python program."""

import argparse
import sys


def main():
    #TODO(jeff): Update description and arguments.
    parser = argparse.ArgumentParser(description='Description.')
    parser.add_argument('fn', metavar='FILENAME', type=str, nargs=1,
                        help='HELP MESSAGE')
    args = parser.parse_args()


if __name__ == '__main__':
    sys.exit(main())
