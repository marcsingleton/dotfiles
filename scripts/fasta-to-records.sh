#!/bin/bash

# Parses FASTA files into delimited records of header and sequence output

set -e

print_usage() {
  printf "usage: %s [-d <delimiter>] [<file>]\n" "${0##*/}"
}

SEP=$'\t' # Default output delimiter

while getopts "d:h" opt; do
  case "$opt" in
    d)
      SEP="$OPTARG"
      ;;
    h | *)
      print_usage
      exit 1
      ;;
  esac
done

# Shift to get the file argument
shift $((OPTIND - 1))

# Check if a file argument is provided
if [ $# -eq 0 ]; then
  input_file="/dev/stdin" # Read from STDIN if no file is provided
elif [ $# -eq 1 ]; then
  input_file="$1"
else
  printf "%s: More than one input file provided.\n" "${0##*/}"
  exit 1
fi

# Awk FASTA parsing command with the specified output delimiter
program='
BEGIN {RS=">"; FS="\n"; ORS="\n"; OFS=""}
{$1=$1 SEP; print}
'

awk -v SEP="$SEP" "$program" "$input_file" | tail -n +2
