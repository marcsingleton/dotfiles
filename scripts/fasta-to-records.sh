#!/bin/bash

# Parses FASTA files into delimited records of header and sequence output

set -e

print_usage() {
  printf "usage: %s [-d <delimiter>] [<file>]\n" "${0##*/}" > /dev/stderr
}

SEP=$'\t' # Default output delimiter

# Parse args
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

# Awk FASTA parsing command with the specified output delimiter
program='
BEGIN {RS=">"; FS="\n"; ORS="\n"; OFS=""}
NR==1 {next}
{$1=$1 SEP; print}
'

awk -v SEP="$SEP" "$program" "$input_file"
