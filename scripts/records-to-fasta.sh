#!/bin/bash

# Parses delimited records of header and sequence into FASTA output

set -e

print_usage() {
  printf "usage: %s [-d <delimiter>] [-w <width>] [<file>]\n" "${0##*/}" > /dev/stderr
}

print_fasta_record() {
  local header="$1"
  local seq="$2"
  local width="$3"

  printf ">%s\n" "$header"
  for ((i = 0; i < ${#seq}; i += $width)); do
    printf "%s\n" "${seq:i:$width}"
  done
}

# Default args
sep=$'\t' # Output delimiter
width=80

# Parse args
while getopts "d:w:h" opt; do
  case $opt in
    d)
      sep="$OPTARG"
      ;;
    w)
      width="$OPTARG"
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

exec 3< "$input_file"
while IFS="$sep" read -u 3 header seq; do
  print_fasta_record "$header" "$seq" "$width"
done
exec 3<&-