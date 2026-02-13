#!/bin/bash

# Parses FASTA files into delimited records

set -e

# Default output delimiter
SEP="\t"

# Parse options
while getopts "d:h" opt; do
  case $opt in
    d)
      SEP="$OPTARG"
      ;;
    h|*)
      echo "usage: ${0##*/} [-d <delimiter>] [<file>]"
      exit 1
      ;;
  esac
done

# Shift to get the file argument
shift $((OPTIND - 1))

# Check if a file argument is provided
if [ $# -eq 1 ]; then
  input_file="$1"
else
  input_file="/dev/stdin"  # Read from STDIN if no file is provided
fi

# Execute the awk command with the specified output delimiter
awk -v SEP="$SEP" 'BEGIN {RS=">"; FS="\n"; ORS="\n"; OFS=""} {$1=$1 SEP; print}' "$input_file" | tail -n +2
