#!/bin/bash

# Converts FASTQ to FASTA

# Assumes sequence lines are not wrapped but does allow for blank lines

# Requires AWK

set -e

print_usage() {
  printf "usage: %s [<file>]\n" "${0##*/}" > /dev/stderr
}

# Parse args
while getopts "h" opt; do
  case "$opt" in
    h | *)
      print_usage
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1)) # Shift to get the file argument

# Validate args
if [ $# -eq 0 ]; then
  input_file="/dev/stdin" # Read from STDIN if no file is provided
elif [ $# -eq 1 ]; then
  input_file="$1"
else
  printf "%s: More than one input file provided.\n" "${0##*/}" > /dev/stderr
  exit 1
fi

# Parse FASTQ
program='
BEGIN {COUNT=0}
length($0) > 0 {
  COUNT++
  if (COUNT % 4 == 1) {print ">" substr($0, 2)}
  if (COUNT % 4 == 2) {print}
}
'

awk "$program" "$input_file"
