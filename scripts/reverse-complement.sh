#/bin/bash

# Calulate the reverse complement of a sequence

# Preserves molecule type (DNA vs RNA) and case
# By default assumes type is DNA

set -e

print_usage() {
  printf "usage: %s [-t dna|rna] <seq>\n" "${0##*/}"
}

type="dna"

while getopts "t:h" opt; do
  case "$opt" in
    t)
      if [ "$OPTARG" != "dna" ] && [ "$OPTARG" != "rna" ]; then
        printf "%s: Type is not dna or rna\n" "${0##*/}"
        exit 1
      fi
      type="$OPTARG"
      ;;
    h | *)
      print_usage
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

if [ $# -ne 1 ]; then
  printf "%s: Argument not provided.\n" "${0##*/}"
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
