#!/bin/bash

# Translate a DNA sequence

# TODO: Preserve the case of the codon

set -e

# Check shell options
if [ -n "$BASH_VERSION" -a "${BASH_VERSINFO[0]}" -lt 4 ]; then
  printf "%s: Requires minimum Bash version 4 for associative arrays.\n" "${0##*/}" > /dev/stderr
  exit 1
fi

# Constants
declare -A CODON_TABLE=(
  [TTT]=F [TTC]=F [TTA]=L [TTG]=L
  [CTT]=L [CTC]=L [CTA]=L [CTG]=L
  [ATT]=I [ATC]=I [ATA]=I [ATG]=M
  [GTT]=V [GTC]=V [GTA]=V [GTG]=V
  [TCT]=S [TCC]=S [TCA]=S [TCG]=S
  [CCT]=P [CCC]=P [CCA]=P [CCG]=P
  [ACT]=T [ACC]=T [ACA]=T [ACG]=T
  [GCT]=A [GCC]=A [GCA]=A [GCG]=A
  [TAT]=Y [TAC]=Y [TAA]='*' [TAG]='*'
  [CAT]=H [CAC]=H [CAA]=Q [CAG]=Q
  [AAT]=N [AAC]=N [AAA]=K [AAG]=K
  [GAT]=D [GAC]=D [GAA]=E [GAG]=E
  [TGT]=C [TGC]=C [TGA]='*' [TGG]=W
  [CGT]=R [CGC]=R [CGA]=R [CGG]=R
  [AGT]=S [AGC]=S [AGA]=R [AGG]=R
  [GGT]=G [GGC]=G [GGA]=G [GGG]=G
)

print_usage() {
  printf "usage: %s [-f 1|2|3] <seq>\n" "${0##*/}" > /dev/stderr
}

translate() {
  local dna="$1"
  local frame="${2:-1}"
  local protein=""
  local start=$((frame - 1))

  local i=$start
  while ((i + 3 <= ${#dna})); do
    local codon="${dna:$i:3}"
    codon=${codon^^} # Bash trick for uppercasing string
    if [[ "$codon" =~ N ]]; then
      local aa+="X"
    else
      local aa="${CODON_TABLE[$codon]:-?}"
    fi
    protein+="$aa"
    ((i += 3))
  done

  printf "%s\n" "$protein"
}

# Default args
frame=1

# Parse args
while getopts "f:h" opt; do
  case "$opt" in
    f)
      frame="$OPTARG"
      ;;
    h | *)
      print_usage
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1)) # Shift to get the file argument

# Validate args
if [ "$frame" != "1" ] && [ "$frame" != "2" ] && [ "$frame" != "3" ]; then
  printf "%s: Frame is not 1, 2, or 3.\n" "${0##*/}" > /dev/stderr
  exit 1
fi
if [ $# -ne 1 ]; then
  printf "%s: Argument not provided.\n" "${0##*/}" > /dev/stderr
  exit 1
fi

# Translate
translate $1
