#!/bin/bash

# Print FASTA into a colorized and columnar format

# Requires AWK

# Check shell options
if [ -z "$BASH" ]; then
  printf "%s: This script is not supported for non-Bash shells.\n" "${0##*/}" > /dev/stderr
  exit 1
fi
if [ -n "$BASH_VERSION" -a "${BASH_VERSINFO[0]}" -lt 4 ]; then
  printf "%s: Requires minimum Bash version 4 for associative arrays.\n" "${0##*/}" > /dev/stderr
  exit 1
fi

# Constants
declare -A NUCLEIC_SCHEME=(
  [A]=2 [C]=4 [G]=3 [T]=1 [U]=9 [N]=7
)

declare -A PROTEIN_SCHEME=(
  [A]=114 [C]=226 [D]=196 [E]=196 [F]=141
  [G]=252 [H]=39 [I]=41 [K]=33 [L]=41
  [M]=41 [N]=51 [P]=213 [Q]=51 [R]=33
  [S]=214 [T]=214 [V]=41 [W]=99 [Y]=141
  [X]=244
)

RESET=$'\e[0m'

print_usage() {
  printf "usage: %s [-t nucleic|protein] [-w <width>] [<file>]\n" "${0##*/}" > /dev/stderr
}

colorize() {
  local seq="$1"
  local -n scheme="$2"

  local result=""
  local len=${#seq}
  for ((i = 0; i < len; i++)); do
    local sym="${seq:$i:1}"
    local code="${scheme[${sym^^}]:-}"
    if [ -n "$code" ]; then
      result+=$'\e[38;5;'"${code}m${sym}${RESET}"
    else
      result+="$sym"
    fi
  done
  printf "%s" "$result"
}

# Default args
type="protein"
width=80
lpad=2
bpad=1 # Bottom padding--number of additional lines between blocks
color=1

# Parse args
while getopts "t:w:l:b:c:h" opt; do
  case "$opt" in
    t)
      type="$OPTARG"
      ;;
    w)
      width="$OPTARG"
      ;;
    l)
      lpad="$OPTARG"
      ;;
    b)
      bpad="$OPTARG"
      ;;
    c)
      color="$OPTARG"
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
  input_file="/dev/stdin"
elif [ $# -eq 1 ]; then
  input_file="$1"
else
  printf "%s: More than one input file provided.\n" "${0##*/}" > /dev/stderr
  exit 1
fi

case "$type" in
  nucleic)
    scheme_name="NUCLEIC_SCHEME"
    ;;
  protein)
    scheme_name="PROTEIN_SCHEME"
    ;;
  *)
    printf "%s: Unknown type \"%s\". Use \"protein\" or \"nucleic\".\n" "${0##*/}" "$type" > /dev/stderr
    exit 1
    ;;
esac

if [ "$width" -lt 1 ]; then
  printf "%s: width is less than 1.\n" "${0##*/}" > /dev/stderr
  exit 1
fi
if [ "$lpad" -lt 0 ]; then
  printf "%s: lpad is less than 0.\n" "${0##*/}" > /dev/stderr
  exit 1
fi
if [ "$bpad" -lt 0 ]; then
  printf "%s: bpad is less than 0.\n" "${0##*/}" > /dev/stderr
  exit 1
fi
if [ "$color" -ne 0 -a "$color" -ne 1 ]; then
  printf "%s: color is not 0 or 1.\n" "${0##*/}" > /dev/stderr
  exit 1
fi

# Awk FASTA parsing command
sep=$'\31' # Use unit separator control character to avoid collisions
program='
BEGIN {RS=">"; FS="\n"; ORS="\n"; OFS=""}
NR==1 {next}
{$1=$1 sep; print}
'

IFS=$'\n' read -d '' -a records < <(awk -v sep="$sep" "$program" "$input_file") \
  || true # prevents exit from read returning > 0

# Get max lengths
max_id_len=0
max_seq_len=0
for record in "${records[@]}"; do
  IFS="$sep" read header seq <<< "$record"
  IFS=" " read id metadata <<< "$header"
  if [ ${#id} -gt $max_id_len ]; then
    max_id_len=${#id}
  fi
  if [ ${#seq} -gt $max_seq_len ]; then
    max_seq_len=${#seq}
  fi
done
lpad=$((lpad + max_id_len))

# Print blocks
idx=0
while [ $idx -lt $max_seq_len ]; do
  if [ $idx -gt 0 ]; then
    printf "%-*s\n" $((lpad + width))
    for ((i = 0; i < $bpad; i++)); do
      printf "\n"
    done
  fi
  for record in "${records[@]}"; do
    IFS="$sep" read header seq <<< "$record"
    IFS=" " read id metadata <<< "$header"

    seqline="${seq:$idx:$width}"
    if [ "$color" -eq 1 ]; then
      seqline=$(colorize "$seqline" "$scheme_name")
    fi
    printf "%-*s%s\n" "$lpad" "$id" "$seqline"
  done
  idx=$((idx + width))
done
