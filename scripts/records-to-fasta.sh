#!/bin/bash

# Parses delimited records of header and sequence into FASTA output

set -e

print_usage() {
  printf "usage: %s [-d <delimiter>] [-w <width>] [<file>]\n" "${0##*/}"
}

write_fasta_record() {
  local header="$1"
  local seq="$2"
  local width="$3"

  printf ">%s\n" "$header"
  for ((i = 0; i < ${#seq}; i += $width)); do
    printf "%s\n" "${seq:i:$width}"
  done
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

while IFS=$SEP read header seq; do
  write_fasta_record "$header" "$seq" $WIDTH
done
