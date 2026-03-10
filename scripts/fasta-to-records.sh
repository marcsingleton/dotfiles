#!/bin/bash

# Parses FASTA files into delimited records of header and sequence output

set -e

print_usage() {
printf "usage: ${0##*/} [-d <delimiter>] [<file>]\n"
}

SEP=$'\t' # Default output delimiter

while getopts "d:h" opt; do
  case "$opt" in
    d)
      SEP="$OPTARG"
      ;;
    h|*)
      print_usage
      exit 1
      ;;
  esac
done

# Shift to get the file argument
shift $((OPTIND - 1))

# Check if a file argument is provided
if [ $# -eq 0 ]; then
  input_file="/dev/stdin"  # Read from STDIN if no file is provided
elif [ $# -eq 1 ]; then
  input_file="$1"
else
  printf "${0##*/}: More than one input file provided.\n"
  exit 1
fi

# Execute the awk command with the specified output delimiter
awk -v SEP="$SEP" 'BEGIN {RS=">"; FS="\n"; ORS="\n"; OFS=""} {$1=$1 SEP; print}' "$input_file" | tail -n +2
