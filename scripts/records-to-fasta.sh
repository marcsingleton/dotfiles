#!/bin/bash

# Parses delimited records of header and sequence into FASTA output

# Requires fold

set -e

print_usage() {
printf "usage: ${0##*/} [-d <delimiter>] [-w <width>] [file]\n"
}

SEP=$'\t' # Default output delimiter
WIDTH=80

while getopts "d:w:h" opt; do
  case $opt in
    d)
      SEP="$OPTARG"
      ;;
    w)
      WIDTH="$OPTARG"
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
if [ $# -eq 1 ]; then
  input_file="$1"
else
  input_file="/dev/stdin"  # Read from STDIN if no file is provided
fi

while IFS=$SEP read header seq; do
    printf ">$header\n"
    printf "$seq\n" | fold -w $WIDTH
done
