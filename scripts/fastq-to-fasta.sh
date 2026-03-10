#!/bin/bash

# Converts FASTQ to FASTA

# Assumes sequence lines are not wrapped but does allow for blank lines

set -e

print_usage() {
printf "usage: ${0##*/} [<file>]\n"
}

while getopts "h" opt; do
  case "$opt" in 
    h|*)
      print_usage
      exit 1
      ;;
  esac
done

# Check if a file argument is provided
if [ $# -eq 0 ]; then
  input_file="/dev/stdin"  # Read from STDIN if no file is provided
elif [ $# -eq 1 ]; then
  input_file="$1"
else
  printf "${0##*/}: More than one input file provided.\n"
  exit 1
fi

program='
BEGIN {COUNT=0}
length($0) > 0 {
  COUNT++
  if (COUNT % 4 == 1) {print ">" substr($0, 2)}
  if (COUNT % 4 == 2) {print}
}
'

awk "$program"  "$input_file"
