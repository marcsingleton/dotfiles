#!/bin/bash

# Calulate the reverse complement of a sequence

# Preserves molecule type (DNA vs RNA) and case
# By default assumes type is DNA

set -e

print_usage() {
  printf "usage: %s [-t dna|rna] <seq>\n" "${0##*/}" > /dev/stderr
}

# Default args
type="dna"

# Parse args
while getopts "t:h" opt; do
  case "$opt" in
    t)
      type="$OPTARG"
      ;;
    h | *)
      print_usage
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1)) # Shift to get the file argument

# Validate args
if [ "$type" != "dna" ] && [ "$type" != "rna" ]; then
  printf "%s: Type is not dna or rna\n" "${0##*/}"
  exit 1
fi
if [ $# -ne 1 ]; then
  printf "%s: Argument not provided.\n" "${0##*/}" > /dev/stderr
  exit 1
fi

case "$type" in
  dna)
    forward="Aa"
    reverse="Tt"
    ;;
  rna)
    forward="Aa"
    reverse="Uu"
    ;;
esac
forward+="TtUuGgCc"
reverse+="AaAaCcGg"

printf "%s\n" "$1" | tr "$forward" "$reverse" | rev
